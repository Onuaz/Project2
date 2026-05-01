class Order {
  int? id;
  String restaurant;
  String item;
  String? notes;
  String status;
  String timestamp;

  Order({
    this.id,
    required this.restaurant,
    required this.item,
    this.notes,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'restaurant': restaurant,
      'item': item,
      'notes': notes,
      'status': status,
      'timestamp': timestamp,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      restaurant: map['restaurant'] as String,
      item: map['item'] as String,
      notes: map['notes'] as String?,
      status: map['status'] as String,
      timestamp: map['timestamp'] as String,
    );
  }
}
