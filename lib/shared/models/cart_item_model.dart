class CartItemModel {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;
  final String? variation;

  CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.variation,
  });

  CartItemModel copyWith({
    int? id,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? variation,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      variation: variation ?? this.variation,
    );
  }

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 1,
      imageUrl: map['image_url'] ?? '',
      variation: map['variation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
      'variation': variation,
    };
  }
}
