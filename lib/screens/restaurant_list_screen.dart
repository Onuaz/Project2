import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';
import '../models/restaurant.dart';
import 'menu_screen.dart';

class RestaurantListScreen extends StatelessWidget {
  final _service = RestaurantService();

  RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants')),
      body: StreamBuilder<List<Restaurant>>(
        stream: _service.watchRestaurants(),
        builder: (c, s) {
          if (!s.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final restaurants = s.data!;
          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (c, i) {
              final r = restaurants[i];
              return ListTile(
                leading: Image.network(r.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                title: Text(r.name),
                subtitle: Text(r.address),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MenuScreen(restaurant: r),
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
