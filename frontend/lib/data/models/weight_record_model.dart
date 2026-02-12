import '../../core/utils/json_parsers.dart';

class WeightRecordModel {
  final int id;
  final int flockId;
  final double averageWeight;
  final int sampleSize;
  final DateTime recordDate;
  final String? notes;
  final DateTime createdAt;

  WeightRecordModel({
    required this.id,
    required this.flockId,
    required this.averageWeight,
    required this.sampleSize,
    required this.recordDate,
    this.notes,
    required this.createdAt,
  });

  factory WeightRecordModel.fromJson(Map<String, dynamic> json) {
    return WeightRecordModel(
      id: json['id'] as int,
      flockId: json['flock'] as int,
      averageWeight: JsonParsers.toDouble(json['average_weight']),
      sampleSize: JsonParsers.toInt(json['sample_size']),
      recordDate: DateTime.parse(json['record_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock': flockId,
      'average_weight': averageWeight,
      'sample_size': sampleSize,
      'record_date': JsonParsers.toDateString(recordDate),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
