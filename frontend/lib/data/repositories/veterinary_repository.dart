import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../datasources/veterinary_datasource.dart';
import '../models/veterinary_visit_model.dart';
import '../models/vaccination_record_model.dart';
import '../models/medication_model.dart';
import '../models/disease_model.dart';
import '../models/biosecurity_checklist_model.dart';

class VeterinaryRepository {
  final VeterinaryDataSource _dataSource;

  VeterinaryRepository(this._dataSource);

  // ==================== VETERINARY VISITS ====================

  Future<Either<Failure, List<VeterinaryVisitModel>>> getVisits({
    int? farmId,
    int? flockId,
    String? status,
  }) async {
    try {
      final visits = await _dataSource.getVisits(
        farmId: farmId,
        flockId: flockId,
        status: status,
      );
      return Right(visits);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(NotFoundFailure(message: 'Visitas no encontradas'));
      }
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener visitas'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VeterinaryVisitModel>> getVisitById(int id) async {
    try {
      final visit = await _dataSource.getVisitById(id);
      return Right(visit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(NotFoundFailure(message: 'Visita no encontrada'));
      }
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener visita'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VeterinaryVisitModel>> createVisit(
    Map<String, dynamic> data,
  ) async {
    try {
      final visit = await _dataSource.createVisit(data);
      return Right(visit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return const Left(ValidationFailure(message: 'Datos inválidos'));
      }
      return Left(ServerFailure(message: e.message ?? 'Error al crear visita'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VeterinaryVisitModel>> updateVisit(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final visit = await _dataSource.updateVisit(id, data);
      return Right(visit);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(NotFoundFailure(message: 'Visita no encontrada'));
      }
      return Left(
        ServerFailure(message: e.message ?? 'Error al actualizar visita'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, void>> deleteVisit(int id) async {
    try {
      await _dataSource.deleteVisit(id);
      return const Right(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(NotFoundFailure(message: 'Visita no encontrada'));
      }
      return Left(
        ServerFailure(message: e.message ?? 'Error al eliminar visita'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VeterinaryVisitModel>> completeVisit(
    int id,
    String diagnosis,
    String treatment,
    String? notes,
    List<String>? photoUrls,
  ) async {
    try {
      final visit = await _dataSource.completeVisit(
        id,
        diagnosis,
        treatment,
        notes,
        photoUrls,
      );
      return Right(visit);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al completar visita'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ==================== VACCINATIONS ====================

  Future<Either<Failure, List<VaccinationRecordModel>>> getVaccinations({
    int? flockId,
    String? status,
  }) async {
    try {
      final vaccinations = await _dataSource.getVaccinations(
        flockId: flockId,
        status: status,
      );
      return Right(vaccinations);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener vacunas'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VaccinationRecordModel>> createVaccination(
    Map<String, dynamic> data,
  ) async {
    try {
      final vaccination = await _dataSource.createVaccination(data);
      return Right(vaccination);
    } on DioException catch (e) {
      return Left(ServerFailure(message: e.message ?? 'Error al crear vacuna'));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, VaccinationRecordModel>> applyVaccination(
    int id,
    int appliedBy,
    int birdCount,
    String? notes,
  ) async {
    try {
      final vaccination = await _dataSource.applyVaccination(
        id,
        appliedBy,
        birdCount,
        notes,
      );
      return Right(vaccination);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al aplicar vacuna'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<VaccinationRecordModel>>> getUpcomingVaccinations(
    int daysAhead,
  ) async {
    try {
      final vaccinations = await _dataSource.getUpcomingVaccinations(daysAhead);
      return Right(vaccinations);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.message ?? 'Error al obtener próximas vacunas',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ==================== MEDICATIONS ====================

  Future<Either<Failure, List<MedicationModel>>> getMedications({
    int? flockId,
    String? status,
  }) async {
    try {
      final medications = await _dataSource.getMedications(
        flockId: flockId,
        status: status,
      );
      return Right(medications);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener medicamentos'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, MedicationModel>> createMedication(
    Map<String, dynamic> data,
  ) async {
    try {
      final medication = await _dataSource.createMedication(data);
      return Right(medication);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al crear medicamento'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<MedicationModel>>> getActiveMedications() async {
    try {
      final medications = await _dataSource.getActiveMedications();
      return Right(medications);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.message ?? 'Error al obtener medicamentos activos',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<MedicationModel>>>
  getMedicationsInWithdrawal() async {
    try {
      final medications = await _dataSource.getMedicationsInWithdrawal();
      return Right(medications);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          message: e.message ?? 'Error al obtener medicamentos en retiro',
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ==================== DISEASES ====================

  Future<Either<Failure, List<DiseaseModel>>> getDiseases({
    String? category,
    String? severity,
  }) async {
    try {
      final diseases = await _dataSource.getDiseases(
        category: category,
        severity: severity,
      );
      return Right(diseases);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener enfermedades'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, DiseaseModel>> getDiseaseById(int id) async {
    try {
      final disease = await _dataSource.getDiseaseById(id);
      return Right(disease);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener enfermedad'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<DiseaseModel>>> searchDiseases(
    String query,
  ) async {
    try {
      final diseases = await _dataSource.searchDiseases(query);
      return Right(diseases);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al buscar enfermedades'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ==================== BIOSECURITY CHECKLISTS ====================

  Future<Either<Failure, List<BiosecurityChecklistModel>>> getChecklists({
    int? farmId,
    int? shedId,
    String? checklistType,
  }) async {
    try {
      final checklists = await _dataSource.getChecklists(
        farmId: farmId,
        shedId: shedId,
        checklistType: checklistType,
      );
      return Right(checklists);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener checklists'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, BiosecurityChecklistModel>> createChecklist(
    Map<String, dynamic> data,
  ) async {
    try {
      final checklist = await _dataSource.createChecklist(data);
      return Right(checklist);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al crear checklist'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getComplianceStats(
    int farmId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final stats = await _dataSource.getComplianceStats(
        farmId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(stats);
    } on DioException catch (e) {
      return Left(
        ServerFailure(message: e.message ?? 'Error al obtener estadísticas'),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
