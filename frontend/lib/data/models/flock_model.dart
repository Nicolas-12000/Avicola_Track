class FlockModel {
  final int id;
  final int shedId;
  final String? shedName;
  final int farmId;
  final String? farmName;
  final String breed;
  final int initialQuantity;
  final int currentQuantity;
  final double? initialWeight;
  final double? currentWeight;
  final String gender;
  final DateTime arrivalDate;
  final DateTime? saleDate;
  final String? supplier;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FlockModel({
    required this.id,
    required this.shedId,
    this.shedName,
    required this.farmId,
    this.farmName,
    required this.breed,
    required this.initialQuantity,
    required this.currentQuantity,
    this.initialWeight,
    this.currentWeight,
    required this.gender,
    required this.arrivalDate,
    this.saleDate,
    this.supplier,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory FlockModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return FlockModel(
      id: json['id'] as int,
      shedId: json['shed'] as int? ?? 0,
      shedName: json['shed_name'] as String?,
      farmId: json['farm'] as int? ?? 0,
      farmName: json['farm_name'] as String?,
      breed: json['breed'] as String? ?? 'Desconocida',
      initialQuantity: json['initial_quantity'] as int? ?? 0,
      currentQuantity: json['current_quantity'] as int? ?? 0,
      initialWeight: toDouble(json['initial_weight']),
      currentWeight: toDouble(json['current_weight']),
      gender: json['gender'] as String? ?? 'Mixed',
      arrivalDate: json['arrival_date'] != null 
          ? DateTime.parse(json['arrival_date'] as String)
          : DateTime.now(),
      saleDate: json['sale_date'] != null
          ? DateTime.parse(json['sale_date'] as String)
          : null,
      supplier: json['supplier'] as String?,
      // Normalize status values coming from the backend (e.g. 'ACTIVE')
      // into the app's expected casing ('Active', 'Sold', 'Terminated').
      status: (() {
        final raw = (json['status'] as String? ?? 'ACTIVE').toString().toUpperCase();
        switch (raw) {
          case 'ACTIVE':
            return 'Active';
          case 'SOLD':
            return 'Sold';
          case 'TERMINATED':
            return 'Terminated';
          default:
            // Fallback: return capitalized form of the raw value
            final lower = raw.toLowerCase();
            return lower.isEmpty ? lower : '${lower[0].toUpperCase()}${lower.substring(1)}';
        }
      })(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shed': shedId,
      'farm': farmId,
      'breed': breed,
      'initial_quantity': initialQuantity,
      'current_quantity': currentQuantity,
      'initial_weight': initialWeight,
      'current_weight': currentWeight,
      'gender': gender,
      'arrival_date': arrivalDate.toIso8601String().split('T')[0],
      'sale_date': saleDate?.toIso8601String().split('T')[0],
      'supplier': supplier,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  int get ageInDays {
    return DateTime.now().difference(arrivalDate).inDays;
  }

  int get deadCount => initialQuantity - currentQuantity;

  double get mortalityRate {
    if (initialQuantity == 0) return 0.0;
    return (deadCount / initialQuantity) * 100;
  }

  double? get weightGain {
    if (initialWeight == null || currentWeight == null) return null;
    return currentWeight! - initialWeight!;
  }

  bool get isActive => status == 'Active';
  bool get isSold => status == 'Sold';
  bool get isTerminated => status == 'Terminated';

  FlockModel copyWith({
    int? id,
    int? shedId,
    String? shedName,
    int? farmId,
    String? farmName,
    String? breed,
    int? initialQuantity,
    int? currentQuantity,
    double? initialWeight,
    double? currentWeight,
    String? gender,
    DateTime? arrivalDate,
    DateTime? saleDate,
    String? supplier,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlockModel(
      id: id ?? this.id,
      shedId: shedId ?? this.shedId,
      shedName: shedName ?? this.shedName,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      breed: breed ?? this.breed,
      initialQuantity: initialQuantity ?? this.initialQuantity,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      initialWeight: initialWeight ?? this.initialWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      gender: gender ?? this.gender,
      arrivalDate: arrivalDate ?? this.arrivalDate,
      saleDate: saleDate ?? this.saleDate,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
