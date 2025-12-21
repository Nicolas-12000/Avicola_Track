import 'package:dio/dio.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';

class VeterinaryDataSource {
  final Dio dio;

  VeterinaryDataSource({required this.dio});

  // Veterinary Visits
  Future<List<Map<String, dynamic>>> getVisits({
    int? flockId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (flockId != null) queryParams['flock'] = flockId;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await dio.get(
        ApiConstants.veterinaryVisits,
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load veterinary visits',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createVisit({
    required int flockId,
    required DateTime visitDate,
    required String veterinarianName,
    String? reasonForVisit,
    String? diagnosis,
    String? treatment,
    String? recommendations,
    String? notes,
  }) async {
    try {
      final data = {
        'flock': flockId,
        'visit_date': visitDate.toIso8601String().split('T')[0],
        'veterinarian_name': veterinarianName,
        if (reasonForVisit != null) 'reason_for_visit': reasonForVisit,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (treatment != null) 'treatment': treatment,
        if (recommendations != null) 'recommendations': recommendations,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        ApiConstants.veterinaryVisits,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create veterinary visit',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateVisit({
    required int visitId,
    int? flockId,
    DateTime? visitDate,
    String? veterinarianName,
    String? reasonForVisit,
    String? diagnosis,
    String? treatment,
    String? recommendations,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (flockId != null) data['flock'] = flockId;
      if (visitDate != null) {
        data['visit_date'] = visitDate.toIso8601String().split('T')[0];
      }
      if (veterinarianName != null)
        data['veterinarian_name'] = veterinarianName;
      if (reasonForVisit != null) data['reason_for_visit'] = reasonForVisit;
      if (diagnosis != null) data['diagnosis'] = diagnosis;
      if (treatment != null) data['treatment'] = treatment;
      if (recommendations != null) data['recommendations'] = recommendations;
      if (notes != null) data['notes'] = notes;

      final response = await dio.put(
        '${ApiConstants.veterinaryVisits}$visitId/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update veterinary visit',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteVisit(int visitId) async {
    try {
      await dio.delete('${ApiConstants.veterinaryVisits}$visitId/');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete veterinary visit',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeVisit(int visitId) async {
    try {
      final response = await dio.post(
        '${ApiConstants.veterinaryVisits}$visitId/complete/',
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to complete veterinary visit',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTodayAndUpcomingVisits() async {
    try {
      final response = await dio.get(
        '${ApiConstants.veterinaryVisits}today_upcoming/',
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load today and upcoming visits',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Vaccinations
  Future<List<Map<String, dynamic>>> getVaccinations({
    int? flockId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (flockId != null) queryParams['flock'] = flockId;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await dio.get(
        ApiConstants.vaccinations,
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load vaccinations',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createVaccination({
    required int flockId,
    required String vaccineName,
    required DateTime scheduledDate,
    required String applicationMethod,
    String? dosage,
    String? batchNumber,
    String? notes,
  }) async {
    try {
      final data = {
        'flock': flockId,
        'vaccine_name': vaccineName,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'application_method': applicationMethod,
        if (dosage != null) 'dosage': dosage,
        if (batchNumber != null) 'batch_number': batchNumber,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(ApiConstants.vaccinations, data: data);
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create vaccination',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateVaccination({
    required int vaccinationId,
    int? flockId,
    String? vaccineName,
    DateTime? scheduledDate,
    DateTime? appliedDate,
    String? applicationMethod,
    String? dosage,
    String? batchNumber,
    String? appliedBy,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (flockId != null) data['flock'] = flockId;
      if (vaccineName != null) data['vaccine_name'] = vaccineName;
      if (scheduledDate != null) {
        data['scheduled_date'] = scheduledDate.toIso8601String().split('T')[0];
      }
      if (appliedDate != null) {
        data['applied_date'] = appliedDate.toIso8601String().split('T')[0];
      }
      if (applicationMethod != null)
        data['application_method'] = applicationMethod;
      if (dosage != null) data['dosage'] = dosage;
      if (batchNumber != null) data['batch_number'] = batchNumber;
      if (appliedBy != null) data['applied_by'] = appliedBy;
      if (notes != null) data['notes'] = notes;

      final response = await dio.put(
        '${ApiConstants.vaccinations}$vaccinationId/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update vaccination',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteVaccination(int vaccinationId) async {
    try {
      await dio.delete('${ApiConstants.vaccinations}$vaccinationId/');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete vaccination',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyVaccination({
    required int vaccinationId,
    required DateTime appliedDate,
    required String appliedBy,
    String? notes,
  }) async {
    try {
      final data = {
        'applied_date': appliedDate.toIso8601String().split('T')[0],
        'applied_by': appliedBy,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        '${ApiConstants.vaccinations}$vaccinationId/apply/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to apply vaccination',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUpcomingVaccinations() async {
    try {
      final response = await dio.get('${ApiConstants.vaccinations}upcoming/');
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load upcoming vaccinations',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Medications
  Future<List<Map<String, dynamic>>> getMedications({
    int? flockId,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? activeOnly,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (flockId != null) queryParams['flock'] = flockId;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (activeOnly != null) queryParams['active'] = activeOnly;

      final response = await dio.get(
        ApiConstants.medications,
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load medications',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createMedication({
    required int flockId,
    required String medicationName,
    required DateTime startDate,
    required DateTime endDate,
    required String dosage,
    required int withdrawalPeriodDays,
    String? applicationMethod,
    String? frequency,
    String? prescribedBy,
    String? reason,
    String? notes,
  }) async {
    try {
      final data = {
        'flock': flockId,
        'medication_name': medicationName,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'dosage': dosage,
        'withdrawal_period_days': withdrawalPeriodDays,
        if (applicationMethod != null) 'application_method': applicationMethod,
        if (frequency != null) 'frequency': frequency,
        if (prescribedBy != null) 'prescribed_by': prescribedBy,
        if (reason != null) 'reason': reason,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(ApiConstants.medications, data: data);
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create medication',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateMedication({
    required int medicationId,
    int? flockId,
    String? medicationName,
    DateTime? startDate,
    DateTime? endDate,
    String? dosage,
    int? withdrawalPeriodDays,
    String? applicationMethod,
    String? frequency,
    String? prescribedBy,
    String? reason,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (flockId != null) data['flock'] = flockId;
      if (medicationName != null) data['medication_name'] = medicationName;
      if (startDate != null) {
        data['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        data['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (dosage != null) data['dosage'] = dosage;
      if (withdrawalPeriodDays != null) {
        data['withdrawal_period_days'] = withdrawalPeriodDays;
      }
      if (applicationMethod != null)
        data['application_method'] = applicationMethod;
      if (frequency != null) data['frequency'] = frequency;
      if (prescribedBy != null) data['prescribed_by'] = prescribedBy;
      if (reason != null) data['reason'] = reason;
      if (notes != null) data['notes'] = notes;

      final response = await dio.put(
        '${ApiConstants.medications}$medicationId/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update medication',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteMedication(int medicationId) async {
    try {
      await dio.delete('${ApiConstants.medications}$medicationId/');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete medication',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recordMedicationApplication({
    required int medicationId,
    required DateTime applicationDate,
    required String appliedBy,
    String? batchNumber,
    String? notes,
  }) async {
    try {
      final data = {
        'application_date': applicationDate.toIso8601String().split('T')[0],
        'applied_by': appliedBy,
        if (batchNumber != null) 'batch_number': batchNumber,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        '${ApiConstants.medications}$medicationId/record_application/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to record medication application',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveMedications() async {
    try {
      final response = await dio.get('${ApiConstants.medications}active/');
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load active medications',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getWithdrawalPeriods() async {
    try {
      final response = await dio.get('${ApiConstants.medications}withdrawal/');
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load withdrawal periods',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Diseases
  Future<List<Map<String, dynamic>>> getDiseases({
    int? flockId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (flockId != null) queryParams['flock'] = flockId;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await dio.get(
        ApiConstants.diseases,
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load diseases',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createDisease({
    required int flockId,
    required String diseaseName,
    required DateTime detectedDate,
    String? symptoms,
    String? diagnosis,
    String? treatment,
    int? affectedBirds,
    String? severity,
    String? notes,
  }) async {
    try {
      final data = {
        'flock': flockId,
        'disease_name': diseaseName,
        'detected_date': detectedDate.toIso8601String().split('T')[0],
        if (symptoms != null) 'symptoms': symptoms,
        if (diagnosis != null) 'diagnosis': diagnosis,
        if (treatment != null) 'treatment': treatment,
        if (affectedBirds != null) 'affected_birds': affectedBirds,
        if (severity != null) 'severity': severity,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(ApiConstants.diseases, data: data);
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create disease record',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateDisease({
    required int diseaseId,
    int? flockId,
    String? diseaseName,
    DateTime? detectedDate,
    DateTime? resolvedDate,
    String? symptoms,
    String? diagnosis,
    String? treatment,
    int? affectedBirds,
    String? severity,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (flockId != null) data['flock'] = flockId;
      if (diseaseName != null) data['disease_name'] = diseaseName;
      if (detectedDate != null) {
        data['detected_date'] = detectedDate.toIso8601String().split('T')[0];
      }
      if (resolvedDate != null) {
        data['resolved_date'] = resolvedDate.toIso8601String().split('T')[0];
      }
      if (symptoms != null) data['symptoms'] = symptoms;
      if (diagnosis != null) data['diagnosis'] = diagnosis;
      if (treatment != null) data['treatment'] = treatment;
      if (affectedBirds != null) data['affected_birds'] = affectedBirds;
      if (severity != null) data['severity'] = severity;
      if (notes != null) data['notes'] = notes;

      final response = await dio.put(
        '${ApiConstants.diseases}$diseaseId/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update disease record',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteDisease(int diseaseId) async {
    try {
      await dio.delete('${ApiConstants.diseases}$diseaseId/');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete disease record',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Biosecurity Measures
  Future<List<Map<String, dynamic>>> getBiosecurityMeasures({
    int? farmId,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (farmId != null) queryParams['farm'] = farmId;
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }

      final response = await dio.get(
        ApiConstants.biosecurityChecklists,
        queryParameters: queryParams,
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load biosecurity measures',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBiosecurityMeasure({
    required int farmId,
    required String measureType,
    required DateTime implementedDate,
    String? description,
    String? frequency,
    String? responsiblePerson,
    String? notes,
  }) async {
    try {
      final data = {
        'farm': farmId,
        'measure_type': measureType,
        'implemented_date': implementedDate.toIso8601String().split('T')[0],
        if (description != null) 'description': description,
        if (frequency != null) 'frequency': frequency,
        if (responsiblePerson != null) 'responsible_person': responsiblePerson,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        ApiConstants.biosecurityChecklists,
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create biosecurity measure',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBiosecurityMeasure({
    required int measureId,
    int? farmId,
    String? measureType,
    DateTime? implementedDate,
    String? description,
    String? frequency,
    String? responsiblePerson,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (farmId != null) data['farm'] = farmId;
      if (measureType != null) data['measure_type'] = measureType;
      if (implementedDate != null) {
        data['implemented_date'] = implementedDate.toIso8601String().split(
          'T',
        )[0];
      }
      if (description != null) data['description'] = description;
      if (frequency != null) data['frequency'] = frequency;
      if (responsiblePerson != null)
        data['responsible_person'] = responsiblePerson;
      if (notes != null) data['notes'] = notes;

      final response = await dio.put(
        '${ApiConstants.biosecurityChecklists}$measureId/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update biosecurity measure',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteBiosecurityMeasure(int measureId) async {
    try {
      await dio.delete('${ApiConstants.biosecurityChecklists}$measureId/');
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete biosecurity measure',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getComplianceStats({int? farmId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (farmId != null) queryParams['farm'] = farmId;

      final response = await dio.get(
        '${ApiConstants.biosecurityChecklists}compliance_stats/',
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load compliance statistics',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
