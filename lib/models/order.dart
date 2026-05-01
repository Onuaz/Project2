import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? driverId;
  final String restaurantName;
  final String itemName;
  final String? notes;
  final String status;
  final double urgencyScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.driverId,
    required this.restaurantName,
    required this.itemName,
    this.notes,
    required this.status,
    required this.urgencyScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Order(
      id: doc.id,
      customerId: d['customerId'],
      restaurantId: d['restaurantId'],
      driverId: d['driverId'],
      restaurantName: d['restaurantName'],
      itemName: d['itemName'],
      notes: d['notes'],
      status: d['status'],
      urgencyScore: (d['urgencyScore'] as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }
}
