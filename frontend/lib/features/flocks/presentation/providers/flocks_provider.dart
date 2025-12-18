import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/flock_model.dart';
import '../../../../data/models/weight_record_model.dart';
import '../../../../data/models/mortality_record_model.dart';
import '../../data/flock_datasource.dart';
import '../../domain/flock_repository.dart';

// State
class FlocksState {
  final List<FlockModel> flocks;
  final List<WeightRecordModel> weightRecords;
  final List<MortalityRecordModel> mortalityRecords;
  final bool isLoading;
  final String? error;

  FlocksState({
    this.flocks = const [],
    this.weightRecords = const [],
    this.mortalityRecords = const [],
    this.isLoading = false,
    this.error,
  });

  FlocksState copyWith({
    List<FlockModel>? flocks,
    List<WeightRecordModel>? weightRecords,
    List<MortalityRecordModel>? mortalityRecords,
    bool? isLoading,
    String? error,
  }) {
    return FlocksState(
      flocks: flocks ?? this.flocks,
      weightRecords: weightRecords ?? this.weightRecords,
      mortalityRecords: mortalityRecords ?? this.mortalityRecords,
      isLoading: isLoading ?? this.isLoading,
      error: error,
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

  FlocksNotifier(this.repository) : super(FlocksState());

  Future<void> loadFlocks({int? farmId, int? shedId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getFlocks(
      farmId: farmId,
      shedId: shedId,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (flocks) =>
          state = state.copyWith(flocks: flocks, isLoading: false, error: null),
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
  }) async {
    final result = await repository.createFlock(
      shedId: shedId,
      breed: breed,
      initialQuantity: initialQuantity,
      gender: gender,
      arrivalDate: arrivalDate,
      initialWeight: initialWeight,
      supplier: supplier,
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

  // Weight Records
  Future<void> loadWeightRecords(int flockId) async {
    final result = await repository.getWeightRecords(flockId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (records) => state = state.copyWith(weightRecords: records, error: null),
    );
  }

  Future<void> createWeightRecord({
    required int flockId,
    required double averageWeight,
    required int sampleSize,
    required DateTime recordDate,
    String? notes,
  }) async {
    final result = await repository.createWeightRecord(
      flockId: flockId,
      averageWeight: averageWeight,
      sampleSize: sampleSize,
      recordDate: recordDate,
      notes: notes,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      record,
    ) {
      state = state.copyWith(
        weightRecords: [...state.weightRecords, record],
        error: null,
      );
    });
  }

  // Mortality Records
  Future<void> loadMortalityRecords(int flockId) async {
    final result = await repository.getMortalityRecords(flockId);

    result.fold(
      (failure) => state = state.copyWith(error: failure.message),
      (records) =>
          state = state.copyWith(mortalityRecords: records, error: null),
    );
  }

  Future<void> createMortalityRecord({
    required int flockId,
    required int quantity,
    required String cause,
    required DateTime recordDate,
    double? temperature,
    String? notes,
  }) async {
    final result = await repository.createMortalityRecord(
      flockId: flockId,
      quantity: quantity,
      cause: cause,
      recordDate: recordDate,
      temperature: temperature,
      notes: notes,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      record,
    ) {
      state = state.copyWith(
        mortalityRecords: [...state.mortalityRecords, record],
        error: null,
      );
    });
  }
}

// Providers
final flockDataSourceProvider = Provider<FlockDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return FlockDataSource(dio);
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
