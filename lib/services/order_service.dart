import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import 'notification_service.dart';

class OrderService {
  final _orders = FirebaseFirestore.instance.collection('orders');
  final _users = FirebaseFirestore.instance.collection('users');
  final _restaurants = FirebaseFirestore.instance.collection('restaurants');
  final _notify = NotificationService();

  Stream<List<Order>> watchCustomerOrders(String customerId) {
    return _orders
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(Order.fromDoc).toList());
  }

  Stream<List<Order>> watchDriverOrders(String driverId) {
    return _orders
        .where('driverId', isEqualTo: driverId)
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
      'rating': null,
      'review': null,
    });

    final restaurantDoc = await _restaurants.doc(restaurantId).get();
    final ownerId = restaurantDoc.data()?['ownerId'];
    if (ownerId != null) {
      final userDoc = await _users.doc(ownerId).get();
      final token = userDoc.data()?['fcmToken'];
      if (token != null) {
        await _notify.sendToToken(
          token,
          'New Order',
          'You received a new order for $itemName',
        );
      }
    }
  }

  Future<void> updateStatus(String id, String status) async {
    await _orders.doc(id).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });

    final orderDoc = await _orders.doc(id).get();
    final customerId = orderDoc.data()?['customerId'];
    if (customerId != null) {
      final customerDoc = await _users.doc(customerId).get();
      final token = customerDoc.data()?['fcmToken'];
      if (token != null) {
        await _notify.sendToToken(
          token,
          'Order Update',
          'Your order status is now $status',
        );
      }
    }
  }

  Future<void> assignDriver(String orderId, String driverId) async {
    await _orders.doc(orderId).update({
      'driverId': driverId,
      'status': 'assigned',
      'updatedAt': Timestamp.now(),
    });

    final driverDoc = await _users.doc(driverId).get();
    final token = driverDoc.data()?['fcmToken'];
    if (token != null) {
      await _notify.sendToToken(
        token,
        'New Delivery',
        'You have been assigned a new order',
      );
    }
  }

  Future<void> submitReview(String orderId, int rating, String review) async {
    await _orders.doc(orderId).update({
      'rating': rating,
      'review': review,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteOrder(String id) async {
    await _orders.doc(id).delete();
  }
}
