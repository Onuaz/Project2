import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final _service = OrderService();

  OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: StreamBuilder<Order>(
        stream: _service.watchOrder(orderId),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final o = s.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.restaurantName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(o.itemName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Text('Status: ${o.status}'),
                const SizedBox(height: 8),
                Text('Placed: ${o.createdAt}'),
                if (o.notes != null && o.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Notes: ${o.notes!}'),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
