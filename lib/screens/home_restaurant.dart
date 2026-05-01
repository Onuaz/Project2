import 'package:flutter/material.dart';
import 'restaurant_orders_screen.dart';

class HomeRestaurant extends StatelessWidget {
  const HomeRestaurant({super.key});

  @override
  Widget build(BuildContext context) {
    const restaurantId = 'demo_restaurant';
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Home')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantOrdersScreen(restaurantId: restaurantId),
              ),
            );
          },
          child: const Text('View Orders'),
        ),
      ),
    );
  }
}
