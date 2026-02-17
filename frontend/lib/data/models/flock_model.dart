import 'package:flutter/material.dart';

/// Etapas del proceso de producción avícola.
enum ProductionStage {
  breeder('BREEDER', 'Rebaño reproductor', Icons.egg_alt),
  pulletFarm('PULLET_FARM', 'Granja de pletinas', Icons.house),
  brooder('BROODER', 'Casa criadora', Icons.heat_pump),
  hatchery('HATCHERY', 'Criadero', Icons.child_care),
  growOut('GROW_OUT', 'Granja de engorde', Icons.agriculture),
  processing('PROCESSING', 'Procesamiento', Icons.factory),
  distribution('DISTRIBUTION', 'Distribución', Icons.local_shipping);

  final String value;
  final String label;
  final IconData icon;
  const ProductionStage(this.value, this.label, this.icon);

  static ProductionStage fromValue(String? v) =>
      ProductionStage.values.firstWhere(
        (e) => e.value == v,
        orElse: () => ProductionStage.growOut,
      );
}

/// Sub-etapas de procesamiento industrial.
enum ProcessingStage {
  reception('RECEPTION', 'Recepción y Espera'),
  hanging('HANGING', 'Colgado'),
  stunning('STUNNING', 'Aturdimiento y Sacrificio'),
  bleeding('BLEEDING', 'Desangrado'),
  scalding('SCALDING', 'Escaldado y Desplumado'),
  evisceration('EVISCERATION', 'Eviscerado'),
  postMortem('POST_MORTEM', 'Inspección Post-Mortem'),
  chilling('CHILLING', 'Enfriamiento'),
  classification('CLASSIFICATION', 'Clasificación y Empaque'),
  storage('STORAGE', 'Almacenamiento y Distribución');

  final String value;
  final String label;
  const ProcessingStage(this.value, this.label);

  static ProcessingStage? fromValue(String? v) {
    if (v == null || v.isEmpty) return null;
    return ProcessingStage.values.firstWhere(
      (e) => e.value == v,
      orElse: () => ProcessingStage.reception,
    );
  }
}

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

  // Sub-grupos Machos/Hembras
  final int initialQuantityMale;
  final int initialQuantityFemale;
  final int currentQuantityMale;
  final int currentQuantityFemale;
  final double? initialWeightMale;
  final double? initialWeightFemale;

  // Etapas de producción
  final ProductionStage productionStage;
  final ProcessingStage? processingStage;

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
    this.initialQuantityMale = 0,
    this.initialQuantityFemale = 0,
    this.currentQuantityMale = 0,
    this.currentQuantityFemale = 0,
    this.initialWeightMale,
    this.initialWeightFemale,
    this.productionStage = ProductionStage.growOut,
    this.processingStage,
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
      initialQuantityMale: json['initial_quantity_male'] as int? ?? 0,
      initialQuantityFemale: json['initial_quantity_female'] as int? ?? 0,
      currentQuantityMale: json['current_quantity_male'] as int? ?? 0,
      currentQuantityFemale: json['current_quantity_female'] as int? ?? 0,
      initialWeightMale: toDouble(json['initial_weight_male']),
      initialWeightFemale: toDouble(json['initial_weight_female']),
      productionStage: ProductionStage.fromValue(json['production_stage'] as String?),
      processingStage: ProcessingStage.fromValue(json['processing_stage'] as String?),
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
      'initial_quantity_male': initialQuantityMale,
      'initial_quantity_female': initialQuantityFemale,
      'current_quantity_male': currentQuantityMale,
      'current_quantity_female': currentQuantityFemale,
      'initial_weight_male': initialWeightMale,
      'initial_weight_female': initialWeightFemale,
      'production_stage': productionStage.value,
      'processing_stage': processingStage?.value,
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

  int get ageInWeeks {
    final days = ageInDays;
    return days > 0 ? (days ~/ 7) + (days % 7 > 0 ? 1 : 0) : 0;
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
    int? initialQuantityMale,
    int? initialQuantityFemale,
    int? currentQuantityMale,
    int? currentQuantityFemale,
    double? initialWeightMale,
    double? initialWeightFemale,
    ProductionStage? productionStage,
    ProcessingStage? processingStage,
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
      initialQuantityMale: initialQuantityMale ?? this.initialQuantityMale,
      initialQuantityFemale: initialQuantityFemale ?? this.initialQuantityFemale,
      currentQuantityMale: currentQuantityMale ?? this.currentQuantityMale,
      currentQuantityFemale: currentQuantityFemale ?? this.currentQuantityFemale,
      initialWeightMale: initialWeightMale ?? this.initialWeightMale,
      initialWeightFemale: initialWeightFemale ?? this.initialWeightFemale,
      productionStage: productionStage ?? this.productionStage,
      processingStage: processingStage ?? this.processingStage,
    );
  }
}
