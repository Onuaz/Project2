import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'orders_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _placing = false;

  Future<String?> _ensureCustomerAddress(BuildContext context, String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await userRef.get();
    final addr = snap.data()?['address'] as String?;
    if (addr != null && addr.trim().isNotEmpty) return addr;

    final addrCtrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071026),
        title: const Text('Enter delivery address', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: addrCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: '123 Main St', hintStyle: TextStyle(color: Colors.white54)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () {
              final a = addrCtrl.text.trim();
              if (a.isNotEmpty) Navigator.pop(context, a);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      await userRef.update({'address': result});
      return result;
    }
    return null;
  }

  /// Try to capture the customer's current GPS coordinates (best-effort).
  Future<Map<String, double>?> _captureCustomerLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      return {'lat': pos.latitude, 'lng': pos.longitude};
    } catch (_) {
      return null;
    }
  }

  Future<void> _placeOrder(BuildContext context) async {
    if (_placing) return;
    setState(() => _placing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Check role - admins cannot place orders
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final role = userSnap.data()?['role'] as String? ?? 'customer';
      if (role == 'admin') {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Admin accounts cannot place orders')));
        return;
      }

      // Ensure customer has address
      final address = await _ensureCustomerAddress(context, uid);
      if (address == null) return; // user cancelled

      // Re-fetch cart items (defensive)
      final cartRef = FirebaseFirestore.instance.collection("users").doc(uid).collection("cart");
      final cartItemsSnap = await cartRef.get();

      if (cartItemsSnap.docs.isEmpty) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your cart is empty')));
        return;
      }

      final firstDocData = cartItemsSnap.docs.first.data() as Map<String, dynamic>;
      final restaurantId = firstDocData.containsKey("restaurantId") ? firstDocData["restaurantId"] : null;
      if (restaurantId == null) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart items missing restaurant information')));
        return;
      }

      final items = cartItemsSnap.docs.map((e) => Map<String, dynamic>.from(e.data() as Map<String, dynamic>)).toList();

      // Attempt to capture customer's current GPS coords and include them in the order
      final customerLoc = await _captureCustomerLocation();

      // Also attempt to fetch restaurant location (if present) to store with order
      final restSnap = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
      Map<String, double>? restaurantLoc;
      if (restSnap.exists) {
        final rdata = restSnap.data();
        if (rdata != null && rdata.containsKey('lat') && rdata.containsKey('lng')) {
          final lat = (rdata['lat'] is num) ? (rdata['lat'] as num).toDouble() : double.tryParse(rdata['lat']?.toString() ?? '');
          final lng = (rdata['lng'] is num) ? (rdata['lng'] as num).toDouble() : double.tryParse(rdata['lng']?.toString() ?? '');
          if (lat != null && lng != null) restaurantLoc = {'lat': lat, 'lng': lng};
        }
      }

      final orderData = {
        "customerId": uid,
        "customerAddress": address,
        "restaurantId": restaurantId,
        "items": items,
        "status": "waiting_for_driver",
        "driverId": null,
        "createdAt": FieldValue.serverTimestamp(),
        if (customerLoc != null) 'customerLocation': customerLoc,
        if (restaurantLoc != null) 'restaurantLocation': restaurantLoc,
      };

      final orderRef = await FirebaseFirestore.instance.collection("orders").add(orderData);

      // assign driver (best-effort)
      final drivers = await FirebaseFirestore.instance.collection("users").where("role", isEqualTo: "driver").get();
      if (drivers.docs.isNotEmpty) {
        final driverId = drivers.docs.first.id;
        await FirebaseFirestore.instance.collection("orders").doc(orderRef.id).update({
          "driverId": driverId,
          "status": "assigned",
        });
      }

      // clear cart
      for (var doc in cartItemsSnap.docs) {
        await doc.reference.delete();
      }

      // Big confirmation dialog (full-screen, auto-dismiss)
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF00E5FF)),
                    SizedBox(height: 12),
                    Text('Order Placed', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Your order is confirmed and being processed. You can track it in Orders.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (context.mounted) Navigator.of(context).pop(); // close dialog
        if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order failed: $e')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text("Cart"),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection("users").doc(uid).collection("cart").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('No cart data', style: TextStyle(color: Colors.white)));

          final items = snapshot.data!.docs;
          if (items.isEmpty) return const Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.white)));

          double total = 0;
          for (var e in items) {
            final raw = e.data()['price'];
            final price = (raw is num) ? raw.toDouble() : double.tryParse(raw?.toString() ?? '') ?? 0.0;
            total += price;
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: items.map((e) {
                    final data = e.data();
                    final name = data['name'] ?? 'Unnamed item';
                    final rawPrice = data['price'];
                    final price = (rawPrice is num) ? rawPrice.toDouble() : double.tryParse(rawPrice?.toString() ?? '') ?? -1;
                    final priceText = price >= 0 ? '\$${price.toStringAsFixed(2)}' : 'No price';
                    return ListTile(
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      trailing: Text(priceText, style: const TextStyle(color: Colors.white70)),
                    );
                  }).toList(),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withOpacity(0.6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: \$${total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton(
                      onPressed: _placing ? null : () => _placeOrder(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                      child: _placing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Place Order", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
