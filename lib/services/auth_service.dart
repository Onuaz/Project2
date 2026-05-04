import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<User?> register(String email, String password, String role) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // base user doc
      await _db.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // role-specific docs
      if (role == 'restaurant') {
        await _db.collection('restaurants').doc(uid).set({
          'name': email.split('@').first,
          'address': 'Update address',
          'imageUrl': '',
          'lat': 33.75,
          'lng': -84.39,
        });
      } else if (role == 'driver') {
        await _db.collection('drivers').doc(uid).set({
          'available': true,
          'lat': 33.75,
          'lng': -84.39,
          'status': 'idle',
          'currentLoad': 0,
        });
      }

      return cred.user;
    } catch (e) {
      print('REGISTER ERROR: $e');
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print('LOGIN ERROR: $e');
      return null;
    }
  }

  Future<String?> getRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'];
    } catch (e) {
      print('ROLE ERROR: $e');
      return null;
    }
  }
}
