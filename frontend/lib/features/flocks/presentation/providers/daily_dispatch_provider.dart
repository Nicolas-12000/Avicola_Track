import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/state/list_state.dart';
import '../../../../data/models/daily_record_model.dart';
import '../../../../data/models/dispatch_record_model.dart';
import '../../data/daily_dispatch_datasource.dart';
import '../../domain/daily_dispatch_repository.dart';

// ============================================================
// TYPE ALIASES
// ============================================================

typedef DailyRecordsState = ListState<DailyRecordModel>;
typedef DispatchesState = ListState<DispatchRecordModel>;

// ============================================================
// DAILY RECORDS NOTIFIER
// ============================================================

class DailyRecordsNotifier extends StateNotifier<DailyRecordsState> {
  final DailyRecordRepository repository;

  DailyRecordsNotifier(this.repository) : super(const DailyRecordsState());

  Future<void> loadDailyRecords({required int flockId}) async {
    state = state.loading();
    final result = await repository.getDailyRecords(flockId: flockId);
    result.fold(
      (failure) => state = state.failed(failure.message),
      (records) => state = state.loaded(records),
    );
  }

  Future<bool> createDailyRecord(Map<String, dynamic> data) async {
    final result = await repository.createDailyRecord(data);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (record) {
        state = state.addItem(record);
        return true;
      },
    );
  }
}

// ============================================================
// DISPATCHES NOTIFIER
// ============================================================

class DispatchesNotifier extends StateNotifier<DispatchesState> {
  final DispatchRepository repository;

  DispatchesNotifier(this.repository) : super(const DispatchesState());

  Future<void> loadDispatches({int? flockId}) async {
    state = state.loading();
    final result = await repository.getDispatches(flockId: flockId);
    result.fold(
      (failure) => state = state.failed(failure.message),
      (dispatches) => state = state.loaded(dispatches),
    );
  }

  Future<bool> createDispatch(Map<String, dynamic> data) async {
    final result = await repository.createDispatch(data);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (dispatch) {
        state = state.addItem(dispatch);
        return true;
      },
    );
  }

  Future<bool> updateDispatch(int id, Map<String, dynamic> data) async {
    final result = await repository.updateDispatch(id, data);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (dispatch) {
        state = state.updateItem((d) => d.id == id, dispatch);
        return true;
      },
    );
  }
}

// ============================================================
// PROVIDERS
// ============================================================

final dailyRecordDataSourceProvider = Provider<DailyRecordDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DailyRecordDataSource(dio);
});

final dailyRecordRepositoryProvider = Provider<DailyRecordRepository>((ref) {
  final dataSource = ref.watch(dailyRecordDataSourceProvider);
  return DailyRecordRepository(dataSource);
});

final dailyRecordsProvider =
    StateNotifierProvider<DailyRecordsNotifier, DailyRecordsState>((ref) {
  final repository = ref.watch(dailyRecordRepositoryProvider);
  return DailyRecordsNotifier(repository);
});

final dispatchDataSourceProvider = Provider<DispatchDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return DispatchDataSource(dio);
});

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  final dataSource = ref.watch(dispatchDataSourceProvider);
  return DispatchRepository(dataSource);
});

final dispatchesProvider =
    StateNotifierProvider<DispatchesNotifier, DispatchesState>((ref) {
  final repository = ref.watch(dispatchRepositoryProvider);
  return DispatchesNotifier(repository);
});
