class VeterinaryVisitModel {
  final int id;
  final int? farmId; // Ahora la visita es a una granja
  final List<int> flockIds; // Múltiples lotes pueden ser revisados
  final int veterinarianId;
  final DateTime visitDate;
  final int expectedDurationDays; // Duración estimada en días
  final String visitType; // routine, emergency, vaccination, treatment
  final String? reason; // Motivo de la visita
  final String? diagnosis;
  final String? treatment;
  final String? prescribedMedications;
  final String? notes;
  final List<String>? photoUrls;
  final String status; // scheduled, in_progress, completed, cancelled
  final DateTime? completedAt;
  final DateTime createdAt;

  const VeterinaryVisitModel({
    required this.id,
    this.farmId,
    this.flockIds = const [],
    required this.veterinarianId,
    required this.visitDate,
    this.expectedDurationDays = 1,
    required this.visitType,
    this.reason,
    this.diagnosis,
    this.treatment,
    this.prescribedMedications,
    this.notes,
    this.photoUrls,
    required this.status,
    this.completedAt,
    required this.createdAt,
  });

  factory VeterinaryVisitModel.fromJson(Map<String, dynamic> json) {
    return VeterinaryVisitModel(
      id: json['id'] as int,
      farmId: json['farm_id'] as int?,
      flockIds: (json['flock_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      veterinarianId: json['veterinarian_id'] as int,
      visitDate: DateTime.parse(json['visit_date'] as String),
      expectedDurationDays: json['expected_duration_days'] as int? ?? 1,
      visitType: json['visit_type'] as String,
      reason: json['reason'] as String?,
      diagnosis: json['diagnosis'] as String?,
      treatment: json['treatment'] as String?,
      prescribedMedications: json['prescribed_medications'] as String?,
      notes: json['notes'] as String?,
      photoUrls: (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: json['status'] as String,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farm_id': farmId,
      'flock_ids': flockIds,
      'veterinarian_id': veterinarianId,
      'visit_date': visitDate.toIso8601String(),
      'expected_duration_days': expectedDurationDays,
      'visit_type': visitType,
      'reason': reason,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'prescribed_medications': prescribedMedications,
      'notes': notes,
      'photo_urls': photoUrls,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  VeterinaryVisitModel copyWith({
    int? id,
    int? farmId,
    List<int>? flockIds,
    int? veterinarianId,
    DateTime? visitDate,
    int? expectedDurationDays,
    String? visitType,
    String? reason,
    String? diagnosis,
    String? treatment,
    String? prescribedMedications,
    String? notes,
    List<String>? photoUrls,
    String? status,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return VeterinaryVisitModel(
      id: id ?? this.id,
      farmId: farmId ?? this.farmId,
      flockIds: flockIds ?? this.flockIds,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      visitDate: visitDate ?? this.visitDate,
      expectedDurationDays: expectedDurationDays ?? this.expectedDurationDays,
      visitType: visitType ?? this.visitType,
      reason: reason ?? this.reason,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      prescribedMedications:
          prescribedMedications ?? this.prescribedMedications,
      notes: notes ?? this.notes,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isCompleted => status == 'completed';
  bool get isScheduled => status == 'scheduled';
  bool get isPending =>
      status == 'scheduled' && visitDate.isAfter(DateTime.now());
  bool get isOverdue =>
      status == 'scheduled' && visitDate.isBefore(DateTime.now());
  bool get isEmergency => visitType == 'emergency';
  bool get hasPhotos => photoUrls != null && photoUrls!.isNotEmpty;
}
