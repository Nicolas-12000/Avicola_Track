import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
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

<<<<<<< HEAD
      final response = await dio.get(
        ApiConstants.alarmsManage,
        queryParameters: queryParams,
      );
=======
      final response = await dio.get(ApiConstants.alarmsManage, queryParameters: queryParams);
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579

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
<<<<<<< HEAD
      final response = await dio.get(ApiConstants.alarmManageDetail(id));
=======
      final response = await dio.get(ApiConstants.alarmDetail(id));
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
        ApiConstants.alarmResolve(id),
        data: {'notes': resolutionNotes},
=======
        '${ApiConstants.alarms}$id/resolve/',
        data: {'resolution_notes': resolutionNotes},
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
      final response = await dio.post(ApiConstants.alarmEscalate(id));
=======
      final response = await dio.post('${ApiConstants.alarms}$id/escalate/');
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
      await dio.delete(ApiConstants.alarmManageDetail(id));
=======
      await dio.delete(ApiConstants.alarmDetail(id));
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
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
=======
      
      // El backend devuelve {summary: {...}, urgent_alarms: [...], last_updated: ...}
      // Extraemos solo el summary que tiene las estadísticas
      final summary = response.data['summary'] as Map<String, dynamic>;
      return Map<String, int>.from(summary);
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
        ApiConstants.alarmAcknowledge(id),
=======
        '${ApiConstants.alarms}$id/acknowledge/',
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
        ApiConstants.alarmsBulkAcknowledge,
=======
        '${ApiConstants.alarms}bulk-acknowledge/',
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
      final response = await dio.get(ApiConstants.notificationsUnread);
=======
      final response = await dio.get('${ApiConstants.apiPrefix}/notifications/unread/');
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
<<<<<<< HEAD
      final response = await dio.get(ApiConstants.notificationsRecent);
=======
      final response = await dio.get('${ApiConstants.apiPrefix}/notifications/recent/');
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
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
