import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/farm_model.dart';
import '../../data/farm_datasource.dart';
import '../../domain/farm_repository.dart';
import '../../../../core/services/offline_sync_service.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/errors/offline_exceptions.dart';
import '../../../../core/providers/offline_provider.dart';

// DataSource Provider
final farmDataSourceProvider = Provider<FarmDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final offline = ref.watch(offlineSyncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return FarmDataSource(dio, offline, connectivity);
});

// Repository Provider
final farmRepositoryProvider = Provider<FarmRepository>((ref) {
  final dataSource = ref.watch(farmDataSourceProvider);
  return FarmRepository(dataSource);
});

// Farms State
class FarmsState {
  final List<FarmModel> farms;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;

  static const int pageSize = 20;

  FarmsState({
    this.farms = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  FarmsState copyWith({
    List<FarmModel>? farms,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return FarmsState(
      farms: farms ?? this.farms,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }
}

// Farms Notifier
class FarmsNotifier extends StateNotifier<FarmsState> {
  final FarmRepository _repository;
  final OfflineSyncService _offlineService;
  final ConnectivityService _connectivityService;

  FarmsNotifier(this._repository, this._offlineService, this._connectivityService)
      : super(FarmsState());

  Future<void> loadFarms({bool force = false}) async {
    // Skip if already loaded and not forced
    if (!force && state.farms.isNotEmpty && !state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasMoreData: true,
    );

    final isConnected = _connectivityService.currentState.isConnected;
    if (!isConnected && !force) {
      try {
        final cached = _offlineService.getCachedData('farms_all');
        if (cached != null && cached is List) {
          state = state.copyWith(
            farms: cached
                .map((json) => FarmModel.fromJson(Map<String, dynamic>.from(json)))
                .toList(),
            isLoading: false,
            error: null,
          );
          return;
        }
      } catch (_) {}
    }

    final result = await _repository.getFarms(page: 1);

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
    } else {
      final farms = result.farms ?? [];
      state = state.copyWith(
        farms: farms,
        isLoading: false,
        error: null,
        currentPage: 1,
        hasMoreData: farms.length >= FarmsState.pageSize,
      );
    }
  }

  Future<void> loadMoreFarms() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await _repository.getFarms(page: nextPage);

    if (result.failure != null) {
      state = state.copyWith(isLoadingMore: false, error: result.failure!.message);
    } else {
      final newFarms = result.farms ?? [];
      state = state.copyWith(
        farms: [...state.farms, ...newFarms],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMoreData: newFarms.length >= FarmsState.pageSize,
      );
    }
  }

  Future<FarmModel?> createFarm({
    required String name,
    required String location,
    int? farmManager,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.createFarm(
        name: name,
        location: location,
        farmManager: farmManager,
      );

      if (result.failure != null) {
        state = state.copyWith(isLoading: false, error: result.failure!.message);
        return null;
      }

      await loadFarms(force: true);
      return result.farm;
    } catch (e) {
      if (e is OfflineQueuedException) {
        await loadFarms();
        return null;
      }
      rethrow;
    }
  }

  Future<bool> updateFarm({
    required int id,
    String? name,
    String? location,
    int? farmManager,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.updateFarm(
        id: id,
        name: name,
        location: location,
        farmManager: farmManager,
      );

      if (result.failure != null) {
        state = state.copyWith(isLoading: false, error: result.failure!.message);
        return false;
      }

      await loadFarms(force: true);
      return true;
    } catch (e) {
      if (e is OfflineQueuedException) {
        await loadFarms();
        return true;
      }
      rethrow;
    }
  }

  Future<bool> deleteFarm(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final failure = await _repository.deleteFarm(id);

      if (failure != null) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      }

      await loadFarms(force: true);
      return true;
    } catch (e) {
      if (e is OfflineQueuedException) {
        await loadFarms();
        return true;
      }
      rethrow;
    }
  }
}

// Farms Provider
final farmsProvider = StateNotifierProvider<FarmsNotifier, FarmsState>((ref) {
  final repository = ref.watch(farmRepositoryProvider);
  final offline = ref.watch(offlineSyncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return FarmsNotifier(repository, offline, connectivity);
});
