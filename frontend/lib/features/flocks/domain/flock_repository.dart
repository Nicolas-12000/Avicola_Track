import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/flock_model.dart';
import '../../../data/models/weight_record_model.dart';
import '../../../data/models/mortality_record_model.dart';
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
      return Left(
        ServerFailure(message: 'Failed to load flocks: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, FlockModel>> getFlock(int id) async {
    try {
      final flock = await dataSource.getFlock(id);
      return Right(flock);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to load flock: ${e.toString()}'),
      );
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
      return Left(ServerFailure(message: msg));
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
      return Left(
        ServerFailure(message: 'Failed to update flock: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> deleteFlock(int id) async {
    try {
      await dataSource.deleteFlock(id);
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to delete flock: ${e.toString()}'),
      );
    }
  }

  // Weight Records
  Future<Either<Failure, List<WeightRecordModel>>> getWeightRecords(
    int flockId,
  ) async {
    try {
      final records = await dataSource.getWeightRecords(flockId);
      return Right(records);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to load weight records: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Failure, WeightRecordModel>> createWeightRecord({
    required int flockId,
    required double averageWeight,
    required int sampleSize,
    required DateTime recordDate,
    String? notes,
  }) async {
    try {
      final record = await dataSource.createWeightRecord(
        flockId: flockId,
        averageWeight: averageWeight,
        sampleSize: sampleSize,
        recordDate: recordDate,
        notes: notes,
      );
      return Right(record);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to create weight record: ${e.toString()}',
        ),
      );
    }
  }

  // Mortality Records
  Future<Either<Failure, List<MortalityRecordModel>>> getMortalityRecords(
    int flockId,
  ) async {
    try {
      final records = await dataSource.getMortalityRecords(flockId);
      return Right(records);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to load mortality records: ${e.toString()}',
        ),
      );
    }
  }

  Future<Either<Failure, MortalityRecordModel>> createMortalityRecord({
    required int flockId,
    required int quantity,
    required String cause,
    required DateTime recordDate,
    double? temperature,
    String? notes,
  }) async {
    try {
      final record = await dataSource.createMortalityRecord(
        flockId: flockId,
        quantity: quantity,
        cause: cause,
        recordDate: recordDate,
        temperature: temperature,
        notes: notes,
      );
      return Right(record);
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Failed to create mortality record: ${e.toString()}',
        ),
      );
    }
  }
}
