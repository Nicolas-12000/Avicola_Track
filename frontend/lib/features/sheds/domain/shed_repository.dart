import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/shed_model.dart';
import '../data/shed_datasource.dart';

class ShedRepository {
  final ShedDataSource dataSource;

  ShedRepository(this.dataSource);

  Future<Either<Failure, List<ShedModel>>> getSheds({int? farmId}) async {
    try {
      final sheds = await dataSource.getSheds(farmId: farmId);
      return Right(sheds);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to load sheds: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, ShedModel>> getShed(int id) async {
    try {
      final shed = await dataSource.getShed(id);
      return Right(shed);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to load shed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, ShedModel>> createShed({
    required String name,
    required int farmId,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    try {
      final shed = await dataSource.createShed(
        name: name,
        farmId: farmId,
        capacity: capacity,
        assignedWorkerId: assignedWorkerId,
      );
      return Right(shed);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to create shed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, ShedModel>> updateShed({
    required int id,
    required String name,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    try {
      final shed = await dataSource.updateShed(
        id: id,
        name: name,
        capacity: capacity,
        assignedWorkerId: assignedWorkerId,
      );
      return Right(shed);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to update shed: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> deleteShed(int id) async {
    try {
      await dataSource.deleteShed(id);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to delete shed: ${e.toString()}'),
      );
    }
  }
}
