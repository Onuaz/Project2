import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/order.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final _service = OrderService();

  OrderDetailScreen({super.key, required this.orderId});

  Future<void> _delete(BuildContext context, Order o) async {
    await _service.deleteOrder(o.id);
    if (context.mounted) Navigator.pop(context, true);
  }

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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.restaurantName, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(o.itemName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(o.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Placed at: ${o.createdAt}'),
                const SizedBox(height: 16),
                if (o.notes != null && o.notes!.isNotEmpty) ...[
                  const Text('Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(o.notes!),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _delete(context, o),
                    icon: const Icon(Icons.delete),
                    label: const Text('Cancel Order'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
