import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';

/// Domain Model for Report
class Report {
  final int? id;
  final String title;
  final String type; // 'production', 'mortality', 'inventory', 'complete'
  final DateTime generatedAt;
  final int farmId;
  final String? farmName;
  final DateTime? startDate;
  final DateTime? endDate;
  final Map<String, dynamic> data;
  final String? pdfPath;
  final String? excelPath;

  const Report({
    this.id,
    required this.title,
    required this.type,
    required this.generatedAt,
    required this.farmId,
    this.farmName,
    this.startDate,
    this.endDate,
    required this.data,
    this.pdfPath,
    this.excelPath,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int?,
      title: json['title'] as String,
      type: json['type'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
      farmId: json['farm_id'] as int,
      farmName: json['farm_name'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>,
      pdfPath: json['pdf_path'] as String?,
      excelPath: json['excel_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type': type,
      'generated_at': generatedAt.toIso8601String(),
      'farm_id': farmId,
      if (farmName != null) 'farm_name': farmName,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'data': data,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (excelPath != null) 'excel_path': excelPath,
    };
  }
}

/// Repository Interface for Reports
abstract class ReportsRepository {
  /// Get all reports
  Future<Either<Failure, List<Report>>> getReports({int? farmId});

  /// Get report by ID
  Future<Either<Failure, Report>> getReportById(int id);

  /// Generate a new report
  Future<Either<Failure, Report>> generateReport({
    required String type,
    required int farmId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  });

  /// Delete report
  Future<Either<Failure, void>> deleteReport(int id);

  /// Get report templates
  Future<Either<Failure, List<ReportTemplate>>> getReportTemplates();
}

/// Domain Model for Report Template
class ReportTemplate {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String type;
  final List<String> requiredFilters;

  const ReportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    this.requiredFilters = const [],
  });

  static List<ReportTemplate> defaults = [
    const ReportTemplate(
      id: 'production',
      name: 'Reporte de Producción',
      description: 'Análisis de peso, crecimiento y desempeño de lotes',
      icon: '📊',
      type: 'production',
      requiredFilters: ['farmId', 'dateRange'],
    ),
    const ReportTemplate(
      id: 'mortality',
      name: 'Reporte de Mortalidad',
      description: 'Registro de mortalidad por lote y causas',
      icon: '📉',
      type: 'mortality',
      requiredFilters: ['farmId', 'dateRange'],
    ),
    const ReportTemplate(
      id: 'inventory',
      name: 'Reporte de Inventario',
      description: 'Estado actual del inventario y movimientos',
      icon: '📦',
      type: 'inventory',
      requiredFilters: ['farmId'],
    ),
    const ReportTemplate(
      id: 'complete',
      name: 'Reporte Completo',
      description: 'Análisis completo: producción, mortalidad e inventario',
      icon: '📋',
      type: 'complete',
      requiredFilters: ['farmId', 'dateRange'],
    ),
  ];
}
