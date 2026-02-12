import '../../core/utils/json_parsers.dart';

class DailyRecordModel {
  final int id;
  final int flockId;
  final DateTime date;
  final int weekNumber;
  final int dayNumber;

  // Mortalidad
  final int mortalityMale;
  final int mortalityFemale;

  // Salida a proceso
  final int processOutputMale;
  final int processOutputFemale;

  // Saldo
  final int balanceMale;
  final int balanceFemale;

  // Consumo alimento
  final double feedConsumedKgMale;
  final double feedConsumedKgFemale;
  final double feedPerBirdGrMale;
  final double feedPerBirdGrFemale;
  final double accumulatedFeedPerBirdGrMale;
  final double accumulatedFeedPerBirdGrFemale;

  // Peso
  final double? weightMale;
  final double? weightFemale;

  // Ganancia peso
  final double? weeklyWeightGainMale;
  final double? weeklyWeightGainFemale;
  final double? dailyAvgWeightGainMale;
  final double? dailyAvgWeightGainFemale;

  // Conversión alimenticia
  final double? feedConversionMale;
  final double? feedConversionFemale;

  // Otros
  final double? temperature;
  final String? notes;
  final int? recordedBy;
  final String? clientId;
  final String? syncStatus;
  final DateTime? createdAt;

  DailyRecordModel({
    required this.id,
    required this.flockId,
    required this.date,
    required this.weekNumber,
    required this.dayNumber,
    this.mortalityMale = 0,
    this.mortalityFemale = 0,
    this.processOutputMale = 0,
    this.processOutputFemale = 0,
    this.balanceMale = 0,
    this.balanceFemale = 0,
    this.feedConsumedKgMale = 0,
    this.feedConsumedKgFemale = 0,
    this.feedPerBirdGrMale = 0,
    this.feedPerBirdGrFemale = 0,
    this.accumulatedFeedPerBirdGrMale = 0,
    this.accumulatedFeedPerBirdGrFemale = 0,
    this.weightMale,
    this.weightFemale,
    this.weeklyWeightGainMale,
    this.weeklyWeightGainFemale,
    this.dailyAvgWeightGainMale,
    this.dailyAvgWeightGainFemale,
    this.feedConversionMale,
    this.feedConversionFemale,
    this.temperature,
    this.notes,
    this.recordedBy,
    this.clientId,
    this.syncStatus,
    this.createdAt,
  });

  // Totales calculados
  int get totalMortality => mortalityMale + mortalityFemale;
  int get totalProcessOutput => processOutputMale + processOutputFemale;
  int get totalBalance => balanceMale + balanceFemale;
  double get totalFeedConsumedKg => feedConsumedKgMale + feedConsumedKgFemale;

  double? get avgWeight {
    if (weightMale != null && weightFemale != null) {
      return (weightMale! + weightFemale!) / 2;
    }
    return weightMale ?? weightFemale;
  }

  double? get avgFeedConversion {
    if (feedConversionMale != null && feedConversionFemale != null) {
      return (feedConversionMale! + feedConversionFemale!) / 2;
    }
    return feedConversionMale ?? feedConversionFemale;
  }

  factory DailyRecordModel.fromJson(Map<String, dynamic> json) {
    return DailyRecordModel(
      id: json['id'] as int,
      flockId: json['flock'] as int,
      date: DateTime.parse(json['date'] as String),
      weekNumber: json['week_number'] as int? ?? 0,
      dayNumber: json['day_number'] as int? ?? 0,
      mortalityMale: json['mortality_male'] as int? ?? 0,
      mortalityFemale: json['mortality_female'] as int? ?? 0,
      processOutputMale: json['process_output_male'] as int? ?? 0,
      processOutputFemale: json['process_output_female'] as int? ?? 0,
      balanceMale: json['balance_male'] as int? ?? 0,
      balanceFemale: json['balance_female'] as int? ?? 0,
      feedConsumedKgMale: JsonParsers.toDouble(json['feed_consumed_kg_male']),
      feedConsumedKgFemale: JsonParsers.toDouble(json['feed_consumed_kg_female']),
      feedPerBirdGrMale: JsonParsers.toDouble(json['feed_per_bird_gr_male']),
      feedPerBirdGrFemale: JsonParsers.toDouble(json['feed_per_bird_gr_female']),
      accumulatedFeedPerBirdGrMale: JsonParsers.toDouble(json['accumulated_feed_per_bird_gr_male']),
      accumulatedFeedPerBirdGrFemale: JsonParsers.toDouble(json['accumulated_feed_per_bird_gr_female']),
      weightMale: JsonParsers.toDoubleNullable(json['weight_male']),
      weightFemale: JsonParsers.toDoubleNullable(json['weight_female']),
      weeklyWeightGainMale: JsonParsers.toDoubleNullable(json['weekly_weight_gain_male']),
      weeklyWeightGainFemale: JsonParsers.toDoubleNullable(json['weekly_weight_gain_female']),
      dailyAvgWeightGainMale: JsonParsers.toDoubleNullable(json['daily_avg_weight_gain_male']),
      dailyAvgWeightGainFemale: JsonParsers.toDoubleNullable(json['daily_avg_weight_gain_female']),
      feedConversionMale: JsonParsers.toDoubleNullable(json['feed_conversion_male']),
      feedConversionFemale: JsonParsers.toDoubleNullable(json['feed_conversion_female']),
      temperature: JsonParsers.toDoubleNullable(json['temperature']),
      notes: json['notes'] as String?,
      recordedBy: json['recorded_by'] as int?,
      clientId: json['client_id'] as String?,
      syncStatus: json['sync_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flock': flockId,
      'date': JsonParsers.toDateString(date),
      'mortality_male': mortalityMale,
      'mortality_female': mortalityFemale,
      'process_output_male': processOutputMale,
      'process_output_female': processOutputFemale,
      'balance_male': balanceMale,
      'balance_female': balanceFemale,
      'feed_consumed_kg_male': feedConsumedKgMale,
      'feed_consumed_kg_female': feedConsumedKgFemale,
      'accumulated_feed_per_bird_gr_male': accumulatedFeedPerBirdGrMale,
      'accumulated_feed_per_bird_gr_female': accumulatedFeedPerBirdGrFemale,
      'weight_male': weightMale,
      'weight_female': weightFemale,
      'weekly_weight_gain_male': weeklyWeightGainMale,
      'weekly_weight_gain_female': weeklyWeightGainFemale,
      'daily_avg_weight_gain_male': dailyAvgWeightGainMale,
      'daily_avg_weight_gain_female': dailyAvgWeightGainFemale,
      'temperature': temperature,
      'notes': notes ?? '',
      'client_id': clientId,
    };
  }

  /// Formato para envío simplificado al endpoint bulk-sync
  Map<String, dynamic> toBulkSyncJson() {
    return {
      'flock_id': flockId,
      'date': JsonParsers.toDateString(date),
      'mortality_male': mortalityMale,
      'mortality_female': mortalityFemale,
      'process_output_male': processOutputMale,
      'process_output_female': processOutputFemale,
      'feed_consumed_kg_male': feedConsumedKgMale,
      'feed_consumed_kg_female': feedConsumedKgFemale,
      'weight_male': weightMale,
      'weight_female': weightFemale,
      'temperature': temperature,
      'notes': notes ?? '',
      'client_id': clientId,
    };
  }
}
