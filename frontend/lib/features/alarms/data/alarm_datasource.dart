import 'package:dio/dio.dart';
import '../../../data/models/alarm_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';

class AlarmDataSource {
  final Dio dio;

  AlarmDataSource(this.dio);

  Future<List<AlarmModel>> getAlarms({
    int? farmId,
    String? severity,
    bool? isResolved,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (farmId != null) queryParams['farm'] = farmId;
      if (severity != null) queryParams['severity'] = severity;
      if (isResolved != null) queryParams['is_resolved'] = isResolved;

      final response = await dio.get(ApiConstants.alarms, queryParameters: queryParams);

      // Handle paginated response from Django REST Framework
      final responseData = response.data;
      final List<dynamic> data = responseData is Map<String, dynamic> && responseData.containsKey('results')
          ? responseData['results'] as List<dynamic>
          : responseData as List<dynamic>;
          
      return data
          .map((json) => AlarmModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load alarms',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AlarmModel> getAlarm(int id) async {
    try {
      final response = await dio.get(ApiConstants.alarmDetail(id));
      return AlarmModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load alarm',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AlarmModel> resolveAlarm({
    required int id,
    required String resolutionNotes,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.alarms}$id/resolve/',
        data: {'resolution_notes': resolutionNotes},
      );
      return AlarmModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to resolve alarm',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<AlarmModel> escalateAlarm(int id) async {
    try {
      final response = await dio.post('${ApiConstants.alarms}$id/escalate/');
      return AlarmModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to escalate alarm',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteAlarm(int id) async {
    try {
      await dio.delete(ApiConstants.alarmDetail(id));
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete alarm',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, int>> getAlarmStats({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get(
        '${ApiConstants.alarms}dashboard/',
        queryParameters: queryParams,
      );
      
      // El backend devuelve {summary: {...}, urgent_alarms: [...], last_updated: ...}
      // Extraemos solo el summary que tiene las estadísticas
      final summary = response.data['summary'] as Map<String, dynamic>;
      return Map<String, int>.from(summary);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load alarm stats',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await dio.get('${ApiConstants.alarms}dashboard/');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load alarm dashboard',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> acknowledgeAlarm({
    required int id,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.alarms}$id/acknowledge/',
        data: {'notes': notes ?? ''},
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to acknowledge alarm',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bulkAcknowledgeAlarms({
    required List<int> alarmIds,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.alarms}bulk-acknowledge/',
        data: {'alarm_ids': alarmIds, 'notes': notes ?? ''},
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to bulk acknowledge alarms',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUnreadNotifications() async {
    try {
      final response = await dio.get('${ApiConstants.apiPrefix}/notifications/unread/');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load unread notifications',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecentNotifications() async {
    try {
      final response = await dio.get('${ApiConstants.apiPrefix}/notifications/recent/');
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load recent notifications',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
