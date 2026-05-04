import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> init() async {
    await _fcm.requestPermission();
  }

  Future<void> saveToken(String uid) async {
    final token = await _fcm.getToken();
    if (token == null) return;
    await _db.collection('users').doc(uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
