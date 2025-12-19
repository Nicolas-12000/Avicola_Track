class MedicationModel {
  final int id;
  final int flockId;
  final String medicationName;
  final String
  medicationType; // antibiotic, antiparasitic, vitamin, probiotic, vaccine, other
  final String? activeIngredient;
  final DateTime startDate;
  final DateTime? endDate;
  final int durationDays;
  final double dosage;
  final String dosageUnit; // ml, mg, g, ml_per_liter
  final String administrationRoute; // water, feed, injection, oral
  final String
  frequency; // once_daily, twice_daily, three_times_daily, continuous
  final int? prescribedBy; // veterinarian user_id
  final String? reason;
  final int? withdrawalPeriodDays; // período de retiro
  final DateTime? withdrawalEndDate;
  final String status; // active, completed, discontinued
  final String? notes;
  final List<DateTime>? applicationDates;
  final DateTime createdAt;

  const MedicationModel({
    required this.id,
    required this.flockId,
    required this.medicationName,
    required this.medicationType,
    this.activeIngredient,
    required this.startDate,
    this.endDate,
    required this.durationDays,
    required this.dosage,
    required this.dosageUnit,
    required this.administrationRoute,
    required this.frequency,
    this.prescribedBy,
    this.reason,
    this.withdrawalPeriodDays,
    this.withdrawalEndDate,
    required this.status,
    this.notes,
    this.applicationDates,
    required this.createdAt,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as int,
      flockId: json['flock_id'] as int,
      medicationName: json['medication_name'] as String,
      medicationType: json['medication_type'] as String,
      activeIngredient: json['active_ingredient'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      durationDays: json['duration_days'] as int,
      dosage: (json['dosage'] as num).toDouble(),
      dosageUnit: json['dosage_unit'] as String,
      administrationRoute: json['administration_route'] as String,
      frequency: json['frequency'] as String,
      prescribedBy: json['prescribed_by'] as int?,
      reason: json['reason'] as String?,
      withdrawalPeriodDays: json['withdrawal_period_days'] as int?,
      withdrawalEndDate: json['withdrawal_end_date'] != null
          ? DateTime.parse(json['withdrawal_end_date'] as String)
          : null,
      status: json['status'] as String,
      notes: json['notes'] as String?,
      applicationDates: (json['application_dates'] as List<dynamic>?)
          ?.map((e) => DateTime.parse(e as String))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flock_id': flockId,
      'medication_name': medicationName,
      'medication_type': medicationType,
      'active_ingredient': activeIngredient,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'duration_days': durationDays,
      'dosage': dosage,
      'dosage_unit': dosageUnit,
      'administration_route': administrationRoute,
      'frequency': frequency,
      'prescribed_by': prescribedBy,
      'reason': reason,
      'withdrawal_period_days': withdrawalPeriodDays,
      'withdrawal_end_date': withdrawalEndDate?.toIso8601String(),
      'status': status,
      'notes': notes,
      'application_dates': applicationDates
          ?.map((e) => e.toIso8601String())
          .toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  MedicationModel copyWith({
    int? id,
    int? flockId,
    String? medicationName,
    String? medicationType,
    String? activeIngredient,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    double? dosage,
    String? dosageUnit,
    String? administrationRoute,
    String? frequency,
    int? prescribedBy,
    String? reason,
    int? withdrawalPeriodDays,
    DateTime? withdrawalEndDate,
    String? status,
    String? notes,
    List<DateTime>? applicationDates,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      flockId: flockId ?? this.flockId,
      medicationName: medicationName ?? this.medicationName,
      medicationType: medicationType ?? this.medicationType,
      activeIngredient: activeIngredient ?? this.activeIngredient,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      administrationRoute: administrationRoute ?? this.administrationRoute,
      frequency: frequency ?? this.frequency,
      prescribedBy: prescribedBy ?? this.prescribedBy,
      reason: reason ?? this.reason,
      withdrawalPeriodDays: withdrawalPeriodDays ?? this.withdrawalPeriodDays,
      withdrawalEndDate: withdrawalEndDate ?? this.withdrawalEndDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      applicationDates: applicationDates ?? this.applicationDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get hasWithdrawalPeriod =>
      withdrawalPeriodDays != null && withdrawalPeriodDays! > 0;
  bool get isInWithdrawal {
    if (withdrawalEndDate == null) return false;
    return DateTime.now().isBefore(withdrawalEndDate!);
  }

  int get daysRemainingWithdrawal {
    if (withdrawalEndDate == null) return 0;
    return withdrawalEndDate!.difference(DateTime.now()).inDays.clamp(0, 999);
  }

  bool get isDueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : today;
    return isActive && !today.isBefore(start) && !today.isAfter(end);
  }

  int get daysRemaining {
    if (endDate == null) return 0;
    return endDate!.difference(DateTime.now()).inDays.clamp(0, 999);
  }
}
