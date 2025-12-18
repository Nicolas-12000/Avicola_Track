import 'package:dio/dio.dart';
import '../../../data/models/alarm_model.dart';

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
    } catch (e) {
      throw Exception('Failed to load alarms: $e');
    }
  }

  Future<AlarmModel> getAlarm(int id) async {
    try {
      final response = await dio.get('/alarms/$id/');
      return AlarmModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load alarm: $e');
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
    } catch (e) {
      throw Exception('Failed to resolve alarm: $e');
    }
  }

  Future<AlarmModel> escalateAlarm(int id) async {
    try {
      final response = await dio.post('/alarms/$id/escalate/');
      return AlarmModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to escalate alarm: $e');
    }
  }

  Future<void> deleteAlarm(int id) async {
    try {
      await dio.delete('/alarms/$id/');
    } catch (e) {
      throw Exception('Failed to delete alarm: $e');
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
    } catch (e) {
      throw Exception('Failed to load alarm stats: $e');
    }
  }
}
