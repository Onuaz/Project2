import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addReview(String orderId, int rating, String comment) async {
  final db = FirebaseFirestore.instance;

  await db
      .collection('order_history')
      .doc(orderId)
      .collection('reviews')
      .add({
    'rating': rating,
    'comment': comment,
    'createdAt': FieldValue.serverTimestamp(),
  });
}
