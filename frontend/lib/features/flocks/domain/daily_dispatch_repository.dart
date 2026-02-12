import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/safe_call.dart';
import '../../../data/models/daily_record_model.dart';
import '../../../data/models/dispatch_record_model.dart';
import '../data/daily_dispatch_datasource.dart';

class DailyRecordRepository {
  final DailyRecordDataSource dataSource;

  DailyRecordRepository(this.dataSource);

  Future<Either<Failure, List<DailyRecordModel>>> getDailyRecords({
    required int flockId,
    String? dateFrom,
    String? dateTo,
    int? week,
  }) =>
      safeCall(
        () => dataSource.getDailyRecords(
          flockId: flockId,
          dateFrom: dateFrom,
          dateTo: dateTo,
          week: week,
        ),
        'Error cargando registros diarios',
      );

  Future<Either<Failure, DailyRecordModel>> createDailyRecord(
          Map<String, dynamic> data) =>
      safeCall(
        () => dataSource.createDailyRecord(data),
        'Error creando registro diario',
      );

  Future<Either<Failure, Map<String, dynamic>>> bulkSyncDailyRecords(
          List<Map<String, dynamic>> records) =>
      safeCall(
        () => dataSource.bulkSyncDailyRecords(records),
        'Error sincronizando registros diarios',
      );
}

class DispatchRepository {
  final DispatchDataSource dataSource;

  DispatchRepository(this.dataSource);

  Future<Either<Failure, List<DispatchRecordModel>>> getDispatches({
    int? flockId,
    String? dateFrom,
    String? dateTo,
  }) =>
      safeCall(
        () => dataSource.getDispatches(
          flockId: flockId,
          dateFrom: dateFrom,
          dateTo: dateTo,
        ),
        'Error cargando despachos',
      );

  Future<Either<Failure, DispatchRecordModel>> createDispatch(
          Map<String, dynamic> data) =>
      safeCall(
        () => dataSource.createDispatch(data),
        'Error creando despacho',
      );

  Future<Either<Failure, DispatchRecordModel>> updateDispatch(
          int id, Map<String, dynamic> data) =>
      safeCall(
        () => dataSource.updateDispatch(id, data),
        'Error actualizando despacho',
      );

  Future<Either<Failure, DispatchRecordModel>> getDispatchDetail(int id) =>
      safeCall(
        () => dataSource.getDispatchDetail(id),
        'Error cargando detalle del despacho',
      );
}
