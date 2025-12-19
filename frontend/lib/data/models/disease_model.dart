class DiseaseModel {
  final int id;
  final String name;
  final String scientificName;
  final String
  category; // viral, bacterial, parasitic, fungal, nutritional, other
  final String severity; // low, medium, high, critical
  final String transmissionMode; // direct, airborne, water, vector, vertical
  final List<String> symptoms;
  final List<String>
  affectedSystems; // respiratory, digestive, nervous, reproductive, integumentary
  final String? diagnosis;
  final List<String> treatments;
  final List<String> preventionMeasures;
  final String? vaccineAvailable;
  final int? incubationPeriodDays;
  final double? mortalityRate; // 0-100
  final double? morbidityRate; // 0-100
  final String? imageUrl;
  final String? description;
  final bool isNotifiable; // enfermedad de reporte obligatorio
  final DateTime createdAt;

  const DiseaseModel({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.category,
    required this.severity,
    required this.transmissionMode,
    required this.symptoms,
    required this.affectedSystems,
    this.diagnosis,
    required this.treatments,
    required this.preventionMeasures,
    this.vaccineAvailable,
    this.incubationPeriodDays,
    this.mortalityRate,
    this.morbidityRate,
    this.imageUrl,
    this.description,
    required this.isNotifiable,
    required this.createdAt,
  });

  factory DiseaseModel.fromJson(Map<String, dynamic> json) {
    return DiseaseModel(
      id: json['id'] as int,
      name: json['name'] as String,
      scientificName: json['scientific_name'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      transmissionMode: json['transmission_mode'] as String,
      symptoms: (json['symptoms'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      affectedSystems: (json['affected_systems'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      diagnosis: json['diagnosis'] as String?,
      treatments: (json['treatments'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      preventionMeasures: (json['prevention_measures'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      vaccineAvailable: json['vaccine_available'] as String?,
      incubationPeriodDays: json['incubation_period_days'] as int?,
      mortalityRate: json['mortality_rate'] != null
          ? (json['mortality_rate'] as num).toDouble()
          : null,
      morbidityRate: json['morbidity_rate'] != null
          ? (json['morbidity_rate'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      isNotifiable: json['is_notifiable'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'category': category,
      'severity': severity,
      'transmission_mode': transmissionMode,
      'symptoms': symptoms,
      'affected_systems': affectedSystems,
      'diagnosis': diagnosis,
      'treatments': treatments,
      'prevention_measures': preventionMeasures,
      'vaccine_available': vaccineAvailable,
      'incubation_period_days': incubationPeriodDays,
      'mortality_rate': mortalityRate,
      'morbidity_rate': morbidityRate,
      'image_url': imageUrl,
      'description': description,
      'is_notifiable': isNotifiable,
      'created_at': createdAt.toIso8601String(),
    };
  }

  DiseaseModel copyWith({
    int? id,
    String? name,
    String? scientificName,
    String? category,
    String? severity,
    String? transmissionMode,
    List<String>? symptoms,
    List<String>? affectedSystems,
    String? diagnosis,
    List<String>? treatments,
    List<String>? preventionMeasures,
    String? vaccineAvailable,
    int? incubationPeriodDays,
    double? mortalityRate,
    double? morbidityRate,
    String? imageUrl,
    String? description,
    bool? isNotifiable,
    DateTime? createdAt,
  }) {
    return DiseaseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      transmissionMode: transmissionMode ?? this.transmissionMode,
      symptoms: symptoms ?? this.symptoms,
      affectedSystems: affectedSystems ?? this.affectedSystems,
      diagnosis: diagnosis ?? this.diagnosis,
      treatments: treatments ?? this.treatments,
      preventionMeasures: preventionMeasures ?? this.preventionMeasures,
      vaccineAvailable: vaccineAvailable ?? this.vaccineAvailable,
      incubationPeriodDays: incubationPeriodDays ?? this.incubationPeriodDays,
      mortalityRate: mortalityRate ?? this.mortalityRate,
      morbidityRate: morbidityRate ?? this.morbidityRate,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isNotifiable: isNotifiable ?? this.isNotifiable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isCritical => severity == 'critical';
  bool get isHighSeverity => severity == 'high' || severity == 'critical';
  bool get hasVaccine =>
      vaccineAvailable != null && vaccineAvailable!.isNotEmpty;
  bool get isHighMortality => mortalityRate != null && mortalityRate! > 20;
  String get categoryEmoji {
    switch (category) {
      case 'viral':
        return '🦠';
      case 'bacterial':
        return '🔬';
      case 'parasitic':
        return '🪱';
      case 'fungal':
        return '🍄';
      case 'nutritional':
        return '🥗';
      default:
        return '⚕️';
    }
  }
}
