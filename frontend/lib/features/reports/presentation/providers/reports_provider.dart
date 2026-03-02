import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/reports_datasource.dart';
import '../../data/reports_repository_impl.dart';
import '../../domain/reports_repository.dart';

// Repository Provider
final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final dataSource = ReportsDataSource(dio);
  return ReportsRepositoryImpl(dataSource);
});

// State
class ReportsState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Report> reports;
  final List<ReportTemplate> templates;
  final String? errorMessage;
  final Report? selectedReport;
  final int currentPage;
  final bool hasMoreData;

  static const int pageSize = 20;

  const ReportsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.reports = const [],
    this.templates = const [],
    this.errorMessage,
    this.selectedReport,
    this.currentPage = 1,
    this.hasMoreData = true,
  });

  ReportsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Report>? reports,
    List<ReportTemplate>? templates,
    String? errorMessage,
    Report? selectedReport,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      reports: reports ?? this.reports,
      templates: templates ?? this.templates,
      errorMessage: errorMessage,
      selectedReport: selectedReport,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isLoadingMore,
    reports,
    templates,
    errorMessage,
    selectedReport,
    currentPage,
    hasMoreData,
  ];
}

// Provider
class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository repository;

  ReportsNotifier(this.repository) : super(const ReportsState()) {
    loadTemplates();
  }

  int? _lastFarmId;

  // Load Reports
  Future<void> loadReports({int? farmId}) async {
    _lastFarmId = farmId;
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentPage: 1,
      hasMoreData: true,
    );

    final result = await repository.getReports(farmId: farmId, page: 1);

    result.fold(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (reports) {
        state = state.copyWith(
          isLoading: false,
          reports: reports,
          errorMessage: null,
          currentPage: 1,
          hasMoreData: reports.length >= ReportsState.pageSize,
        );
      },
    );
  }

  // Load More Reports (infinite scroll)
  Future<void> loadMoreReports() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await repository.getReports(farmId: _lastFarmId, page: nextPage);

    result.fold(
      (failure) {
        state = state.copyWith(isLoadingMore: false, errorMessage: failure.message);
      },
      (newReports) {
        state = state.copyWith(
          reports: [...state.reports, ...newReports],
          isLoadingMore: false,
          currentPage: nextPage,
          hasMoreData: newReports.length >= ReportsState.pageSize,
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
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
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
