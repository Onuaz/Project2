import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

double _deg2rad(double deg) => deg * pi / 180.0;

double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

Future<void> assignBestDriverToOrder(String orderId) async {
  final db = FirebaseFirestore.instance;

  final orderSnap = await db.collection('orders').doc(orderId).get();
  if (!orderSnap.exists) return;
  final order = orderSnap.data()!;
  final restaurantId = order['restaurantId'] as String;
  final urgency = (order['urgency'] ?? 1) as num;

  final restSnap = await db.collection('restaurants').doc(restaurantId).get();
  if (!restSnap.exists) return;
  final rest = restSnap.data()!;
  final rLat = (rest['lat'] ?? 0).toDouble();
  final rLng = (rest['lng'] ?? 0).toDouble();

  final driversSnap = await db
      .collection('drivers')
      .where('available', isEqualTo: true)
      .get();
  if (driversSnap.docs.isEmpty) return;

  String? bestDriverId;
  double bestScore = -1;
  final explanations = <String, dynamic>{};

  for (final d in driversSnap.docs) {
    final data = d.data();
    final dLat = (data['lat'] ?? 0).toDouble();
    final dLng = (data['lng'] ?? 0).toDouble();
    final status = (data['status'] ?? 'idle') as String;
    final load = (data['currentLoad'] ?? 0) as num;

    final distKm = _distanceKm(rLat, rLng, dLat, dLng);
    final distScore = 1 / (1 + distKm);
    final urgencyScore = urgency.toDouble();
    final statusScore = status == 'idle' ? 1.0 : 0.5;
    final loadPenalty = 1 / (1 + load);

    final score = distScore * 0.5 +
        urgencyScore * 0.3 +
        statusScore * 0.2;
    final finalScore = score * loadPenalty;

    explanations[d.id] = {
      'distanceKm': distKm,
      'distScore': distScore,
      'urgency': urgency,
      'urgencyScore': urgencyScore,
      'status': status,
      'statusScore': statusScore,
      'load': load,
      'loadPenalty': loadPenalty,
      'finalScore': finalScore,
    };

    if (finalScore > bestScore) {
      bestScore = finalScore;
      bestDriverId = d.id;
    }
  }

  if (bestDriverId == null) return;

  await db.collection('orders').doc(orderId).update({
    'driverId': bestDriverId,
    'status': 'assigned',
    'assignedAt': FieldValue.serverTimestamp(),
  });

  await db
      .collection('orders')
      .doc(orderId)
      .collection('driver_scores')
      .add({
    'createdAt': FieldValue.serverTimestamp(),
    'explanations': explanations,
    'chosenDriverId': bestDriverId,
  });
}
