import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/driver_location.dart';

class DriverLocationService {
  final _drivers = FirebaseFirestore.instance.collection('driver_locations');

  Future<void> updateLocation(String driverId, DriverLocation loc) async {
    await _drivers.doc(driverId).set(loc.toMap());
  }

  Stream<DriverLocation> watchDriver(String driverId) {
    return _drivers.doc(driverId).snapshots().map(
          (d) => DriverLocation.fromMap(d.data()!),
        );
  }
}
