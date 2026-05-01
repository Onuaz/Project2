import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import 'order_detail_driver.dart';

class HomeDriver extends StatefulWidget {
  const HomeDriver({super.key});

  @override
  State<HomeDriver> createState() => _HomeDriverState();
}

class _HomeDriverState extends State<HomeDriver> {
  final _service = OrderService();
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _driverId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    if (_driverId == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Orders')),
      body: StreamBuilder<List<Order>>(
        stream: _service.watchDriverOrders(_driverId!),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = s.data!;
          if (orders.isEmpty) {
            return const Center(child: Text('No assigned orders'));
          }
          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (c, i) {
              final o = orders[i];
              return ListTile(
                title: Text(o.itemName),
                subtitle: Text(o.restaurantName),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailDriver(order: o),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
