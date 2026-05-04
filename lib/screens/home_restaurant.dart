import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'restaurant_menu_editor.dart';
import 'cart_screen.dart';
import 'orders_screen.dart';

class HomeRestaurant extends StatelessWidget {
  const HomeRestaurant({super.key});

  Future<bool> _isOwner(String restaurantId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
    return snap.exists && (snap.data()?['ownerId'] == uid);
  }

  Future<void> _editRestaurantDetails(BuildContext context, String restaurantId) async {
    final docRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId);
    final snap = await docRef.get();
    final data = snap.data() ?? {};
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final addressCtrl = TextEditingController(text: data['address'] ?? '');

    final result = await showDialog<bool?>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF071026),
        title: const Text('Edit Restaurant', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', labelStyle: TextStyle(color: Colors.white70))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final address = addressCtrl.text.trim();
              await docRef.update({'name': name, 'address': address});
              Navigator.pop(context, true);
            },
            child: const Text('Save', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restaurant updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('Restaurant Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
          IconButton(icon: const Icon(Icons.list), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
        ],
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('restaurants').where('ownerId', isEqualTo: uid).get(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('You have no restaurant profile yet.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                      onPressed: () async {
                        final docRef = FirebaseFirestore.instance.collection('restaurants').doc(uid);
                        final exists = (await docRef.get()).exists;
                        if (!exists) {
                          await docRef.set({
                            'name': 'New Restaurant',
                            'address': '',
                            'ownerId': uid,
                            'createdAt': FieldValue.serverTimestamp(),
                          });
                        }
                        await FirebaseFirestore.instance.collection('users').doc(uid).set({'role': 'restaurant'}, SetOptions(merge: true));
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: uid)));
                      },
                      child: const Text('Create Restaurant Profile', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            );
          }

          final r = docs.first;
          final name = r.data()['name'] ?? 'Unnamed';
          final address = r.data()['address'] ?? '';

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Card(
                  color: Colors.black.withOpacity(0.6),
                  child: ListTile(
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(address, style: const TextStyle(color: Colors.white70)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: r.id))),
                        child: const Text('Edit Menu', style: TextStyle(color: Colors.black)),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.cyanAccent),
                        onPressed: () => _editRestaurantDetails(context, r.id),
                        tooltip: 'Edit restaurant name/address',
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list, color: Colors.black),
                  label: const Text('View Orders', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
