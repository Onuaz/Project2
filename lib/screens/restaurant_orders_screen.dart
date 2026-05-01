import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class RestaurantOrdersScreen extends StatelessWidget {
  final String restaurantId;
  final _orders = FirebaseFirestore.instance.collection('orders');

  RestaurantOrdersScreen({super.key, required this.restaurantId});

  Stream<List<Order>> _watch() {
    return _orders
        .where('restaurantId', isEqualTo: restaurantId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Order.fromDoc(d)).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Orders')),
      body: StreamBuilder<List<Order>>(
        stream: _watch(),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = s.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (c, i) {
              final o = orders[i];
              return ListTile(
                title: Text(o.itemName),
                subtitle: Text('${o.status} • Driver: ${o.driverId ?? "None"}'),

              );
            },
          );
        },
      ),
    );
  }
}
