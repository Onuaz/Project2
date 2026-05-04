import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> completeOrder(String orderId) async {
  final db = FirebaseFirestore.instance;

  final snap = await db.collection('orders').doc(orderId).get();
  if (!snap.exists) return;

  final data = snap.data()!;

  await db.collection('order_history').doc(orderId).set({
    ...data,
    'completedAt': FieldValue.serverTimestamp(),
  });

  await db.collection('orders').doc(orderId).update({
    'status': 'completed',
  });
}
