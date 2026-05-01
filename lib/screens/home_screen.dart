import 'package:flutter/material.dart';
import '../db/db_helper.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbHelper = DBHelper();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    setState(() {
      _ordersFuture = _dbHelper.getOrders();
    });
  }

  Future<void> _navigateToAddOrder() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddOrderScreen()),
    );
    if (added == true) {
      _loadOrders();
    }
  }

  Future<void> _openDetails(Order order) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(order: order),
      ),
    );
    if (changed == true) {
      _loadOrders();
    }
  }

  Future<void> _deleteOrder(Order order) async {
    if (order.id != null) {
      await _dbHelper.deleteOrder(order.id!);
      _loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Runner'),
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text('No orders yet. Tap + to add one.'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadOrders(),
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return OrderCard(
                  order: order,
                  onTap: () => _openDetails(order),
                  onDismissed: (direction) => _deleteOrder(order),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddOrder,
        child: const Icon(Icons.add),
      ),
    );
  }
}
