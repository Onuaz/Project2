import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _users = FirebaseFirestore.instance.collection('users');

  Future<void> saveToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    await _users.doc(uid).update({'fcmToken': token});
  }

  Future<void> sendToToken(String token, String title, String body) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'token': token,
      'title': title,
      'body': body,
      'timestamp': DateTime.now(),
    });
  }
}
