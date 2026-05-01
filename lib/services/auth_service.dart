import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<User?> authState() => _auth.authStateChanges();

  Future<User?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return cred.user;
  }

  Future<User?> register(String email, String password, String role) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _users.doc(cred.user!.uid).set({
      'email': email,
      'role': role,
    });
    return cred.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getRole(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data()?['role'];
  }
}
