class MortalityRecordModel {
  final int id;
  final int flockId;
  final int quantity;
  final String cause;
  final DateTime recordDate;
  final double? temperature;
  final String? notes;
  final DateTime createdAt;

  MortalityRecordModel({
    required this.id,
    required this.flockId,
    required this.quantity,
    required this.cause,
    required this.recordDate,
    this.temperature,
    this.notes,
    required this.createdAt,
  });

  factory MortalityRecordModel.fromJson(Map<String, dynamic> json) {
    return MortalityRecordModel(
      id: json['id'] as int,
      flockId: json['flock'] as int,
      quantity: json['quantity'] as int,
      cause: json['cause'] as String,
      recordDate: DateTime.parse(json['record_date'] as String),
      temperature: (json['temperature'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock': flockId,
      'quantity': quantity,
      'cause': cause,
      'record_date': recordDate.toIso8601String().split('T')[0],
      'temperature': temperature,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
