import 'package:dio/dio.dart';
import '../models/veterinary_visit_model.dart';
import '../models/vaccination_record_model.dart';
import '../models/medication_model.dart';
import '../models/disease_model.dart';
import '../models/biosecurity_checklist_model.dart';

class VeterinaryDataSource {
  final Dio _dio;

  VeterinaryDataSource(this._dio);

  // ==================== VETERINARY VISITS ====================

  Future<List<VeterinaryVisitModel>> getVisits({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/api/veterinary/visits/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => VeterinaryVisitModel.fromJson(json))
        .toList();
  }

  Future<VeterinaryVisitModel> getVisitById(int id) async {
    final response = await _dio.get('/api/veterinary/visits/$id/');
    return VeterinaryVisitModel.fromJson(response.data);
  }

  Future<VeterinaryVisitModel> createVisit(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/veterinary/visits/', data: data);
    return VeterinaryVisitModel.fromJson(response.data);
  }

  Future<VeterinaryVisitModel> updateVisit(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/api/veterinary/visits/$id/', data: data);
    return VeterinaryVisitModel.fromJson(response.data);
  }

  Future<void> deleteVisit(int id) async {
    await _dio.delete('/api/veterinary/visits/$id/');
  }

  Future<VeterinaryVisitModel> completeVisit(
    int id,
    String diagnosis,
    String treatment,
    String? notes,
    List<String>? photoUrls,
  ) async {
    final response = await _dio.post(
      '/api/veterinary/visits/$id/complete/',
      data: {
        'diagnosis': diagnosis,
        'treatment': treatment,
        'notes': notes,
        'photo_urls': photoUrls,
      },
    );
    return VeterinaryVisitModel.fromJson(response.data);
  }

  // ==================== VACCINATIONS ====================

  Future<List<VaccinationRecordModel>> getVaccinations({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/api/veterinary/vaccinations/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => VaccinationRecordModel.fromJson(json))
        .toList();
  }

  Future<VaccinationRecordModel> getVaccinationById(int id) async {
    final response = await _dio.get('/api/veterinary/vaccinations/$id/');
    return VaccinationRecordModel.fromJson(response.data);
  }

  Future<VaccinationRecordModel> createVaccination(
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      '/api/veterinary/vaccinations/',
      data: data,
    );
    return VaccinationRecordModel.fromJson(response.data);
  }

  Future<VaccinationRecordModel> updateVaccination(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '/api/veterinary/vaccinations/$id/',
      data: data,
    );
    return VaccinationRecordModel.fromJson(response.data);
  }

  Future<void> deleteVaccination(int id) async {
    await _dio.delete('/api/veterinary/vaccinations/$id/');
  }

  Future<VaccinationRecordModel> applyVaccination(
    int id,
    int appliedBy,
    int birdCount,
    String? notes,
  ) async {
    final response = await _dio.post(
      '/api/veterinary/vaccinations/$id/apply/',
      data: {
        'applied_by': appliedBy,
        'bird_count': birdCount,
        'notes': notes,
        'applied_date': DateTime.now().toIso8601String(),
      },
    );
    return VaccinationRecordModel.fromJson(response.data);
  }

  Future<List<VaccinationRecordModel>> getUpcomingVaccinations(
    int daysAhead,
  ) async {
    final response = await _dio.get(
      '/api/veterinary/vaccinations/upcoming/',
      queryParameters: {'days_ahead': daysAhead},
    );
    return (response.data as List)
        .map((json) => VaccinationRecordModel.fromJson(json))
        .toList();
  }

  // ==================== MEDICATIONS ====================

  Future<List<MedicationModel>> getMedications({
    int? flockId,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (flockId != null) queryParams['flock_id'] = flockId;
    if (status != null) queryParams['status'] = status;

    final response = await _dio.get(
      '/api/veterinary/medications/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => MedicationModel.fromJson(json))
        .toList();
  }

  Future<MedicationModel> getMedicationById(int id) async {
    final response = await _dio.get('/api/veterinary/medications/$id/');
    return MedicationModel.fromJson(response.data);
  }

  Future<MedicationModel> createMedication(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/veterinary/medications/',
      data: data,
    );
    return MedicationModel.fromJson(response.data);
  }

  Future<MedicationModel> updateMedication(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '/api/veterinary/medications/$id/',
      data: data,
    );
    return MedicationModel.fromJson(response.data);
  }

  Future<void> deleteMedication(int id) async {
    await _dio.delete('/api/veterinary/medications/$id/');
  }

  Future<MedicationModel> recordApplication(
    int id,
    DateTime applicationDate,
    String? notes,
  ) async {
    final response = await _dio.post(
      '/api/veterinary/medications/$id/record_application/',
      data: {
        'application_date': applicationDate.toIso8601String(),
        'notes': notes,
      },
    );
    return MedicationModel.fromJson(response.data);
  }

  Future<List<MedicationModel>> getActiveMedications() async {
    final response = await _dio.get('/api/veterinary/medications/active/');
    return (response.data as List)
        .map((json) => MedicationModel.fromJson(json))
        .toList();
  }

  Future<List<MedicationModel>> getMedicationsInWithdrawal() async {
    final response = await _dio.get('/api/veterinary/medications/withdrawal/');
    return (response.data as List)
        .map((json) => MedicationModel.fromJson(json))
        .toList();
  }

  // ==================== DISEASES ====================

  Future<List<DiseaseModel>> getDiseases({
    String? category,
    String? severity,
  }) async {
    final queryParams = <String, dynamic>{};
    if (category != null) queryParams['category'] = category;
    if (severity != null) queryParams['severity'] = severity;

    final response = await _dio.get(
      '/api/veterinary/diseases/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => DiseaseModel.fromJson(json))
        .toList();
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

    final response = await _dio.get(
      '/api/veterinary/biosecurity-checklists/',
      queryParameters: queryParams,
    );
    return (response.data as List)
        .map((json) => BiosecurityChecklistModel.fromJson(json))
        .toList();
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
    final response = await _dio.post(
      '/api/veterinary/biosecurity-checklists/',
      data: data,
    );
    return BiosecurityChecklistModel.fromJson(response.data);
  }

  Future<BiosecurityChecklistModel> updateChecklist(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put(
      '/api/veterinary/biosecurity-checklists/$id/',
      data: data,
    );
    return BiosecurityChecklistModel.fromJson(response.data);
  }

  Future<void> deleteChecklist(int id) async {
    await _dio.delete('/api/veterinary/biosecurity-checklists/$id/');
  }

  Future<Map<String, dynamic>> getComplianceStats(
    int farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, dynamic>{'farm_id': farmId};
    if (startDate != null)
      queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

    final response = await _dio.get(
      '/api/veterinary/biosecurity-checklists/compliance-stats/',
      queryParameters: queryParams,
    );
    return response.data;
  }
}
