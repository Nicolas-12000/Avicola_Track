class InventoryItemModel {
  final int id;
  final int farmId;
  final String? farmName;
  final String name;
  final String category;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double? averageConsumption;
  final DateTime? expirationDate;
  final String? supplier;
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryItemModel({
    required this.id,
    required this.farmId,
    this.farmName,
    required this.name,
    required this.category,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    this.averageConsumption,
    this.expirationDate,
    this.supplier,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as int,
      farmId: json['farm'] as int,
      farmName: json['farm_name'] as String?,
      name: json['name'] as String,
      category: json['category'] as String,
      unit: json['unit'] as String,
      currentStock: (json['current_stock'] as num).toDouble(),
      minimumStock: (json['minimum_stock'] as num).toDouble(),
      averageConsumption: (json['average_consumption'] as num?)?.toDouble(),
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      supplier: json['supplier'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm': farmId,
      'name': name,
      'category': category,
      'unit': unit,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'average_consumption': averageConsumption,
      'expiration_date': expirationDate?.toIso8601String().split('T')[0],
      'supplier': supplier,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get stockStatus {
    if (currentStock <= 0) return 'out_of_stock';
    if (currentStock <= minimumStock) return 'low_stock';
    if (currentStock <= minimumStock * 1.5) return 'warning';
    return 'normal';
  }

  int? get daysUntilEmpty {
    if (averageConsumption == null || averageConsumption! <= 0) return null;
    return (currentStock / averageConsumption!).ceil();
  }

  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final daysUntilExpiration = expirationDate!
        .difference(DateTime.now())
        .inDays;
    return daysUntilExpiration <= 7 && daysUntilExpiration >= 0;
  }

  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  InventoryItemModel copyWith({
    int? id,
    int? farmId,
    String? farmName,
    String? name,
    String? category,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? averageConsumption,
    DateTime? expirationDate,
    String? supplier,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      name: name ?? this.name,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      averageConsumption: averageConsumption ?? this.averageConsumption,
      expirationDate: expirationDate ?? this.expirationDate,
      supplier: supplier ?? this.supplier,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
