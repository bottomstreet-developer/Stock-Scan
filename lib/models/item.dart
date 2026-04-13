class Item {
  const Item({
    this.id,
    required this.name,
    this.sku,
    this.barcode,
    required this.quantity,
    required this.costPrice,
    required this.sellPrice,
    this.photoPath,
    this.category,
    required this.minQuantity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String? sku;
  final String? barcode;
  final int quantity;
  final double costPrice;
  final double sellPrice;
  final String? photoPath;
  final String? category;
  final int minQuantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get profit => sellPrice - costPrice;

  double get profitMargin {
    if (sellPrice <= 0) return 0;
    return ((sellPrice - costPrice) / sellPrice) * 100;
  }

  double get totalValue => quantity * costPrice;

  double get totalRevenue => quantity * sellPrice;

  bool get isLowStock => minQuantity > 0 && quantity <= minQuantity;

  Item copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    int? quantity,
    double? costPrice,
    double? sellPrice,
    String? photoPath,
    String? category,
    int? minQuantity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      photoPath: photoPath ?? this.photoPath,
      category: category ?? this.category,
      minQuantity: minQuantity ?? this.minQuantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'quantity': quantity,
      'cost_price': costPrice,
      'sell_price': sellPrice,
      'photo_path': photoPath,
      'category': category,
      'min_quantity': minQuantity,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as int?,
      name: map['name'] as String,
      sku: map['sku'] as String?,
      barcode: map['barcode'] as String?,
      quantity: map['quantity'] as int? ?? 0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      sellPrice: (map['sell_price'] as num?)?.toDouble() ?? 0,
      photoPath: map['photo_path'] as String?,
      category: map['category'] as String?,
      minQuantity: map['min_quantity'] as int? ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
