import 'package:dio/dio.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/errors/offline_exceptions.dart';
import '../models/veterinary_visit_model.dart';
import '../models/vaccination_record_model.dart';
import '../models/medication_model.dart';
import '../models/disease_model.dart';
import '../models/biosecurity_checklist_model.dart';

class VeterinaryDataSource {
  final Dio _dio;
  final OfflineSyncService _offline;
  final ConnectivityService _connectivity;

  VeterinaryDataSource({
    required Dio dio,
    required OfflineSyncService offlineService,
    required ConnectivityService connectivityService,
  })  : _dio = dio,
        _offline = offlineService,
        _connectivity = connectivityService;

  bool get _isOnline => _connectivity.currentState.isConnected;

  Future<void> _enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    required String entity,
    int? localId,
  }) async {
    await _offline.addToQueue(
      endpoint: endpoint,
      method: method,
      data: data,
      entityType: entity,
      localId: localId,
    );
  }

  // ==================== VETERINARY VISITS ====================

  Future<List<VeterinaryVisitModel>> getVisits({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final cacheKey = 'vet_visits_${flockId ?? 'all'}_${status ?? 'all'}';
    try {
      final response = await _dio.get(
        '/api/veterinary/visits/',
        queryParameters: queryParams,
      );
      final data = (response.data as List)
          .map((json) => VeterinaryVisitModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return data;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => VeterinaryVisitModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<VeterinaryVisitModel> getVisitById(int id) async {
    final response = await _dio.get('/api/veterinary/visits/$id/');
    return VeterinaryVisitModel.fromJson(response.data);
  }

  Future<VeterinaryVisitModel> createVisit(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/veterinary/visits/', data: data);
      return VeterinaryVisitModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/visits/',
          method: 'POST',
          data: data,
          entity: 'veterinary_visit',
        );
        throw OfflineQueuedException('Visita veterinaria encolada');
      }
      rethrow;
    }
  }

  Future<VeterinaryVisitModel> updateVisit(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/api/veterinary/visits/$id/', data: data);
      return VeterinaryVisitModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/visits/$id/',
          method: 'PUT',
          data: data,
          entity: 'veterinary_visit',
          localId: id,
        );
        throw OfflineQueuedException('Actualización de visita encolada');
      }
      rethrow;
    }
  }

  Future<void> deleteVisit(int id) async {
    try {
      await _dio.delete('/api/veterinary/visits/$id/');
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/visits/$id/',
          method: 'DELETE',
          data: {'id': id},
          entity: 'veterinary_visit',
          localId: id,
        );
        throw OfflineQueuedException('Eliminación de visita encolada');
      }
      rethrow;
    }
  }

  Future<VeterinaryVisitModel> completeVisit(
    int id,
    String diagnosis,
    String treatment,
    String? notes,
    List<String>? photoUrls,
  ) async {
    final data = {
      'diagnosis': diagnosis,
      'treatment': treatment,
      'notes': notes,
      'photo_urls': photoUrls,
    };
    try {
      final response = await _dio.post(
        '/api/veterinary/visits/$id/complete/',
        data: data,
      );
      return VeterinaryVisitModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/visits/$id/complete/',
          method: 'POST',
          data: data,
          entity: 'veterinary_visit',
          localId: id,
        );
        throw OfflineQueuedException('Completar visita encolado');
      }
      rethrow;
    }
  }

  // ==================== VACCINATIONS ====================

  Future<List<VaccinationRecordModel>> getVaccinations({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final cacheKey = 'vet_vaccinations_${flockId ?? 'all'}_${status ?? 'all'}';
    try {
      final response = await _dio.get(
        '/api/veterinary/vaccinations/',
        queryParameters: queryParams,
      );
      final data = (response.data as List)
          .map((json) => VaccinationRecordModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return data;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => VaccinationRecordModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<VaccinationRecordModel> getVaccinationById(int id) async {
    final response = await _dio.get('/api/veterinary/vaccinations/$id/');
    return VaccinationRecordModel.fromJson(response.data);
  }

  Future<VaccinationRecordModel> createVaccination(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/veterinary/vaccinations/',
        data: data,
      );
      return VaccinationRecordModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/vaccinations/',
          method: 'POST',
          data: data,
          entity: 'vaccination',
        );
        throw OfflineQueuedException('Vacunación encolada');
      }
      rethrow;
    }
  }

  Future<VaccinationRecordModel> updateVaccination(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/veterinary/vaccinations/$id/',
        data: data,
      );
      return VaccinationRecordModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/vaccinations/$id/',
          method: 'PUT',
          data: data,
          entity: 'vaccination',
          localId: id,
        );
        throw OfflineQueuedException('Actualización de vacunación encolada');
      }
      rethrow;
    }
  }

  Future<void> deleteVaccination(int id) async {
    try {
      await _dio.delete('/api/veterinary/vaccinations/$id/');
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/vaccinations/$id/',
          method: 'DELETE',
          data: {'id': id},
          entity: 'vaccination',
          localId: id,
        );
        throw OfflineQueuedException('Eliminación de vacunación encolada');
      }
      rethrow;
    }
  }

  Future<VaccinationRecordModel> applyVaccination(
    int id,
    int appliedBy,
    int birdCount,
    String? notes,
  ) async {
    final payload = {
      'applied_by': appliedBy,
      'bird_count': birdCount,
      'notes': notes,
      'applied_date': DateTime.now().toIso8601String(),
    };
    try {
      final response = await _dio.post(
        '/api/veterinary/vaccinations/$id/apply/',
        data: payload,
      );
      return VaccinationRecordModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/vaccinations/$id/apply/',
          method: 'POST',
          data: payload,
          entity: 'vaccination',
          localId: id,
        );
        throw OfflineQueuedException('Aplicación de vacunación encolada');
      }
      rethrow;
    }
  }

  Future<List<VaccinationRecordModel>> getUpcomingVaccinations(
    int daysAhead,
  ) async {
    final cacheKey = 'vet_vaccinations_upcoming_$daysAhead';
    try {
      final response = await _dio.get(
        '/api/veterinary/vaccinations/upcoming/',
        queryParameters: {'days_ahead': daysAhead},
      );
      final list = (response.data as List)
          .map((json) => VaccinationRecordModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => VaccinationRecordModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  // ==================== MEDICATIONS ====================

  Future<List<MedicationModel>> getMedications({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final cacheKey = 'vet_medications_${flockId ?? 'all'}_${status ?? 'all'}';
    try {
      final response = await _dio.get(
        '/api/veterinary/medications/',
        queryParameters: queryParams,
      );
      final list = (response.data as List)
          .map((json) => MedicationModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => MedicationModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<MedicationModel> getMedicationById(int id) async {
    final response = await _dio.get('/api/veterinary/medications/$id/');
    return MedicationModel.fromJson(response.data);
  }

  Future<MedicationModel> createMedication(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/api/veterinary/medications/',
        data: data,
      );
      return MedicationModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/medications/',
          method: 'POST',
          data: data,
          entity: 'medication',
        );
        throw OfflineQueuedException('Medicación encolada');
      }
      rethrow;
    }
  }

  Future<MedicationModel> updateMedication(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/veterinary/medications/$id/',
        data: data,
      );
      return MedicationModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/medications/$id/',
          method: 'PUT',
          data: data,
          entity: 'medication',
          localId: id,
        );
        throw OfflineQueuedException('Actualización de medicación encolada');
      }
      rethrow;
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _dio.delete('/api/veterinary/medications/$id/');
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/medications/$id/',
          method: 'DELETE',
          data: {'id': id},
          entity: 'medication',
          localId: id,
        );
        throw OfflineQueuedException('Eliminación de medicación encolada');
      }
      rethrow;
    }
  }

  Future<MedicationModel> recordApplication(
    int id,
    DateTime applicationDate,
    String? notes,
  ) async {
    final payload = {
      'application_date': applicationDate.toIso8601String(),
      'notes': notes,
    };
    try {
      final response = await _dio.post(
        '/api/veterinary/medications/$id/record_application/',
        data: payload,
      );
      return MedicationModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/medications/$id/record_application/',
          method: 'POST',
          data: payload,
          entity: 'medication',
          localId: id,
        );
        throw OfflineQueuedException('Aplicación de medicación encolada');
      }
      rethrow;
    }
  }

  Future<List<MedicationModel>> getActiveMedications() async {
    try {
      final response = await _dio.get('/api/veterinary/medications/active/');
      final list = (response.data as List)
          .map((json) => MedicationModel.fromJson(json))
          .toList();
      await _offline.cacheData('vet_medications_active', response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData('vet_medications_active');
      if (cached != null && cached is List) {
        return cached
            .map((json) => MedicationModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<List<MedicationModel>> getMedicationsInWithdrawal() async {
    try {
      final response = await _dio.get('/api/veterinary/medications/withdrawal/');
      final list = (response.data as List)
          .map((json) => MedicationModel.fromJson(json))
          .toList();
      await _offline.cacheData('vet_medications_withdrawal', response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData('vet_medications_withdrawal');
      if (cached != null && cached is List) {
        return cached
            .map((json) => MedicationModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  // ==================== DISEASES ====================

  Future<List<DiseaseModel>> getDiseases({
    String? category,
    String? severity,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (severity != null) queryParams['severity'] = severity;

    final cacheKey = 'vet_diseases_${category ?? 'all'}_${severity ?? 'all'}';
    try {
      final response = await _dio.get(
        '/api/veterinary/diseases/',
        queryParameters: queryParams,
      );
      final list = (response.data as List)
          .map((json) => DiseaseModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => DiseaseModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<DiseaseModel> getDiseaseById(int id) async {
    final response = await _dio.get('/api/veterinary/diseases/$id/');
    return DiseaseModel.fromJson(response.data);
  }

  Future<List<DiseaseModel>> searchDiseases(String query) async {
    final response = await _dio.get(
      '/api/veterinary/diseases/search/',
      queryParameters: {'q': query},
    );
    return (response.data as List)
        .map((json) => DiseaseModel.fromJson(json))
        .toList();
  }

  // ==================== BIOSECURITY CHECKLISTS ====================

  Future<List<BiosecurityChecklistModel>> getChecklists({
    int? farmId,
    int? shedId,
    String? checklistType,
  }) async {
    final queryParams = <String, dynamic>{};
    if (farmId != null) queryParams['farm_id'] = farmId;
    if (shedId != null) queryParams['shed_id'] = shedId;
    if (checklistType != null) queryParams['checklist_type'] = checklistType;

    final cacheKey = 'vet_checklists_${farmId ?? 'all'}_${shedId ?? 'all'}_${checklistType ?? 'all'}';
    try {
      final response = await _dio.get(
        '/api/veterinary/biosecurity-checklists/',
        queryParameters: queryParams,
      );
      final list = (response.data as List)
          .map((json) => BiosecurityChecklistModel.fromJson(json))
          .toList();
      await _offline.cacheData(cacheKey, response.data as List<dynamic>);
      return list;
    } catch (_) {
      final cached = _offline.getCachedData(cacheKey);
      if (cached != null && cached is List) {
        return cached
            .map((json) => BiosecurityChecklistModel.fromJson(json))
            .toList();
      }
      rethrow;
    }
  }

  Future<BiosecurityChecklistModel> getChecklistById(int id) async {
    final response = await _dio.get(
      '/api/veterinary/biosecurity-checklists/$id/',
    );
    return BiosecurityChecklistModel.fromJson(response.data);
  }

  Future<BiosecurityChecklistModel> createChecklist(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/api/veterinary/biosecurity-checklists/',
        data: data,
      );
      return BiosecurityChecklistModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/biosecurity-checklists/',
          method: 'POST',
          data: data,
          entity: 'biosecurity_checklist',
        );
        throw OfflineQueuedException('Lista de bioseguridad encolada');
      }
      rethrow;
    }
  }

  Future<BiosecurityChecklistModel> updateChecklist(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/api/veterinary/biosecurity-checklists/$id/',
        data: data,
      );
      return BiosecurityChecklistModel.fromJson(response.data);
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/biosecurity-checklists/$id/',
          method: 'PUT',
          data: data,
          entity: 'biosecurity_checklist',
          localId: id,
        );
        throw OfflineQueuedException('Actualización de lista encolada');
      }
      rethrow;
    }
  }

  Future<void> deleteChecklist(int id) async {
    try {
      await _dio.delete('/api/veterinary/biosecurity-checklists/$id/');
    } catch (_) {
      if (!_isOnline) {
        await _enqueue(
          endpoint: '/api/veterinary/biosecurity-checklists/$id/',
          method: 'DELETE',
          data: {'id': id},
          entity: 'biosecurity_checklist',
          localId: id,
        );
        throw OfflineQueuedException('Eliminación de lista encolada');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getComplianceStats(
    int farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{'farm_id': farmId};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final response = await _dio.get(
      '/api/veterinary/biosecurity-checklists/compliance_stats/',
      queryParameters: queryParams,
    );
    return response.data;
  }
}
