import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  String _elapsed(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  String _formatMeters(dynamic m) {
    if (m == null) return '—';
    if (m is num) {
      final meters = m.toDouble();
      if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '—';
  }

  Future<void> _showOrderDetails(BuildContext context, DocumentSnapshot<Map<String, dynamic>> o) async {
    final data = o.data() ?? {};
    final createdTs = data['createdAt'];
    final DateTime created = createdTs is Timestamp ? createdTs.toDate() : DateTime.now();
    final status = data['status'] ?? 'unknown';
    final items = (data['items'] as List<dynamic>?) ?? [];
    final driverDistanceToRestaurant = data['driverDistanceToRestaurant'];
    final driverDistanceToCustomer = data['driverDistanceToCustomer'];
    final driverLocation = data['driverLocation'];
    final restaurantLocation = data['restaurantLocation'];
    final customerLocation = data['customerLocation'];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order ${o.id}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Status: $status', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('Placed: ${DateFormat.yMd().add_jm().format(created)}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              const Text('Items:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 6),
              ...items.map((it) {
                final name = (it is Map && it.containsKey('name')) ? it['name'] : it.toString();
                final price = (it is Map && it.containsKey('price')) ? it['price'] : 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('- $name (\$${price.toString()})', style: const TextStyle(color: Colors.white70)),
                );
              }).toList(),
              const SizedBox(height: 12),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              const Text('Live tracking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.store, color: Colors.cyanAccent),
                title: const Text('Distance to Restaurant', style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatMeters(driverDistanceToRestaurant), style: const TextStyle(color: Colors.white70)),
              ),
              ListTile(
                leading: const Icon(Icons.person_pin_circle, color: Colors.cyanAccent),
                title: const Text('Distance to Customer', style: TextStyle(color: Colors.white)),
                subtitle: Text(_formatMeters(driverDistanceToCustomer), style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              if (driverLocation != null)
                Text('Driver coords: ${driverLocation['lat']}, ${driverLocation['lng']}', style: const TextStyle(color: Colors.white54)),
              if (restaurantLocation != null)
                Text('Restaurant coords: ${restaurantLocation['lat']}, ${restaurantLocation['lng']}', style: const TextStyle(color: Colors.white54)),
              if (customerLocation != null)
                Text('Customer coords: ${customerLocation['lat']}, ${customerLocation['lng']}', style: const TextStyle(color: Colors.white54)),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
                    onPressed: () {
                      // allow admin/restaurant/driver to mark delivered from this sheet if they have permission in your app rules
                      FirebaseFirestore.instance.collection('orders').doc(o.id).update({'status': 'delivered'});
                      Navigator.pop(context);
                    },
                    child: const Text('Mark delivered', style: TextStyle(color: Colors.black)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () {
                      FirebaseFirestore.instance.collection('orders').doc(o.id).delete();
                      Navigator.pop(context);
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No orders yet', style: TextStyle(color: Colors.white)));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final o = docs[i];
              final data = o.data();
              final createdTs = data['createdAt'];
              final DateTime created = createdTs is Timestamp ? createdTs.toDate() : DateTime.now();
              final elapsed = DateTime.now().difference(created);
              final elapsedText = _elapsed(elapsed);
              final status = data['status'] ?? 'unknown';
              final items = (data['items'] as List<dynamic>?) ?? [];
              final driverDistanceToCustomer = data['driverDistanceToCustomer'];
              final driverDistanceToRestaurant = data['driverDistanceToRestaurant'];

              return Card(
                color: Colors.black.withOpacity(0.6),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('Order ${o.id}', style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Status: $status • ${items.length} items\nPlaced: ${DateFormat.yMd().add_jm().format(created)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(elapsedText, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Driver→Store: ${_formatMeters(driverDistanceToRestaurant)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      Text('Driver→You: ${_formatMeters(driverDistanceToCustomer)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => _showOrderDetails(context, o),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
