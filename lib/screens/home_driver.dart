import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'orders_screen.dart';

class HomeDriver extends StatefulWidget {
  const HomeDriver({super.key});
  @override
  State<HomeDriver> createState() => _HomeDriverState();
}

class _HomeDriverState extends State<HomeDriver> {
  StreamSubscription<Position>? _posSub;
  String? _trackingOrderId;
  bool _requestingPermission = false;

  Future<bool> _ensurePermission() async {
    if (_requestingPermission) return false;
    _requestingPermission = true;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      _requestingPermission = false;
      return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
    } catch (_) {
      _requestingPermission = false;
      return false;
    }
  }

  Future<void> _updateDistances(String orderId, double driverLat, double driverLng) async {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final snap = await orderRef.get();
    if (!snap.exists) return;
    final data = snap.data() ?? {};

    double? distToRestaurant;
    double? distToCustomer;

    if (data.containsKey('restaurantLocation')) {
      final rloc = data['restaurantLocation'];
      final rlat = (rloc['lat'] is num) ? (rloc['lat'] as num).toDouble() : double.tryParse(rloc['lat']?.toString() ?? '');
      final rlng = (rloc['lng'] is num) ? (rloc['lng'] as num).toDouble() : double.tryParse(rloc['lng']?.toString() ?? '');
      if (rlat != null && rlng != null) {
        distToRestaurant = Geolocator.distanceBetween(driverLat, driverLng, rlat, rlng);
      }
    }

    if (data.containsKey('customerLocation')) {
      final cloc = data['customerLocation'];
      final clat = (cloc['lat'] is num) ? (cloc['lat'] as num).toDouble() : double.tryParse(cloc['lat']?.toString() ?? '');
      final clng = (cloc['lng'] is num) ? (cloc['lng'] as num).toDouble() : double.tryParse(cloc['lng']?.toString() ?? '');
      if (clat != null && clng != null) {
        distToCustomer = Geolocator.distanceBetween(driverLat, driverLng, clat, clng);
      }
    }

    final update = <String, dynamic>{'driverLocation': {'lat': driverLat, 'lng': driverLng, 'updatedAt': FieldValue.serverTimestamp()}};
    if (distToRestaurant != null) update['driverDistanceToRestaurant'] = distToRestaurant;
    if (distToCustomer != null) update['driverDistanceToCustomer'] = distToCustomer;

    await orderRef.update(update);
  }

  Future<void> _startTracking(String orderId) async {
    final hasPerm = await _ensurePermission();
    if (!hasPerm) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission required')));
      }
      return;
    }

    setState(() => _trackingOrderId = orderId);

    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    _posSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((pos) async {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final driversRef = FirebaseFirestore.instance.collection('drivers').doc(uid);
      try {
        await driversRef.set({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'lastUpdated': FieldValue.serverTimestamp(),
          'trackingOrderId': orderId,
        }, SetOptions(merge: true));
      } catch (_) {}

      try {
        await _updateDistances(orderId, pos.latitude, pos.longitude);
      } catch (_) {}

      FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'driverLocation': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }).catchError((_) {});
    });
  }

  Future<void> _stopTracking() async {
    await _posSub?.cancel();
    _posSub = null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && _trackingOrderId != null) {
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({'trackingOrderId': null});
    }
    setState(() => _trackingOrderId = null);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  String _formatMeters(dynamic m) {
    if (m == null) return '—';
    if (m is num) {
      final meters = m.toDouble();
      if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '—';
  }

  Future<void> _showTrackingSheet(DocumentSnapshot<Map<String, dynamic>> orderDoc) async {
    final data = orderDoc.data() ?? {};
    final distToRestaurant = data['driverDistanceToRestaurant'];
    final distToCustomer = data['driverDistanceToCustomer'];
    final restaurantLoc = data['restaurantLocation'];
    final customerLoc = data['customerLocation'];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                title: Text('Tracking Order ${orderDoc.id}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Live location updates are being sent', style: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.cyanAccent),
                title: const Text('Distance to Restaurant', style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatMeters(distToRestaurant), style: const TextStyle(color: Colors.white70)),
              ),
              ListTile(
                leading: const Icon(Icons.person_pin_circle, color: Colors.cyanAccent),
                title: const Text('Distance to Customer', style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatMeters(distToCustomer), style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                      onPressed: () async {
                        // Mark order complete and stop tracking
                        await FirebaseFirestore.instance.collection('orders').doc(orderDoc.id).update({'status': 'delivered'});
                        await _stopTracking();
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Order complete', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue tracking', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (restaurantLoc != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Restaurant coords: ${restaurantLoc['lat']}, ${restaurantLoc['lng']}', style: const TextStyle(color: Colors.white54)),
                ),
              if (customerLoc != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Customer coords: ${customerLoc['lat']}, ${customerLoc['lng']}', style: const TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('Driver Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.list), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').where('status', whereIn: ['waiting_for_driver', 'assigned']).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No available orders', style: TextStyle(color: Colors.white)));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final o = docs[i];
              final data = o.data();
              final restaurantId = data['restaurantId'] ?? 'unknown';
              final status = data['status'] ?? 'unknown';
              final distToRestaurant = data['driverDistanceToRestaurant'];
              final distToCustomer = data['driverDistanceToCustomer'];

              return Card(
                color: Colors.black.withOpacity(0.6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('Order ${o.id}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Status: $status\nRestaurant: $restaurantId\nTo restaurant: ${_formatMeters(distToRestaurant)} • To customer: ${_formatMeters(distToCustomer)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  isThreeLine: true,
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                    child: Text(_trackingOrderId == o.id ? 'Tracking' : 'Accept', style: const TextStyle(color: Colors.black)),
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                        return;
                      }

                      // Ensure driver has address before accepting
                      final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      final addr = userSnap.data()?['address'] as String?;
                      if (addr == null || addr.trim().isEmpty) {
                        final addrCtrl = TextEditingController();
                        final result = await showDialog<String?>(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF071026),
                            title: const Text('Enter your address', style: TextStyle(color: Colors.white)),
                            content: TextField(controller: addrCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Driver address', hintStyle: TextStyle(color: Colors.white54))),
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
                        if (result == null) return;
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'address': result});
                      }

                      if (_trackingOrderId == null) {
                        // Accept and start tracking
                        await FirebaseFirestore.instance.collection('orders').doc(o.id).update({
                          'driverId': uid,
                          'status': 'assigned',
                        });
                        await _startTracking(o.id);
                      } else if (_trackingOrderId == o.id) {
                        // Instead of immediately stopping tracking, show tracking sheet with distances and require "Order complete"
                        await _showTrackingSheet(o);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Finish current delivery first')));
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
