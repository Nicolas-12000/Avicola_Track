import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/offline_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../data/models/flock_model.dart';
import '../../data/flock_datasource.dart';
import '../../domain/flock_repository.dart';

// State
class FlocksState {
  final List<FlockModel> flocks;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;

  static const int pageSize = 20;

  FlocksState({
    this.flocks = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  FlocksState copyWith({
    List<FlockModel>? flocks,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return FlocksState(
      flocks: flocks ?? this.flocks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  List<FlockModel> get activeFlocks =>
      flocks.where((f) => f.status == 'Active').toList();
  List<FlockModel> get soldFlocks =>
      flocks.where((f) => f.status == 'Sold').toList();
  List<FlockModel> get terminatedFlocks =>
      flocks.where((f) => f.status == 'Terminated').toList();
}

// Notifier
class FlocksNotifier extends StateNotifier<FlocksState> {
  final FlockRepository repository;

  int? _lastFarmId;
  int? _lastShedId;
  String? _lastStatus;

  FlocksNotifier(this.repository) : super(FlocksState());

  Future<void> loadFlocks({int? farmId, int? shedId, String? status, bool refresh = true}) async {
    _lastFarmId = farmId;
    _lastShedId = shedId;
    _lastStatus = status;

    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMoreData: true,
      );
    }

    final result = await repository.getFlocks(
      farmId: farmId,
      shedId: shedId,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (flocks) => state = state.copyWith(
        flocks: flocks,
        isLoading: false,
        error: null,
        hasMoreData: flocks.length >= FlocksState.pageSize,
      ),
    );
  }

  Future<void> loadMoreFlocks() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);

    final result = await repository.getFlocks(
      farmId: _lastFarmId,
      shedId: _lastShedId,
      status: _lastStatus,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoadingMore: false, error: failure.message),
      (newFlocks) {
        final allFlocks = [...state.flocks, ...newFlocks];
        state = state.copyWith(
          flocks: allFlocks,
          isLoadingMore: false,
          currentPage: state.currentPage + 1,
          hasMoreData: newFlocks.length >= FlocksState.pageSize,
          error: null,
        );
      },
    );
  }

  Future<void> createFlock({
    required int shedId,
    required String breed,
    required int initialQuantity,
    required String gender,
    required DateTime arrivalDate,
    double? initialWeight,
    String? supplier,
    String productionStage = 'GROW_OUT',
  }) async {
    final result = await repository.createFlock(
      shedId: shedId,
      breed: breed,
      initialQuantity: initialQuantity,
      gender: gender,
      arrivalDate: arrivalDate,
      initialWeight: initialWeight,
      supplier: supplier,
      productionStage: productionStage,
    );

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (flock) =>
          state = state.copyWith(flocks: [...state.flocks, flock], error: null),
    );
  }

  Future<void> updateFlock({
    required int id,
    int? currentQuantity,
    double? currentWeight,
    String? status,
    DateTime? saleDate,
  }) async {
    final result = await repository.updateFlock(
      id: id,
      currentQuantity: currentQuantity,
      currentWeight: currentWeight,
      status: status,
      saleDate: saleDate,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      updatedFlock,
    ) {
      final updatedFlocks = state.flocks.map((f) {
        return f.id == id ? updatedFlock : f;
      }).toList();
      state = state.copyWith(flocks: updatedFlocks, error: null);
    });
  }

  Future<void> deleteFlock(int id) async {
    final result = await repository.deleteFlock(id);

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      _,
    ) {
      final updatedFlocks = state.flocks.where((f) => f.id != id).toList();
      state = state.copyWith(flocks: updatedFlocks, error: null);
    });
  }
}

// Providers
final flockDataSourceProvider = Provider<FlockDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  final offline = ref.watch(offlineSyncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return FlockDataSource(dio, offline, connectivity);
});

final flockRepositoryProvider = Provider<FlockRepository>((ref) {
  final dataSource = ref.watch(flockDataSourceProvider);
  return FlockRepository(dataSource);
});

final flocksProvider = StateNotifierProvider<FlocksNotifier, FlocksState>((
  ref,
) {
  final repository = ref.watch(flockRepositoryProvider);
  return FlocksNotifier(repository);
});
