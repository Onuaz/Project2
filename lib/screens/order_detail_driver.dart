import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/driver_location_service.dart';
import '../models/driver_location.dart';
import 'package:geolocator/geolocator.dart';

class OrderDetailDriver extends StatefulWidget {
  final Order order;

  const OrderDetailDriver({super.key, required this.order});

  @override
  State<OrderDetailDriver> createState() => _OrderDetailDriverState();
}

class _OrderDetailDriverState extends State<OrderDetailDriver> {
  final _orders = OrderService();
  final _loc = DriverLocationService();

  Future<void> _updateStatus(String status) async {
    await _orders.updateStatus(widget.order.id, status);
  }

  Future<void> _shareLocation() async {
    final pos = await Geolocator.getCurrentPosition();
    await _loc.updateLocation(
      widget.order.driverId!,
      DriverLocation(lat: pos.latitude, lng: pos.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Order')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(o.itemName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(o.restaurantName),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _updateStatus('picked_up'),
              child: const Text('Picked Up'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _updateStatus('delivering'),
              child: const Text('Delivering'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _updateStatus('delivered'),
              child: const Text('Delivered'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _shareLocation,
              child: const Text('Share Location'),
            ),
          ],
        ),
      ),
    );
  }
}
