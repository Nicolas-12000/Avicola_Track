import 'package:dio/dio.dart';
import '../domain/reports_repository.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';

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
    try {
      final response = await dio.get(ApiConstants.reportTemplates);
      return (response.data as List).map((template) {
        return ReportTemplate(
          id: template['id'].toString(),
          name: template['name'] as String,
          description: template['description'] as String? ?? '',
          icon: _mapReportTypeToIcon(template['report_type'] as String),
          type: template['report_type'] as String,
          requiredFilters: _getRequiredFiltersForType(
            template['report_type'] as String,
          ),
        );
      }).toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load report templates',
        stackTrace: stackTrace,
      );
      // Return default templates on error
      return ReportTemplate.defaults;
    }
  }

  String _mapReportTypeToIcon(String reportType) {
    switch (reportType) {
      case 'productivity':
        return '📊';
      case 'mortality':
        return '📉';
      case 'weight':
        return '⚖️';
      case 'consumption':
        return '🍽️';
      case 'inventory':
        return '📦';
      case 'alarms':
        return '🔔';
      case 'financial':
        return '💰';
      default:
        return '📋';
    }
  }

  List<String> _getRequiredFiltersForType(String reportType) {
    switch (reportType) {
      case 'productivity':
      case 'mortality':
      case 'weight':
      case 'consumption':
        return ['farmId', 'dateRange'];
      case 'inventory':
        return ['farmId'];
      case 'alarms':
        return ['farmId', 'dateRange'];
      case 'financial':
        return ['farmId', 'dateRange'];
      default:
        return [];
    }
  }

  Future<List<Map<String, dynamic>>> getReportTypes() async {
    try {
      final response = await dio.get('/reports/types/');
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load report types',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> quickProductivityReport({
    required int farmId,
    int? shedId,
    int? flockId,
    required DateTime dateFrom,
    required DateTime dateTo,
    String exportFormat = 'json',
    bool includeCharts = true,
  }) async {
    try {
      final data = {
        'farm': farmId,
        if (shedId != null) 'shed': shedId,
        if (flockId != null) 'flock': flockId,
        'date_from': dateFrom.toIso8601String().split('T')[0],
        'date_to': dateTo.toIso8601String().split('T')[0],
        'export_format': exportFormat,
        'include_charts': includeCharts,
      };

      final response = await dio.post(
        '/reports/quick_productivity/',
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to generate quick productivity report',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Report> generateReportFromId({required int reportId}) async {
    try {
      final response = await dio.post('/reports/$reportId/generate/');
      return Report.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to generate report',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
