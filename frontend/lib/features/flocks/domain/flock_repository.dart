import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/flock_model.dart';
import '../data/flock_datasource.dart';

class FlockRepository {
  final FlockDataSource dataSource;

  FlockRepository(this.dataSource);

  Future<Either<Failure, List<FlockModel>>> getFlocks({
    int? farmId,
    int? shedId,
    String? status,
  }) async {
    try {
      final flocks = await dataSource.getFlocks(
        farmId: farmId,
        shedId: shedId,
        status: status,
      );
      return Right(flocks);
    } catch (e) {
      return Left(ServerFailure(
        message: ErrorHandler.getUserMessage(
          e,
          context: 'Failed to load flocks',
        ),
      ));
    }
  }

  Future<Either<Failure, FlockModel>> getFlock(int id) async {
    try {
      final flock = await dataSource.getFlock(id);
      return Right(flock);
    } catch (e) {
      return Left(ServerFailure(
        message: ErrorHandler.getUserMessage(
          e,
          context: 'Failed to load flock',
        ),
      ));
    }
  }

  Future<Either<Failure, FlockModel>> createFlock({
    required int shedId,
    required String breed,
    required int initialQuantity,
    required String gender,
    required DateTime arrivalDate,
    double? initialWeight,
    String? supplier,
  }) async {
    try {
      final flock = await dataSource.createFlock(
        shedId: shedId,
        breed: breed,
        initialQuantity: initialQuantity,
        gender: gender,
        arrivalDate: arrivalDate,
        initialWeight: initialWeight,
        supplier: supplier,
      );
      return Right(flock);
    } catch (e) {
      // Propagar mensaje detallado si viene del backend
      final msg = _extractMessage(e, defaultMsg: 'Failed to create flock');
      return Left(ServerFailure(
        message: ErrorHandler.getUserMessage(e, context: msg),
      ));
    }
  }

  String _extractMessage(Object e, {required String defaultMsg}) {
    if (e is DioException && e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map.isNotEmpty) {
        final firstKey = map.keys.first;
        final val = map[firstKey];
        if (val is List && val.isNotEmpty) {
          return val.first.toString();
        }
        return val.toString();
      }
    }
    return '$defaultMsg: ${e.toString()}';
  }

  Future<Either<Failure, FlockModel>> updateFlock({
    required int id,
    int? currentQuantity,
    double? currentWeight,
    String? status,
    DateTime? saleDate,
  }) async {
    try {
      final flock = await dataSource.updateFlock(
        id: id,
        currentQuantity: currentQuantity,
        currentWeight: currentWeight,
        status: status,
        saleDate: saleDate,
      );
      return Right(flock);
    } catch (e) {
      return Left(ServerFailure(
        message: ErrorHandler.getUserMessage(
          e,
          context: 'Failed to update flock',
        ),
      ));
    }
  }

  Future<Either<Failure, void>> deleteFlock(int id) async {
    try {
      await dataSource.deleteFlock(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(
        message: ErrorHandler.getUserMessage(
          e,
          context: 'Failed to delete flock',
        ),
      ));
    }
  }
}
