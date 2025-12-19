import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../../data/reports_datasource.dart';
import '../../data/reports_repository_impl.dart';
import '../../domain/reports_repository.dart';

// Repository Provider
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  // TODO: Replace with actual Dio instance from core
  final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/'));
  final dataSource = ReportsDataSource(dio);
  return ReportsRepositoryImpl(dataSource);
});

// State
class ReportsState extends Equatable {
  final bool isLoading;
  final List<Report> reports;
  final List<ReportTemplate> templates;
  final String? errorMessage;
  final Report? selectedReport;

  const ReportsState({
    this.isLoading = false,
    this.reports = const [],
    this.templates = const [],
    this.errorMessage,
    this.selectedReport,
  });

  ReportsState copyWith({
    bool? isLoading,
    List<Report>? reports,
    List<ReportTemplate>? templates,
    String? errorMessage,
    Report? selectedReport,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      reports: reports ?? this.reports,
      templates: templates ?? this.templates,
      errorMessage: errorMessage,
      selectedReport: selectedReport,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    reports,
    templates,
    errorMessage,
    selectedReport,
  ];
}

// Provider
class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository repository;

  ReportsNotifier(this.repository) : super(const ReportsState()) {
    loadTemplates();
  }

  // Load Reports
  Future<void> loadReports({int? farmId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await repository.getReports(farmId: farmId);

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Error al cargar reportes',
        );
      },
      (reports) {
        state = state.copyWith(
          isLoading: false,
          reports: reports,
          errorMessage: null,
        );
      },
    );
  }

  // Load Templates
  Future<void> loadTemplates() async {
    final result = await repository.getReportTemplates();

    result.fold(
      (failure) {
        // Keep default templates on failure
        state = state.copyWith(templates: ReportTemplate.defaults);
      },
      (templates) {
        state = state.copyWith(templates: templates);
      },
    );
  }

  // Generate Report
  Future<bool> generateReport({
    required String type,
    required int farmId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await repository.generateReport(
      type: type,
      farmId: farmId,
      startDate: startDate,
      endDate: endDate,
      filters: filters,
    );

    return result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
      (report) {
        final updatedReports = [report, ...state.reports];
        state = state.copyWith(
          isLoading: false,
          reports: updatedReports,
          selectedReport: report,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  // Delete Report
  Future<bool> deleteReport(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await repository.deleteReport(id);

    return result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message ?? 'Error al eliminar reporte',
        );
        return false;
      },
      (_) {
        final updatedReports = state.reports.where((r) => r.id != id).toList();
        state = state.copyWith(
          isLoading: false,
          reports: updatedReports,
          errorMessage: null,
        );
        return true;
      },
    );
  }

  // Select Report
  void selectReport(Report? report) {
    state = state.copyWith(selectedReport: report);
  }

  // Clear Error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// State Provider
final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((
  ref,
) {
  final repository = ref.watch(reportsRepositoryProvider);
  return ReportsNotifier(repository);
});
