import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderService {
  final _orders = FirebaseFirestore.instance.collection('orders');

  Stream<List<Order>> watchCustomerOrders(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Order.fromDoc).toList());
  }

  Stream<Order> watchOrder(String id) {
    return _orders.doc(id).snapshots().map(Order.fromDoc);
  }

  Future<void> createOrder({
    required String customerId,
    required String restaurantId,
    required String restaurantName,
    required String itemName,
    String? notes,
  }) async {
    final now = DateTime.now();
    final ref = _orders.doc();
    await ref.set({
      'customerId': customerId,
      'restaurantId': restaurantId,
      'driverId': null,
      'restaurantName': restaurantName,
      'itemName': itemName,
      'notes': notes,
      'status': 'pending',
      'urgencyScore': 0.0,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> deleteOrder(String id) async {
    await _orders.doc(id).delete();
  }
}
