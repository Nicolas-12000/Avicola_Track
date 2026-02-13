import '../../core/utils/json_parsers.dart';

class AlarmConfigModel {
  final int? id;
  final String alarmType;
  final int farmId;
  final double thresholdValue;
  final double? criticalThreshold;
  final int evaluationPeriodHours;
  final int consecutiveOccurrences;
  final bool notifyFarmManager;
  final bool notifyVeterinarian;
  final bool notifyGalponeros;
  final bool isActive;

  AlarmConfigModel({
    this.id,
    required this.alarmType,
    required this.farmId,
    required this.thresholdValue,
    this.criticalThreshold,
    required this.evaluationPeriodHours,
    required this.consecutiveOccurrences,
    required this.notifyFarmManager,
    required this.notifyVeterinarian,
    required this.notifyGalponeros,
    required this.isActive,
  });

  factory AlarmConfigModel.fromJson(Map<String, dynamic> json) {
    return AlarmConfigModel(
      id: json['id'] as int?,
      alarmType: json['alarm_type'] as String? ?? '',
      farmId: json['farm'] as int? ?? 0,
      thresholdValue: JsonParsers.toDouble(json['threshold_value']),
      criticalThreshold: JsonParsers.toDoubleNullable(json['critical_threshold']),
      evaluationPeriodHours: json['evaluation_period_hours'] as int? ?? 24,
      consecutiveOccurrences: json['consecutive_occurrences'] as int? ?? 1,
      notifyFarmManager: json['notify_farm_manager'] as bool? ?? true,
      notifyVeterinarian: json['notify_veterinarian'] as bool? ?? true,
      notifyGalponeros: json['notify_galponeros'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'alarm_type': alarmType,
      'farm': farmId,
      'threshold_value': thresholdValue,
      'critical_threshold': criticalThreshold,
      'evaluation_period_hours': evaluationPeriodHours,
      'consecutive_occurrences': consecutiveOccurrences,
      'notify_farm_manager': notifyFarmManager,
      'notify_veterinarian': notifyVeterinarian,
      'notify_galponeros': notifyGalponeros,
      'is_active': isActive,
    };
  }

}
