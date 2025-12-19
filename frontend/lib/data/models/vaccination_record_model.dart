class VaccinationRecordModel {
  final int id;
  final int flockId;
  final String vaccineName;
  final String vaccineType; // viral, bacterial, parasitic
  final DateTime scheduledDate;
  final DateTime? appliedDate;
  final int? appliedBy; // user_id
  final String administrationRoute; // oral, injection, spray, water
  final double? dosage;
  final String? dosageUnit; // ml, mg, drops
  final int? birdCount; // cuántas aves se vacunaron
  final String status; // scheduled, applied, missed, rescheduled
  final String? notes;
  final String? batchNumber; // lote de la vacuna
  final DateTime? expirationDate;
  final DateTime createdAt;

  const VaccinationRecordModel({
    required this.id,
    required this.flockId,
    required this.vaccineName,
    required this.vaccineType,
    required this.scheduledDate,
    this.appliedDate,
    this.appliedBy,
    required this.administrationRoute,
    this.dosage,
    this.dosageUnit,
    this.birdCount,
    required this.status,
    this.notes,
    this.batchNumber,
    this.expirationDate,
    required this.createdAt,
  });

  factory VaccinationRecordModel.fromJson(Map<String, dynamic> json) {
    return VaccinationRecordModel(
      id: json['id'] as int,
      flockId: json['flock_id'] as int,
      vaccineName: json['vaccine_name'] as String,
      vaccineType: json['vaccine_type'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      appliedDate: json['applied_date'] != null
          ? DateTime.parse(json['applied_date'] as String)
          : null,
      appliedBy: json['applied_by'] as int?,
      administrationRoute: json['administration_route'] as String,
      dosage: json['dosage'] != null
          ? (json['dosage'] as num).toDouble()
          : null,
      dosageUnit: json['dosage_unit'] as String?,
      birdCount: json['bird_count'] as int?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      batchNumber: json['batch_number'] as String?,
      expirationDate: json['expiration_date'] != null
          ? DateTime.parse(json['expiration_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock_id': flockId,
      'vaccine_name': vaccineName,
      'vaccine_type': vaccineType,
      'scheduled_date': scheduledDate.toIso8601String(),
      'applied_date': appliedDate?.toIso8601String(),
      'applied_by': appliedBy,
      'administration_route': administrationRoute,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'bird_count': birdCount,
      'status': status,
      'notes': notes,
      'batch_number': batchNumber,
      'expiration_date': expirationDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  VaccinationRecordModel copyWith({
    int? id,
    int? flockId,
    String? vaccineName,
    String? vaccineType,
    DateTime? scheduledDate,
    DateTime? appliedDate,
    int? appliedBy,
    String? administrationRoute,
    double? dosage,
    String? dosageUnit,
    int? birdCount,
    String? status,
    String? notes,
    String? batchNumber,
    DateTime? expirationDate,
    DateTime? createdAt,
  }) {
    return VaccinationRecordModel(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      vaccineName: vaccineName ?? this.vaccineName,
      vaccineType: vaccineType ?? this.vaccineType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      appliedDate: appliedDate ?? this.appliedDate,
      appliedBy: appliedBy ?? this.appliedBy,
      administrationRoute: administrationRoute ?? this.administrationRoute,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      birdCount: birdCount ?? this.birdCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      batchNumber: batchNumber ?? this.batchNumber,
      expirationDate: expirationDate ?? this.expirationDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isPending => status == 'scheduled';
  bool get isApplied => status == 'applied';
  bool get isMissed => status == 'missed';
  bool get isOverdue =>
      status == 'scheduled' && scheduledDate.isBefore(DateTime.now());
  bool get isDueToday {
    final now = DateTime.now();
    return status == 'scheduled' &&
        scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  bool get isDueSoon {
    final daysUntil = scheduledDate.difference(DateTime.now()).inDays;
    return status == 'scheduled' && daysUntil >= 0 && daysUntil <= 7;
  }
}
