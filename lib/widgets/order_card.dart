import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final DismissDirectionCallback onDismissed;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onDismissed,
  });

  Color _c(String s) {
    if (s == 'accepted') return Colors.orange;
    if (s == 'assigned' || s == 'picked_up' || s == 'delivering') return Colors.blue;
    if (s == 'delivered') return Colors.green;
    if (s == 'cancelled') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(order.id),
      direction: DismissDirection.endToStart,
      onDismissed: onDismissed,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: ListTile(
          onTap: onTap,
          title: Text(order.restaurantName),
          subtitle: Text(order.itemName),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _c(order.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order.status,
              style: TextStyle(
                color: _c(order.status),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
