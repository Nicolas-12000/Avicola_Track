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
      averageWeight: _toDouble(json['average_weight']),
      sampleSize: _toInt(json['sample_size']),
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
      'record_date': recordDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
