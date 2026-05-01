import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'review_screen.dart';

class CustomerOrderHistory extends StatelessWidget {
  final _service = OrderService();

  CustomerOrderHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: StreamBuilder<List<Order>>(
        stream: _service.watchCustomerOrders(uid!),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          final orders = s.data!;
          if (orders.isEmpty) return const Center(child: Text('No orders yet'));

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (c, i) {
              final o = orders[i];
              return ListTile(
                title: Text(o.itemName),
                subtitle: Text('Status: ${o.status}'),
                trailing: o.rating == null
                    ? TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewScreen(orderId: o.id),
                            ),
                          );
                        },
                        child: const Text('Review'),
                      )
                    : Text('${o.rating} ★'),
              );
            },
          );
        },
      ),
    );
  }
}
