class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
  });

  factory MenuItemModel.fromDoc(Map<String, dynamic> d, String id) {
    return MenuItemModel(
      id: id,
      name: d['name'],
      price: (d['price'] as num).toDouble(),
      imageUrl: d['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
