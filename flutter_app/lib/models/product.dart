class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String image;
  final String unit;
  final String category;
  final bool inStock;
  final int? quantity;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.unit,
    required this.category,
    required this.inStock,
    this.quantity,
  });

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? unit,
    String? category,
    bool? inStock,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      inStock: inStock ?? this.inStock,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'unit': unit,
      'category': category,
      'inStock': inStock,
      'quantity': quantity,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      unit: json['unit'] as String,
      category: json['category'] as String,
      inStock: json['inStock'] as bool,
      quantity: json['quantity'] as int?,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });
}
