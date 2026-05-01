import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../widgets/order_card.dart';
import 'restaurant_list_screen.dart';
import 'order_detail_screen.dart';

class HomeCustomer extends StatefulWidget {
  const HomeCustomer({super.key});

  @override
  State<HomeCustomer> createState() => _HomeCustomerState();
}

class _HomeCustomerState extends State<HomeCustomer> {
  final _service = OrderService();
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _customerId = FirebaseAuth.instance.currentUser?.uid;
  }

  void _openRestaurants() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RestaurantListScreen()),
    );
  }

  void _openOrder(Order o) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: o.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_customerId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
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
                onTap: () => _openOrder(o),
                onDismissed: (_) => _service.deleteOrder(o.id),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openRestaurants,
        child: const Icon(Icons.add),
      ),
    );
  }
}
