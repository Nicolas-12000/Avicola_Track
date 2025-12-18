class AlarmModel {
  final int id;
  final int farmId;
  final String? farmName;
  final int? flockId;
  final String? flockInfo;
  final String alarmType;
  final String severity;
  final String title;
  final String description;
  final bool isResolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  AlarmModel({
    required this.id,
    required this.farmId,
    this.farmName,
    this.flockId,
    this.flockInfo,
    required this.alarmType,
    required this.severity,
    required this.title,
    required this.description,
    required this.isResolved,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNotes,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as int,
      farmId: json['farm'] as int,
      farmName: json['farm_name'] as String?,
      flockId: json['flock'] as int?,
      flockInfo: json['flock_info'] as String?,
      alarmType: json['alarm_type'] as String,
      severity: json['severity'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isResolved: json['is_resolved'] as bool,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionNotes: json['resolution_notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm': farmId,
      'flock': flockId,
      'alarm_type': alarmType,
      'severity': severity,
      'title': title,
      'description': description,
      'is_resolved': isResolved,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isCritical => severity == 'critical';
  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isLow => severity == 'low';

  Duration get age => DateTime.now().difference(createdAt);

  AlarmModel copyWith({
    int? id,
    int? farmId,
    String? farmName,
    int? flockId,
    String? flockInfo,
    String? alarmType,
    String? severity,
    String? title,
    String? description,
    bool? isResolved,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? resolutionNotes,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      flockId: flockId ?? this.flockId,
      flockInfo: flockInfo ?? this.flockInfo,
      alarmType: alarmType ?? this.alarmType,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      isResolved: isResolved ?? this.isResolved,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
