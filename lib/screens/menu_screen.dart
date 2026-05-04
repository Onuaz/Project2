// lib/screens/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cart_screen.dart';

class MenuScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  Future<void> addToCart(BuildContext context, DocumentSnapshot item) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Defensive read for price
    final dynamic rawPrice = item.data().toString().contains('price') ? item['price'] : null;
    final double price = _parsePrice(rawPrice);

    if (price < 0) {
      // Show user-friendly message if price missing or invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This item has no price set. Contact the restaurant.')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cart")
        .add({
      "restaurantId": restaurantId,
      "name": item["name"] ?? "Unnamed item",
      "price": price,
      "createdAt": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart')),
    );
  }

  double _parsePrice(dynamic raw) {
    if (raw == null) return -1;
    if (raw is num) return raw.toDouble();
    if (raw is String) {
      final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
      try {
        return double.parse(cleaned);
      } catch (_) {
        return -1;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("restaurants")
            .doc(restaurantId)
            .collection("menu")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!.docs;
          if (items.isEmpty) return const Center(child: Text('No menu items', style: TextStyle(color: Colors.white)));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final name = item['name'] ?? 'Unnamed item';
              final dynamic rawPrice = item.data().toString().contains('price') ? item['price'] : null;
              final double price = _parsePrice(rawPrice);
              final priceText = price >= 0 ? '\$${price.toStringAsFixed(2)}' : 'No price';

              return ListTile(
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(priceText, style: const TextStyle(color: Colors.white70)),
                onTap: () => addToCart(context, item),
                tileColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              );
            },
          );
        },
      ),
    );
  }
}
