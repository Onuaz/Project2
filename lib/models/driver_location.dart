class DriverLocation {
  final double lat;
  final double lng;

  DriverLocation({
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }

  factory DriverLocation.fromMap(Map<String, dynamic> d) {
    return DriverLocation(
      lat: (d['lat'] as num).toDouble(),
      lng: (d['lng'] as num).toDouble(),
    );
  }
}
