import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/alarm_model.dart';
import '../data/alarm_datasource.dart';

class AlarmRepository {
  final AlarmDataSource dataSource;

  AlarmRepository(this.dataSource);

  Future<Either<Failure, List<AlarmModel>>> getAlarms({
    int? farmId,
    String? severity,
    bool? isResolved,
  }) async {
    try {
      final alarms = await dataSource.getAlarms(
        farmId: farmId,
        severity: severity,
        isResolved: isResolved,
      );
      return Right(alarms);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al cargar alarmas: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, AlarmModel>> getAlarm(int id) async {
    try {
      final alarm = await dataSource.getAlarm(id);
      return Right(alarm);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al cargar alarma: ${e.toString()}'),
      );
    }
  }

  // Note: createAlarm not available in datasource

  Future<Either<Failure, AlarmModel>> resolveAlarm({
    required int id,
    required String resolutionNotes,
  }) async {
    try {
      final alarm = await dataSource.resolveAlarm(
        id: id,
        resolutionNotes: resolutionNotes,
      );
      return Right(alarm);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al resolver alarma: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, AlarmModel>> escalateAlarm(int id) async {
    try {
      final alarm = await dataSource.escalateAlarm(id);
      return Right(alarm);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al escalar alarma: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> deleteAlarm(int id) async {
    try {
      await dataSource.deleteAlarm(id);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al eliminar alarma: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getAlarmStats({
    int? farmId,
  }) async {
    try {
      final stats = await dataSource.getAlarmStats(farmId: farmId);
      return Right(stats);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Error al cargar estadísticas: ${e.toString()}'),
      );
    }
  }
}
