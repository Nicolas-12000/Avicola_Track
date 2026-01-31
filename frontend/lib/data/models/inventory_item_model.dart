class InventoryItemModel {
  final int id;
  final int farmId;
  final String? farmName;
  final int? shedId;
  final String? shedName;
  final String name;
  final String? description;
  final String unit;
  final double currentStock;
  final double minimumStock;
  final double? dailyAvgConsumption;
  final DateTime? lastRestockDate;
  final DateTime? lastConsumptionDate;
  final int alertThresholdDays;
  final int criticalThresholdDays;
  final DateTime? projectedStockoutDate;
  final Map<String, dynamic>? stockStatus;

  InventoryItemModel({
    required this.id,
    required this.farmId,
    this.farmName,
    this.shedId,
    this.shedName,
    required this.name,
    this.description,
    required this.unit,
    required this.currentStock,
    required this.minimumStock,
    this.dailyAvgConsumption,
    this.lastRestockDate,
    this.lastConsumptionDate,
    this.alertThresholdDays = 5,
    this.criticalThresholdDays = 2,
    this.projectedStockoutDate,
    this.stockStatus,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    return InventoryItemModel(
      id: json['id'] as int,
      farmId: json['farm'] as int,
      farmName: json['farm_name'] as String?,
      shedId: json['shed'] as int?,
      shedName: json['shed_name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      unit: json['unit'] as String,
      currentStock: _parseDouble(json['current_stock']),
      minimumStock: _parseDouble(json['minimum_stock']),
      dailyAvgConsumption: _parseNullableDouble(json['daily_avg_consumption']),
      lastRestockDate: json['last_restock_date'] != null
          ? DateTime.parse(json['last_restock_date'] as String)
          : null,
      lastConsumptionDate: json['last_consumption_date'] != null
          ? DateTime.parse(json['last_consumption_date'] as String)
          : null,
      alertThresholdDays: _parseInt(json['alert_threshold_days'], defaultValue: 5),
      criticalThresholdDays: _parseInt(json['critical_threshold_days'], defaultValue: 2),
      projectedStockoutDate: json['projected_stockout_date'] != null
          ? DateTime.parse(json['projected_stockout_date'] as String)
          : null,
      stockStatus: _parseStockStatus(json['stock_status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm': farmId,
      'shed': shedId,
      'name': name,
      'description': description,
      'unit': unit,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'alert_threshold_days': alertThresholdDays,
      'critical_threshold_days': criticalThresholdDays,
    };
  }

  String get stockStatusLabel {
    if (stockStatus == null) return 'unknown';
    return (stockStatus!['status'] as String?)?.toLowerCase() ?? 'unknown';
  }

  int? get daysUntilEmpty {
    if (dailyAvgConsumption == null || dailyAvgConsumption! <= 0) return null;
    return (currentStock / dailyAvgConsumption!).ceil();
  }

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  bool get isCritical => daysUntilEmpty != null && daysUntilEmpty! <= criticalThresholdDays;
  bool get isAlert => daysUntilEmpty != null && daysUntilEmpty! <= alertThresholdDays;

  InventoryItemModel copyWith({
    int? id,
    int? farmId,
    String? farmName,
    int? shedId,
    String? shedName,
    String? name,
    String? description,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? dailyAvgConsumption,
    DateTime? lastRestockDate,
    DateTime? lastConsumptionDate,
    int? alertThresholdDays,
    int? criticalThresholdDays,
    DateTime? projectedStockoutDate,
    Map<String, dynamic>? stockStatus,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      shedId: shedId ?? this.shedId,
      shedName: shedName ?? this.shedName,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock ?? this.minimumStock,
      dailyAvgConsumption: dailyAvgConsumption ?? this.dailyAvgConsumption,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      lastConsumptionDate: lastConsumptionDate ?? this.lastConsumptionDate,
      alertThresholdDays: alertThresholdDays ?? this.alertThresholdDays,
      criticalThresholdDays: criticalThresholdDays ?? this.criticalThresholdDays,
      projectedStockoutDate: projectedStockoutDate ?? this.projectedStockoutDate,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static int _parseInt(dynamic value, {required int defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return defaultValue;
  }

  static Map<String, dynamic>? _parseStockStatus(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    return null;
  }
}
