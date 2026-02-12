import '../../core/utils/json_parsers.dart';

class DispatchRecordModel {
  final int id;
  final int flockId;
  final String? flockInfo;

  // Info general
  final DateTime dispatchDate;
  final int dayNumber;
  final String manifestNumber;
  final String shedName;

  // Cantidades
  final int malesCount;
  final int femalesCount;
  final int totalBirds;

  // Peso granja
  final double farmAvgWeight;
  final double farmTotalKg;

  // Planta proceso
  final int? plantBirds;
  final int plantMissing;
  final int drowned;
  final double? plantAvgWeight;
  final double? plantTotalKg;
  final double? plantShrinkageGrams;

  // Venta
  final int? saleBirds;
  final double saleDiscountKg;
  final double? saleTotalKg;
  final double? saleAvgWeight;
  final double? totalShrinkageGrams;

  // Otros
  final String? observations;
  final int? recordedBy;
  final String? clientId;
  final String? syncStatus;
  final DateTime? createdAt;

  DispatchRecordModel({
    required this.id,
    required this.flockId,
    this.flockInfo,
    required this.dispatchDate,
    this.dayNumber = 0,
    required this.manifestNumber,
    this.shedName = '',
    this.malesCount = 0,
    this.femalesCount = 0,
    required this.totalBirds,
    required this.farmAvgWeight,
    required this.farmTotalKg,
    this.plantBirds,
    this.plantMissing = 0,
    this.drowned = 0,
    this.plantAvgWeight,
    this.plantTotalKg,
    this.plantShrinkageGrams,
    this.saleBirds,
    this.saleDiscountKg = 0,
    this.saleTotalKg,
    this.saleAvgWeight,
    this.totalShrinkageGrams,
    this.observations,
    this.recordedBy,
    this.clientId,
    this.syncStatus,
    this.createdAt,
  });

  /// Merma planta como porcentaje
  double? get plantShrinkagePercent {
    if (farmTotalKg <= 0 || plantTotalKg == null) return null;
    return ((farmTotalKg - plantTotalKg!) / farmTotalKg) * 100;
  }

  /// Merma total como porcentaje
  double? get totalShrinkagePercent {
    if (farmTotalKg <= 0 || saleTotalKg == null) return null;
    return ((farmTotalKg - saleTotalKg!) / farmTotalKg) * 100;
  }

  factory DispatchRecordModel.fromJson(Map<String, dynamic> json) {
    return DispatchRecordModel(
      id: json['id'] as int,
      flockId: json['flock'] as int,
      flockInfo: json['flock_info'] as String?,
      dispatchDate: DateTime.parse(json['dispatch_date'] as String),
      dayNumber: json['day_number'] as int? ?? 0,
      manifestNumber: json['manifest_number'] as String? ?? '',
      shedName: json['shed_name'] as String? ?? '',
      malesCount: json['males_count'] as int? ?? 0,
      femalesCount: json['females_count'] as int? ?? 0,
      totalBirds: json['total_birds'] as int? ?? 0,
      farmAvgWeight: JsonParsers.toDouble(json['farm_avg_weight']),
      farmTotalKg: JsonParsers.toDouble(json['farm_total_kg']),
      plantBirds: json['plant_birds'] as int?,
      plantMissing: json['plant_missing'] as int? ?? 0,
      drowned: json['drowned'] as int? ?? 0,
      plantAvgWeight: JsonParsers.toDoubleNullable(json['plant_avg_weight']),
      plantTotalKg: JsonParsers.toDoubleNullable(json['plant_total_kg']),
      plantShrinkageGrams: JsonParsers.toDoubleNullable(json['plant_shrinkage_grams']),
      saleBirds: json['sale_birds'] as int?,
      saleDiscountKg: JsonParsers.toDouble(json['sale_discount_kg']),
      saleTotalKg: JsonParsers.toDoubleNullable(json['sale_total_kg']),
      saleAvgWeight: JsonParsers.toDoubleNullable(json['sale_avg_weight']),
      totalShrinkageGrams: JsonParsers.toDoubleNullable(json['total_shrinkage_grams']),
      observations: json['observations'] as String?,
      recordedBy: json['recorded_by'] as int?,
      clientId: json['client_id'] as String?,
      syncStatus: json['sync_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flock': flockId,
      'dispatch_date': JsonParsers.toDateString(dispatchDate),
      'manifest_number': manifestNumber,
      'shed_name': shedName,
      'males_count': malesCount,
      'females_count': femalesCount,
      'total_birds': totalBirds,
      'farm_avg_weight': farmAvgWeight,
      'farm_total_kg': farmTotalKg,
      'plant_birds': plantBirds,
      'plant_missing': plantMissing,
      'drowned': drowned,
      'plant_avg_weight': plantAvgWeight,
      'plant_total_kg': plantTotalKg,
      'sale_birds': saleBirds,
      'sale_discount_kg': saleDiscountKg,
      'sale_total_kg': saleTotalKg,
      'sale_avg_weight': saleAvgWeight,
      'observations': observations ?? '',
      'client_id': clientId,
    };
  }
}
