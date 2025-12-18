import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/alarm_model.dart';
import '../../data/alarm_datasource.dart';
import '../../domain/alarm_repository.dart';

// State
class AlarmsState {
  final List<AlarmModel> alarms;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  AlarmsState({
    this.alarms = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  AlarmsState copyWith({
    List<AlarmModel>? alarms,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return AlarmsState(
      alarms: alarms ?? this.alarms,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Getters por severidad
  List<AlarmModel> get criticalAlarms =>
      alarms.where((a) => a.severity == 'critical' && !a.isResolved).toList();

  List<AlarmModel> get highAlarms =>
      alarms.where((a) => a.severity == 'high' && !a.isResolved).toList();

  List<AlarmModel> get mediumAlarms =>
      alarms.where((a) => a.severity == 'medium' && !a.isResolved).toList();

  List<AlarmModel> get lowAlarms =>
      alarms.where((a) => a.severity == 'low' && !a.isResolved).toList();

  List<AlarmModel> get unresolvedAlarms =>
      alarms.where((a) => !a.isResolved).toList();

  List<AlarmModel> get resolvedAlarms =>
      alarms.where((a) => a.isResolved).toList();

  int get unresolvedCount => unresolvedAlarms.length;
  int get criticalCount => criticalAlarms.length;
}

// Notifier
class AlarmsNotifier extends StateNotifier<AlarmsState> {
  final AlarmRepository repository;

  AlarmsNotifier(this.repository) : super(AlarmsState());

  Future<void> loadAlarms({
    int? farmId,
    String? severity,
    bool? isResolved,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getAlarms(
      farmId: farmId,
      severity: severity,
      isResolved: isResolved,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (alarms) =>
          state = state.copyWith(alarms: alarms, isLoading: false, error: null),
    );
  }

  Future<void> loadAlarmStats({int? farmId}) async {
    final result = await repository.getAlarmStats(farmId: farmId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (stats) => state = state.copyWith(stats: stats),
    );
  }

  // Note: createAlarm not available in datasource

  Future<void> resolveAlarm({
    required int id,
    required String resolutionNotes,
  }) async {
    final result = await repository.resolveAlarm(
      id: id,
      resolutionNotes: resolutionNotes,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (resolvedAlarm) {
        final updatedAlarms = state.alarms.map((alarm) {
          return alarm.id == id ? resolvedAlarm : alarm;
        }).toList();
        state = state.copyWith(alarms: updatedAlarms, error: null);
      },
    );
  }

  Future<void> escalateAlarm(int id) async {
    final result = await repository.escalateAlarm(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (escalatedAlarm) {
        final updatedAlarms = state.alarms.map((alarm) {
          return alarm.id == id ? escalatedAlarm : alarm;
        }).toList();
        state = state.copyWith(alarms: updatedAlarms, error: null);
      },
    );
  }

  Future<void> deleteAlarm(int id) async {
    final result = await repository.deleteAlarm(id);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (_) {
        final updatedAlarms = state.alarms.where((alarm) => alarm.id != id).toList();
        state = state.copyWith(alarms: updatedAlarms, error: null);
      },
    );
  }
}

// Providers
final alarmDataSourceProvider = Provider<AlarmDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AlarmDataSource(dio);
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final dataSource = ref.watch(alarmDataSourceProvider);
  return AlarmRepository(dataSource);
});

final alarmsProvider =
    StateNotifierProvider<AlarmsNotifier, AlarmsState>((ref) {
  final repository = ref.watch(alarmRepositoryProvider);
  return AlarmsNotifier(repository);
});
