class VeterinaryVisitModel {
  final int id;
  final int flockId;
  final int veterinarianId;
  final DateTime visitDate;
  final String visitType; // routine, emergency, vaccination, treatment
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
    required this.flockId,
    required this.veterinarianId,
    required this.visitDate,
    required this.visitType,
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
      flockId: json['flock_id'] as int,
      veterinarianId: json['veterinarian_id'] as int,
      visitDate: DateTime.parse(json['visit_date'] as String),
      visitType: json['visit_type'] as String,
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
      'flock_id': flockId,
      'veterinarian_id': veterinarianId,
      'visit_date': visitDate.toIso8601String(),
      'visit_type': visitType,
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
    int? flockId,
    int? veterinarianId,
    DateTime? visitDate,
    String? visitType,
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
      flockId: flockId ?? this.flockId,
      veterinarianId: veterinarianId ?? this.veterinarianId,
      visitDate: visitDate ?? this.visitDate,
      visitType: visitType ?? this.visitType,
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
