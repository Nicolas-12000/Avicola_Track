import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/datasources/veterinary_datasource.dart';
import '../../../../data/repositories/veterinary_repository.dart';
import '../../../../data/models/veterinary_visit_model.dart';

// DataSource Provider
final veterinaryDataSourceProvider = Provider<VeterinaryDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return VeterinaryDataSource(dio);
});

// Repository Provider
final veterinaryRepositoryProvider = Provider<VeterinaryRepository>((ref) {
  final dataSource = ref.watch(veterinaryDataSourceProvider);
  return VeterinaryRepository(dataSource);
});

// State for Veterinary Visits
class VeterinaryVisitsState {
  final List<VeterinaryVisitModel> visits;
  final bool isLoading;
  final String? error;

  VeterinaryVisitsState({
    this.visits = const [],
    this.isLoading = false,
    this.error,
  });

  VeterinaryVisitsState copyWith({
    List<VeterinaryVisitModel>? visits,
    bool? isLoading,
    String? error,
  }) {
    return VeterinaryVisitsState(
      visits: visits ?? this.visits,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Getters útiles
  List<VeterinaryVisitModel> get scheduledVisits =>
      visits.where((v) => v.status == 'scheduled').toList();

  List<VeterinaryVisitModel> get completedVisits =>
      visits.where((v) => v.status == 'completed').toList();

  List<VeterinaryVisitModel> get pendingVisits =>
      visits.where((v) => v.isPending).toList();

  List<VeterinaryVisitModel> get overdueVisits =>
      visits.where((v) => v.isOverdue).toList();

  List<VeterinaryVisitModel> get emergencyVisits =>
      visits.where((v) => v.isEmergency && !v.isCompleted).toList();

  List<VeterinaryVisitModel> get todayVisits {
    final now = DateTime.now();
    return visits.where((v) {
      final visitDate = v.visitDate;
      return visitDate.year == now.year &&
          visitDate.month == now.month &&
          visitDate.day == now.day &&
          !v.isCompleted;
    }).toList();
  }

  int get totalScheduled => scheduledVisits.length;
  int get totalCompleted => completedVisits.length;
  int get totalOverdue => overdueVisits.length;
  int get totalEmergency => emergencyVisits.length;
}

// StateNotifier for Veterinary Visits
class VeterinaryVisitsNotifier extends StateNotifier<VeterinaryVisitsState> {
  final VeterinaryRepository _repository;

  VeterinaryVisitsNotifier(this._repository) : super(VeterinaryVisitsState());

  Future<void> loadVisits({int? flockId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getVisits(
      flockId: flockId,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (visits) =>
          state = state.copyWith(visits: visits, isLoading: false, error: null),
    );
  }

  Future<bool> createVisit(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createVisit(data);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (visit) {
        state = state.copyWith(
          visits: [...state.visits, visit],
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<bool> updateVisit(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.updateVisit(id, data);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (updatedVisit) {
        final updatedVisits = state.visits.map((v) {
          return v.id == id ? updatedVisit : v;
        }).toList();

        state = state.copyWith(
          visits: updatedVisits,
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<bool> deleteVisit(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.deleteVisit(id);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (_) {
        final updatedVisits = state.visits.where((v) => v.id != id).toList();
        state = state.copyWith(
          visits: updatedVisits,
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<bool> completeVisit(
    int id,
    String diagnosis,
    String treatment,
    String? notes,
    List<String>? photoUrls,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.completeVisit(
      id,
      diagnosis,
      treatment,
      notes,
      photoUrls,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (completedVisit) {
        final updatedVisits = state.visits.map((v) {
          return v.id == id ? completedVisit : v;
        }).toList();

        state = state.copyWith(
          visits: updatedVisits,
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for Veterinary Visits
final veterinaryVisitsProvider =
    StateNotifierProvider<VeterinaryVisitsNotifier, VeterinaryVisitsState>((
      ref,
    ) {
      final repository = ref.watch(veterinaryRepositoryProvider);
      return VeterinaryVisitsNotifier(repository);
    });
