class Product {
  Product({
    required this.id,
    this.name,
    required this.price,
    this.description,
    required this.stock,
    required this.isActive,
    required this.createdDate,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'],
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdDate: DateTime.tryParse(json['createdDate'] ?? '') ?? DateTime.now(),
    );
  }

  final int id;
  final String? name;
  final double price;
  final String? description;
  final int stock;
  final bool isActive;
  final DateTime createdDate;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'stock': stock,
      'isActive': isActive,
      'createdDate': createdDate.toIso8601String(),
    };
  }

  Product copyWith({
    int? id,
    String? name,
    double? price,
    String? description,
    int? stock,
    bool? isActive,
    DateTime? createdDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
