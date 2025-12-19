import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/repositories/veterinary_repository.dart';
import '../../../../data/models/vaccination_record_model.dart';
import '../../../../data/models/medication_model.dart';
import 'veterinary_visits_provider.dart';

// ==================== VACCINATIONS ====================

class VaccinationsState {
  final List<VaccinationRecordModel> vaccinations;
  final bool isLoading;
  final String? error;

  VaccinationsState({
    this.vaccinations = const [],
    this.isLoading = false,
    this.error,
  });

  VaccinationsState copyWith({
    List<VaccinationRecordModel>? vaccinations,
    bool? isLoading,
    String? error,
  }) {
    return VaccinationsState(
      vaccinations: vaccinations ?? this.vaccinations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<VaccinationRecordModel> get pendingVaccinations =>
      vaccinations.where((v) => v.isPending).toList();

  List<VaccinationRecordModel> get appliedVaccinations =>
      vaccinations.where((v) => v.isApplied).toList();

  List<VaccinationRecordModel> get overdueVaccinations =>
      vaccinations.where((v) => v.isOverdue).toList();

  List<VaccinationRecordModel> get dueTodayVaccinations =>
      vaccinations.where((v) => v.isDueToday).toList();

  List<VaccinationRecordModel> get dueSoonVaccinations =>
      vaccinations.where((v) => v.isDueSoon).toList();

  int get totalPending => pendingVaccinations.length;
  int get totalApplied => appliedVaccinations.length;
  int get totalOverdue => overdueVaccinations.length;
}

class VaccinationsNotifier extends StateNotifier<VaccinationsState> {
  final VeterinaryRepository _repository;

  VaccinationsNotifier(this._repository) : super(VaccinationsState());

  Future<void> loadVaccinations({int? flockId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getVaccinations(
      flockId: flockId,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (vaccinations) => state = state.copyWith(
        vaccinations: vaccinations,
        isLoading: false,
        error: null,
      ),
    );
  }

  Future<bool> createVaccination(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createVaccination(data);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (vaccination) {
        state = state.copyWith(
          vaccinations: [...state.vaccinations, vaccination],
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<bool> applyVaccination(
    int id,
    int appliedBy,
    int birdCount,
    String? notes,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.applyVaccination(
      id,
      appliedBy,
      birdCount,
      notes,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (appliedVaccination) {
        final updated = state.vaccinations.map((v) {
          return v.id == id ? appliedVaccination : v;
        }).toList();

        state = state.copyWith(
          vaccinations: updated,
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<void> loadUpcomingVaccinations(int daysAhead) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getUpcomingVaccinations(daysAhead);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (vaccinations) => state = state.copyWith(
        vaccinations: vaccinations,
        isLoading: false,
        error: null,
      ),
    );
  }
}

final vaccinationsProvider =
    StateNotifierProvider<VaccinationsNotifier, VaccinationsState>((ref) {
      final repository = ref.watch(veterinaryRepositoryProvider);
      return VaccinationsNotifier(repository);
    });

// ==================== MEDICATIONS ====================

class MedicationsState {
  final List<MedicationModel> medications;
  final bool isLoading;
  final String? error;

  MedicationsState({
    this.medications = const [],
    this.isLoading = false,
    this.error,
  });

  MedicationsState copyWith({
    List<MedicationModel>? medications,
    bool? isLoading,
    String? error,
  }) {
    return MedicationsState(
      medications: medications ?? this.medications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<MedicationModel> get activeMedications =>
      medications.where((m) => m.isActive).toList();

  List<MedicationModel> get completedMedications =>
      medications.where((m) => m.isCompleted).toList();

  List<MedicationModel> get medicationsInWithdrawal =>
      medications.where((m) => m.isInWithdrawal).toList();

  List<MedicationModel> get dueTodayMedications =>
      medications.where((m) => m.isDueToday).toList();

  int get totalActive => activeMedications.length;
  int get totalInWithdrawal => medicationsInWithdrawal.length;
}

class MedicationsNotifier extends StateNotifier<MedicationsState> {
  final VeterinaryRepository _repository;

  MedicationsNotifier(this._repository) : super(MedicationsState());

  Future<void> loadMedications({int? flockId, String? status}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getMedications(
      flockId: flockId,
      status: status,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (medications) => state = state.copyWith(
        medications: medications,
        isLoading: false,
        error: null,
      ),
    );
  }

  Future<bool> createMedication(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.createMedication(data);

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, error: failure.message);
        return false;
      },
      (medication) {
        state = state.copyWith(
          medications: [...state.medications, medication],
          isLoading: false,
          error: null,
        );
        return true;
      },
    );
  }

  Future<void> loadActiveMedications() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getActiveMedications();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (medications) => state = state.copyWith(
        medications: medications,
        isLoading: false,
        error: null,
      ),
    );
  }

  Future<void> loadMedicationsInWithdrawal() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getMedicationsInWithdrawal();

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (medications) => state = state.copyWith(
        medications: medications,
        isLoading: false,
        error: null,
      ),
    );
  }
}

final medicationsProvider =
    StateNotifierProvider<MedicationsNotifier, MedicationsState>((ref) {
      final repository = ref.watch(veterinaryRepositoryProvider);
      return MedicationsNotifier(repository);
    });
