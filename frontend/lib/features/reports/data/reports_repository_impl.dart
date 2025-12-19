import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../domain/reports_repository.dart';
import 'reports_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsDataSource dataSource;

  ReportsRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<Report>>> getReports({int? farmId}) async {
    try {
      final reports = await dataSource.getReports(farmId: farmId);
      return Right(reports);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Report>> getReportById(int id) async {
    try {
      final report = await dataSource.getReportById(id);
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Report>> generateReport({
    required String type,
    required int farmId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final report = await dataSource.generateReport(
        type: type,
        farmId: farmId,
        startDate: startDate,
        endDate: endDate,
        filters: filters,
      );
      return Right(report);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReport(int id) async {
    try {
      await dataSource.deleteReport(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ReportTemplate>>> getReportTemplates() async {
    try {
      final templates = await dataSource.getReportTemplates();
      return Right(templates.cast<ReportTemplate>());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
