import 'package:dio/dio.dart';
import '../domain/reports_repository.dart';
import '../../../core/utils/error_handler.dart';

class ReportsDataSource {
  final Dio dio;

  ReportsDataSource(this.dio);

  Future<List<Report>> getReports({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm_id': farmId} : null;
      final response = await dio.get('/reports/', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['results'] ?? response.data;
        return data.map((json) => Report.fromJson(json)).toList();
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load reports',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load reports',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Report> getReportById(int id) async {
    try {
      final response = await dio.get('/reports/$id/');

      if (response.statusCode == 200) {
        return Report.fromJson(response.data);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load report',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load report',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Report> generateReport({
    required String type,
    required int farmId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final data = {
        'type': type,
        'farm_id': farmId,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (filters != null) ...filters,
      };

      final response = await dio.post('/reports/generate/', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Report.fromJson(response.data);
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to generate report',
      );
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to generate report',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteReport(int id) async {
    try {
      final response = await dio.delete('/reports/$id/');

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete report',
        );
      }
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete report',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<dynamic>> getReportTemplates() async {
    // For now, return static templates
    // In the future, this could be fetched from backend
    return ReportTemplate.defaults;
  }
}
