import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cart_screen.dart';
import 'orders_screen.dart';
import 'restaurant_menu_editor.dart';
import 'account_manager.dart';

class HomeCustomer extends StatelessWidget {
  const HomeCustomer({super.key});

  Future<void> _addToCart(BuildContext context, String restaurantId, Map<String, dynamic> item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not signed in')));
      return;
    }
    final cartRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('cart');
    await cartRef.add({
      ...item,
      'restaurantId': restaurantId,
      'addedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('Discover Restaurants'),
        actions: [
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
          IconButton(icon: const Icon(Icons.list), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()))),
          IconButton(icon: const Icon(Icons.people), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountManager()))),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('restaurants').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No restaurants yet', style: TextStyle(color: Colors.white)));
          final restaurants = snap.data!.docs;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, i) {
              final r = restaurants[i];
              final name = r.data()['name'] ?? 'Unnamed';
              final address = r.data()['address'] ?? '';
              return Card(
                color: Colors.black.withOpacity(0.6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(address, style: const TextStyle(color: Colors.white70)),
                  trailing: IconButton(
                    icon: const Icon(Icons.restaurant_menu, color: Colors.cyanAccent),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuViewer(restaurantId: r.id, onAdd: (item) => _addToCart(context, r.id, item))));
                    },
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantMenuViewer(restaurantId: r.id, onAdd: (item) => _addToCart(context, r.id, item))));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Lightweight menu viewer used by customers to browse and add items to cart.
/// Reuses the restaurant menu collection; does not allow editing here.
class RestaurantMenuViewer extends StatelessWidget {
  final String restaurantId;
  final void Function(Map<String, dynamic> item) onAdd;
  const RestaurantMenuViewer({super.key, required this.restaurantId, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final menuRef = FirebaseFirestore.instance.collection('restaurants').doc(restaurantId).collection('menu').orderBy('createdAt', descending: true);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.home), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)),
        title: const Text('Menu'),
        actions: [
          IconButton(icon: const Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: menuRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text('No menu items', style: TextStyle(color: Colors.white)));
          final docs = snap.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i];
              final name = d.data()['name'] ?? 'Unnamed';
              final price = d.data()['price'] ?? 0;
              return Card(
                color: Colors.black.withOpacity(0.6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('\$${price.toString()}', style: const TextStyle(color: Colors.white70)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                    onPressed: () => onAdd({'name': name, 'price': price}),
                    child: const Text('Add', style: TextStyle(color: Colors.black)),
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
