class Product {
  final String id;
  final String code;
  final String name;
  final String category;
  final double buyPrice;
  final double sellPrice;
  final int stock;
  final String unit;
  final String createdAt;

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.buyPrice,
    required this.sellPrice,
    required this.stock,
    required this.unit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
      'unit': unit,
      'created_at': createdAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Umum',
      buyPrice: (map['buy_price'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      unit: map['unit'] as String? ?? 'pcs',
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Product copyWith({
    String? id,
    String? code,
    String? name,
    String? category,
    double? buyPrice,
    double? sellPrice,
    int? stock,
    String? unit,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
