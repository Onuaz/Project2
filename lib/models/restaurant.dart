class Restaurant {
  final String id;
  final String name;
  final String address;
  final String imageUrl;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
  });

  factory Restaurant.fromDoc(Map<String, dynamic> d, String id) {
    return Restaurant(
      id: id,
      name: d['name'],
      address: d['address'],
      imageUrl: d['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
    };
  }
}
