import 'package:dio/dio.dart';
import '../../../data/models/daily_record_model.dart';
import '../../../data/models/dispatch_record_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/api_helpers.dart';

class DailyRecordDataSource {
  final Dio dio;

  DailyRecordDataSource(this.dio);

  /// Obtener registros diarios de un lote
  Future<List<DailyRecordModel>> getDailyRecords({
    required int flockId,
    String? dateFrom,
    String? dateTo,
    int? week,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {'flock': flockId};
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      if (week != null) queryParams['week'] = week;

      final response = await dio.get(
        ApiConstants.dailyRecords,
        queryParameters: queryParams,
      );

      final data = parsePaginatedResponse(response.data);

      return data
          .map((json) => DailyRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to load daily records', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crear registro diario
  Future<DailyRecordModel> createDailyRecord(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(ApiConstants.dailyRecords, data: data);
      return DailyRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to create daily record', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Sincronización masiva
  Future<Map<String, dynamic>> bulkSyncDailyRecords(List<Map<String, dynamic>> records) async {
    try {
      final response = await dio.post(
        ApiConstants.dailyRecordsBulkSync,
        data: {'daily_records': records},
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to bulk sync daily records', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtener resumen consolidado
  Future<List<Map<String, dynamic>>> getDailyRecordsSummary(int flockId) async {
    try {
      final response = await dio.get(
        ApiConstants.dailyRecordsSummary,
        queryParameters: {'flock': flockId},
      );
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to load daily records summary', stackTrace: stackTrace);
      rethrow;
    }
  }
}

class DispatchDataSource {
  final Dio dio;

  DispatchDataSource(this.dio);

  /// Obtener despachos de un lote
  Future<List<DispatchRecordModel>> getDispatches({
    int? flockId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (flockId != null) queryParams['flock'] = flockId;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await dio.get(
        ApiConstants.dispatches,
        queryParameters: queryParams,
      );

      final data = parsePaginatedResponse(response.data);

      return data
          .map((json) => DispatchRecordModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to load dispatches', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Crear despacho
  Future<DispatchRecordModel> createDispatch(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(ApiConstants.dispatches, data: data);
      return DispatchRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to create dispatch', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Actualizar despacho (ej: agregar datos de planta/venta)
  Future<DispatchRecordModel> updateDispatch(int id, Map<String, dynamic> data) async {
    try {
      final response = await dio.patch(
        ApiConstants.dispatchDetail(id),
        data: data,
      );
      return DispatchRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to update dispatch', stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Obtener detalle de un despacho
  Future<DispatchRecordModel> getDispatchDetail(int id) async {
    try {
      final response = await dio.get(ApiConstants.dispatchDetail(id));
      return DispatchRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(e, context: 'Failed to load dispatch detail', stackTrace: stackTrace);
      rethrow;
    }
  }
}
