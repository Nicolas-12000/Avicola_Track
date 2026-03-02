import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/offline_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../data/models/alarm_model.dart';
import '../../data/alarm_datasource.dart';
import '../../domain/alarm_repository.dart';

// State
class AlarmsState {
  final List<AlarmModel> alarms;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;

  static const int pageSize = 20;

  AlarmsState({
    this.alarms = const [],
    this.stats,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  AlarmsState copyWith({
    List<AlarmModel>? alarms,
    Map<String, dynamic>? stats,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return AlarmsState(
      alarms: alarms ?? this.alarms,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  // Cached computed lists (lazy, once per immutable state instance)
  List<AlarmModel>? _unresolvedCache;
  List<AlarmModel>? _resolvedCache;

  // Getters por severidad
  List<AlarmModel> get criticalAlarms =>
      unresolvedAlarms.where((a) => a.severity == 'critical').toList();

  List<AlarmModel> get highAlarms =>
      unresolvedAlarms.where((a) => a.severity == 'high').toList();

  List<AlarmModel> get mediumAlarms =>
      unresolvedAlarms.where((a) => a.severity == 'medium').toList();

  List<AlarmModel> get lowAlarms =>
      unresolvedAlarms.where((a) => a.severity == 'low').toList();

  List<AlarmModel> get unresolvedAlarms {
    _unresolvedCache ??= alarms.where((a) => !a.isResolved).toList();
    return _unresolvedCache!;
  }

  List<AlarmModel> get resolvedAlarms {
    _resolvedCache ??= alarms.where((a) => a.isResolved).toList();
    return _resolvedCache!;
  }

  int get unresolvedCount => alarms.where((a) => !a.isResolved).length;
  int get criticalCount => alarms.where((a) => a.severity == 'critical' && !a.isResolved).length;
}

// Notifier
class AlarmsNotifier extends StateNotifier<AlarmsState> {
  final AlarmRepository repository;

  int? _lastFarmId;
  String? _lastSeverity;
  bool? _lastIsResolved;

  AlarmsNotifier(this.repository) : super(AlarmsState());

  Future<void> loadAlarms({
    int? farmId,
    String? severity,
    bool? isResolved,
    bool refresh = true,
  }) async {
    _lastFarmId = farmId;
    _lastSeverity = severity;
    _lastIsResolved = isResolved;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMoreData: true,
      );
    }

    final result = await repository.getAlarms(
      farmId: farmId,
      severity: severity,
      isResolved: isResolved,
      page: 1,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (alarms) => state = state.copyWith(
        alarms: alarms,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMoreData: alarms.length >= AlarmsState.pageSize,
      ),
    );
  }

  Future<void> loadMoreAlarms() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await repository.getAlarms(
      farmId: _lastFarmId,
      severity: _lastSeverity,
      isResolved: _lastIsResolved,
      page: nextPage,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoadingMore: false, error: failure.message),
      (newAlarms) {
        final allAlarms = [...state.alarms, ...newAlarms];
        state = state.copyWith(
          alarms: allAlarms,
          isLoadingMore: false,
          currentPage: nextPage,
          hasMoreData: newAlarms.length >= AlarmsState.pageSize,
          error: null,
        );
      },
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

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      resolvedAlarm,
    ) {
      final updatedAlarms = state.alarms.map((alarm) {
        return alarm.id == id ? resolvedAlarm : alarm;
      }).toList();
      state = state.copyWith(alarms: updatedAlarms, error: null);
    });
  }

  Future<void> escalateAlarm(int id) async {
    final result = await repository.escalateAlarm(id);

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      escalatedAlarm,
    ) {
      final updatedAlarms = state.alarms.map((alarm) {
        return alarm.id == id ? escalatedAlarm : alarm;
      }).toList();
      state = state.copyWith(alarms: updatedAlarms, error: null);
    });
  }

  Future<void> deleteAlarm(int id) async {
    final result = await repository.deleteAlarm(id);

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      _,
    ) {
      final updatedAlarms = state.alarms
          .where((alarm) => alarm.id != id)
          .toList();
      state = state.copyWith(alarms: updatedAlarms, error: null);
    });
  }
}

// Providers
final alarmDataSourceProvider = Provider<AlarmDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final offline = ref.watch(offlineSyncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return AlarmDataSource(dio, offline, connectivity);
});

final alarmRepositoryProvider = Provider<AlarmRepository>((ref) {
  final dataSource = ref.watch(alarmDataSourceProvider);
  return AlarmRepository(dataSource);
});

final alarmsProvider = StateNotifierProvider<AlarmsNotifier, AlarmsState>((
  ref,
) {
  final repository = ref.watch(alarmRepositoryProvider);
  return AlarmsNotifier(repository);
});
