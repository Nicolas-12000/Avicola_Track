import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
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

      final response = await dio.get(
        ApiConstants.alarmsManage,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final List<dynamic> data =
          responseData is Map<String, dynamic> &&
                  responseData.containsKey('results')
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
      final response = await dio.get(ApiConstants.alarmManageDetail(id));
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
        ApiConstants.alarmResolve(id),
        data: {'notes': resolutionNotes},
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
      final response = await dio.post(ApiConstants.alarmEscalate(id));
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
      await dio.delete(ApiConstants.alarmManageDetail(id));
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
        ApiConstants.alarmsDashboard,
        queryParameters: queryParams,
      );
      final data = response.data as Map<String, dynamic>;
      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      return {
        'total': (summary['total'] as int?) ?? 0,
        'pending': (summary['pending'] as int?) ?? 0,
        'acknowledged':
            (summary['acknowledged'] as int?) ??
            (summary['resolved'] as int?) ??
            0,
      };
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
      final response = await dio.get(ApiConstants.alarmsDashboard);
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
        ApiConstants.alarmAcknowledge(id),
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
        ApiConstants.alarmsBulkAcknowledge,
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
      final response = await dio.get(ApiConstants.notificationsUnread);
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
      final response = await dio.get(ApiConstants.notificationsRecent);
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
