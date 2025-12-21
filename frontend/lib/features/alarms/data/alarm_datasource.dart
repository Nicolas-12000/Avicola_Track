import 'package:dio/dio.dart';
import '../../../data/models/alarm_model.dart';
import '../../../core/utils/error_handler.dart';

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

      final response = await dio.get('/alarms/', queryParameters: queryParams);

      final List<dynamic> data = response.data as List<dynamic>;
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
      final response = await dio.get('/alarms/$id/');
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
        '/alarms/$id/resolve/',
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
      final response = await dio.post('/alarms/$id/escalate/');
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
      await dio.delete('/alarms/$id/');
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
        '/alarms/stats/',
        queryParameters: queryParams,
      );
      return Map<String, int>.from(response.data as Map<String, dynamic>);
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
      final response = await dio.get('/alarms/dashboard/');
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
        '/alarms/$id/acknowledge/',
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
        '/alarms/bulk-acknowledge/',
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
      final response = await dio.get('/notifications/unread/');
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
      final response = await dio.get('/notifications/recent/');
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
