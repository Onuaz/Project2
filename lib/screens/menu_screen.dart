import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../models/menu_item.dart';
import '../services/order_service.dart';

class MenuScreen extends StatelessWidget {
  final Restaurant restaurant;
  final _service = RestaurantService();
  final _orders = OrderService();

  MenuScreen({super.key, required this.restaurant});

  Future<void> _order(BuildContext context, MenuItemModel item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _orders.createOrder(
      customerId: uid,
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      itemName: item.name,
      notes: null,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurant.name)),
      body: StreamBuilder<List<MenuItemModel>>(
        stream: _service.watchMenu(restaurant.id),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = s.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (c, i) {
              final m = items[i];
              return ListTile(
                leading: Image.network(m.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                title: Text(m.name),
                subtitle: Text('\$${m.price.toStringAsFixed(2)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () => _order(context, m),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
