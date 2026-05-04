import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'restaurant_menu_editor.dart';
import 'cart_screen.dart';
import 'account_manager.dart';
import 'orders_screen.dart';

class HomeRestaurant extends StatelessWidget {
  const HomeRestaurant({super.key});

  Future<bool> _isOwner(String restaurantId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final snap = await FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).get();
    return snap.exists && (snap.data()?['ownerId'] == uid);
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
          IconButton(icon: const Icon(Icons.people), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManager()))),
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
                        // create a minimal restaurant doc for this user
                        final newDoc = await FirebaseFirestore.instance.collection('restaurants').add({
                          'name': 'New Restaurant',
                          'address': '',
                          'ownerId': uid,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        // link user doc
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'restaurant'});
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: newDoc.id)));
                      },
                      child: const Text('Create Restaurant Profile', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            );
          }

          // show first restaurant owned by this user and quick actions
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
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuEditor(restaurantId: r.id))),
                      child: const Text('Edit Menu', style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list, color: Colors.black),
                  label: const Text('View Orders', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen())),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.people, color: Colors.black),
                  label: const Text('Account Manager', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManager())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
