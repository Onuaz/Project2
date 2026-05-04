import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/review_service.dart';

class CustomerOrderHistoryScreen extends StatelessWidget {
  final String customerId;

  const CustomerOrderHistoryScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1F),
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('order_history')
            .where('customerId', isEqualTo: customerId)
            .orderBy('completedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final orders = snap.data!.docs;

          if (orders.isEmpty) {
            return const Center(
              child: Text("No completed orders", style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i].data() as Map<String, dynamic>;
              final orderId = orders[i].id;

              return Card(
                color: Colors.black54,
                child: ListTile(
                  title: Text(
                    "Order from ${o['restaurantId']}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "Completed",
                    style: const TextStyle(color: Colors.cyanAccent),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      addReview(orderId, 5, "Great delivery!");
                    },
                    child: const Text("Review"),
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
