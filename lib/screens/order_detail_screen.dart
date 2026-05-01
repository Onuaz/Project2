import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/order.dart';
import 'add_order_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final _dbHelper = DBHelper();

  OrderDetailScreen({super.key, required this.order});

  Future<void> _deleteOrder(BuildContext context) async {
    if (order.id != null) {
      await _dbHelper.deleteOrder(order.id!);
      if (context.mounted) {
        Navigator.pop(context, true); // indicate refresh
      }
    }
  }

  Future<void> _editOrder(BuildContext context) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddOrderScreen(existingOrder: order),
      ),
    );
    if (updated == true && context.mounted) {
      Navigator.pop(context, true); // go back to list and refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(order.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteOrder(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.restaurant,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              order.item,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(order.status),
              ],
            ),
            const SizedBox(height: 8),
            if (date != null)
              Text(
                'Ordered at: $date',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(order.notes!),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editOrder(context),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
