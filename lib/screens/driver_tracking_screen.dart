import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverTrackingScreen extends StatelessWidget {
  final String driverId;
  const DriverTrackingScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Location")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data() as Map<String, dynamic>;
          final lat = (data['lat'] ?? 0).toDouble();
          final lng = (data['lng'] ?? 0).toDouble();
          final pos = LatLng(lat, lng);

          return GoogleMap(
            initialCameraPosition: CameraPosition(target: pos, zoom: 14),
            markers: {
              Marker(
                markerId: const MarkerId('driver'),
                position: pos,
              ),
            },
          );
        },
      ),
    );
  }
}
