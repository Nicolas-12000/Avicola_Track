import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/farm_model.dart';
import '../../data/farm_datasource.dart';
import '../../domain/farm_repository.dart';

// DataSource Provider
final farmDataSourceProvider = Provider<FarmDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FarmDataSource(dio);
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
  final String? error;

  FarmsState({this.farms = const [], this.isLoading = false, this.error});

  FarmsState copyWith({
    List<FarmModel>? farms,
    bool? isLoading,
    String? error,
  }) {
    return FarmsState(
      farms: farms ?? this.farms,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Farms Notifier
class FarmsNotifier extends StateNotifier<FarmsState> {
  final FarmRepository _repository;

  FarmsNotifier(this._repository) : super(FarmsState());

  Future<void> loadFarms() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getFarms();

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
    } else {
      state = state.copyWith(
        farms: result.farms ?? [],
        isLoading: false,
        error: null,
      );
    }
  }

  Future<FarmModel?> createFarm({
    required String name,
    required String location,
    int? farmManager,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createFarm(
      name: name,
      location: location,
      farmManager: farmManager,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, error: result.failure!.message);
      return null;
    }

    // Recargar lista y devolver la granja creada
    await loadFarms();
    return result.farm;
  }

  Future<bool> updateFarm({
    required int id,
    String? name,
    String? location,
    int? farmManager,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

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

    // Recargar lista
    await loadFarms();
    return true;
  }

  Future<bool> deleteFarm(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    final failure = await _repository.deleteFarm(id);

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure.message);
      return false;
    }

    // Recargar lista
    await loadFarms();
    return true;
  }
}

// Farms Provider
final farmsProvider = StateNotifierProvider<FarmsNotifier, FarmsState>((ref) {
  final repository = ref.watch(farmRepositoryProvider);
  return FarmsNotifier(repository);
});
