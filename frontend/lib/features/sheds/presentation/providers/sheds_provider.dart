import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/shed_model.dart';
import '../../data/shed_datasource.dart';
import '../../domain/shed_repository.dart';

// State
class ShedsState {
  final List<ShedModel> sheds;
  final bool isLoading;
  final String? error;

  ShedsState({this.sheds = const [], this.isLoading = false, this.error});

  ShedsState copyWith({
    List<ShedModel>? sheds,
    bool? isLoading,
    String? error,
  }) {
    return ShedsState(
      sheds: sheds ?? this.sheds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class ShedsNotifier extends StateNotifier<ShedsState> {
  final ShedRepository repository;

  ShedsNotifier(this.repository) : super(ShedsState());

  Future<void> loadSheds({int? farmId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getSheds(farmId: farmId);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (sheds) =>
          state = state.copyWith(sheds: sheds, isLoading: false, error: null),
    );
  }

  Future<void> createShed({
    required String name,
    required int farmId,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    final result = await repository.createShed(
      name: name,
      farmId: farmId,
      capacity: capacity,
      assignedWorkerId: assignedWorkerId,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      shed,
    ) {
      state = state.copyWith(sheds: [...state.sheds, shed], error: null);
    });
  }

  Future<void> updateShed({
    required int id,
    required String name,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    final result = await repository.updateShed(
      id: id,
      name: name,
      capacity: capacity,
      assignedWorkerId: assignedWorkerId,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      updatedShed,
    ) {
      final updatedSheds = state.sheds.map((shed) {
        return shed.id == id ? updatedShed : shed;
      }).toList();
      state = state.copyWith(sheds: updatedSheds, error: null);
    });
  }

  Future<void> deleteShed(int id) async {
    final result = await repository.deleteShed(id);

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      _,
    ) {
      final updatedSheds = state.sheds.where((shed) => shed.id != id).toList();
      state = state.copyWith(sheds: updatedSheds, error: null);
    });
  }
}

// Providers
final shedDataSourceProvider = Provider<ShedDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ShedDataSource(dio);
});

final shedRepositoryProvider = Provider<ShedRepository>((ref) {
  final dataSource = ref.watch(shedDataSourceProvider);
  return ShedRepository(dataSource);
});

final shedsProvider = StateNotifierProvider<ShedsNotifier, ShedsState>((ref) {
  final repository = ref.watch(shedRepositoryProvider);
  return ShedsNotifier(repository);
});
