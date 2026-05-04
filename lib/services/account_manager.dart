// lib/services/account_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountManagerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetch a stream of all users (for admin dashboards)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllUsers() {
    return _db.collection('users').orderBy('createdAt', descending: true).snapshots();
  }

  /// Fetch a stream of all restaurants
  Stream<QuerySnapshot<Map<String, dynamic>>> streamAllRestaurants() {
    return _db.collection('restaurants').snapshots();
  }

  /// Get a single user document
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) {
    return _db.collection('users').doc(uid).get();
  }

  /// Create or update a user document (non-auth user record)
  Future<void> upsertUser(String uid, Map<String, dynamic> data) async {
    final docRef = _db.collection('users').doc(uid);
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (data['createdAt'] == null) payload['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(payload, SetOptions(merge: true));
  }

  /// Create a new user document with auto-id (useful for admin-created accounts)
  Future<DocumentReference<Map<String, dynamic>>> createUser(Map<String, dynamic> data) {
    final payload = {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    return _db.collection('users').add(payload);
  }

  /// Delete a user document but do NOT delete restaurant documents.
  /// If the deleted user was a restaurant owner, restaurant docs are left intact.
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
    // intentionally do not delete restaurants owned by this uid
    // optionally, you could mark restaurants.ownerId = null here if desired
  }

  /// Fetch a single restaurant document
  Future<DocumentSnapshot<Map<String, dynamic>>> getRestaurant(String restaurantId) {
    return _db.collection('restaurants').doc(restaurantId).get();
  }

  /// Create or update restaurant document. Use merge to avoid overwriting menu subcollection.
  Future<void> upsertRestaurant(String restaurantId, Map<String, dynamic> data) async {
    final docRef = _db.collection('restaurants').doc(restaurantId);
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (data['createdAt'] == null) payload['createdAt'] = FieldValue.serverTimestamp();
    await docRef.set(payload, SetOptions(merge: true));
  }

  /// Delete a restaurant document (admin-only action expected)
  Future<void> deleteRestaurant(String restaurantId) async {
    await _db.collection('restaurants').doc(restaurantId).delete();
    // Note: menu subcollection will remain unless you explicitly delete it.
    // If you want to remove menu items too, call deleteRestaurantWithMenu.
  }

  /// Delete restaurant and its menu subcollection (careful, destructive)
  Future<void> deleteRestaurantWithMenu(String restaurantId) async {
    final menuCol = _db.collection('restaurants').doc(restaurantId).collection('menu');
    final menuSnap = await menuCol.get();
    final batch = _db.batch();
    for (final doc in menuSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('restaurants').doc(restaurantId));
    await batch.commit();
  }

  /// Helper to list menu items for a restaurant
  Stream<QuerySnapshot<Map<String, dynamic>>> streamRestaurantMenu(String restaurantId) {
    return _db.collection('restaurants').doc(restaurantId).collection('menu').orderBy('createdAt', descending: true).snapshots();
  }

  /// Add or update a menu item
  Future<void> upsertMenuItem(String restaurantId, {String? itemId, required Map<String, dynamic> data}) async {
    final col = _db.collection('restaurants').doc(restaurantId).collection('menu');
    final payload = <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (itemId == null) {
      payload['createdAt'] = FieldValue.serverTimestamp();
      await col.add(payload);
    } else {
      if (data['createdAt'] == null) payload['createdAt'] = FieldValue.serverTimestamp();
      await col.doc(itemId).set(payload, SetOptions(merge: true));
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String restaurantId, String itemId) async {
    await _db.collection('restaurants').doc(restaurantId).collection('menu').doc(itemId).delete();
  }

  /// Utility to get current authenticated user id
  String? currentUid() => _auth.currentUser?.uid;
}
