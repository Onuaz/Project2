import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/restaurant.dart';
import '../models/menu_item.dart';
import 'dart:io';

class RestaurantService {
  final _restaurants = FirebaseFirestore.instance.collection('restaurants');

  Stream<List<Restaurant>> watchRestaurants() {
    return _restaurants.snapshots().map(
      (s) => s.docs
          .map((d) => Restaurant.fromDoc(d.data(), d.id))
          .toList(),
    );
  }

  Stream<List<MenuItemModel>> watchMenu(String restaurantId) {
    return _restaurants
        .doc(restaurantId)
        .collection('menu')
        .snapshots()
        .map((s) => s.docs
            .map((d) => MenuItemModel.fromDoc(d.data(), d.id))
            .toList());
  }

  Future<String> uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('menu_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> addMenuItem(
    String restaurantId,
    String name,
    double price,
    String imageUrl,
  ) async {
    await _restaurants
        .doc(restaurantId)
        .collection('menu')
        .add({
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    });
  }

  Future<void> createRestaurant(
    String name,
    String address,
    String imageUrl,
  ) async {
    await _restaurants.add({
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
    });
  }
}
