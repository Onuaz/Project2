import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../widgets/order_card.dart';
import '../models/order.dart';
import 'add_order_screen.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = OrderService();
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _customerId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _add() async {
    if (_customerId == null) return;
    const restId = 'demo_restaurant';
    const restName = 'Demo Restaurant';
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddOrderScreen(
          customerId: _customerId!,
          restaurantId: restId,
          restaurantName: restName,
        ),
      ),
    );
  }

  void _open(Order o) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: o.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Food Runner')),
      body: StreamBuilder<List<Order>>(
        stream: _service.watchCustomerOrders(_customerId!),
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
              return OrderCard(
                order: o,
                onTap: () => _open(o),
                onDismissed: (_) => _service.deleteOrder(o.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
