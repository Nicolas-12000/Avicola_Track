import 'package:dio/dio.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/farm_model.dart';
import '../data/farm_datasource.dart';

class FarmRepository {
  final FarmDataSource _dataSource;

  FarmRepository(this._dataSource);

  Future<({List<FarmModel>? farms, Failure? failure})> getFarms() async {
    try {
      final farms = await _dataSource.getFarms();
      return (farms: farms, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          farms: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        farms: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to load farms',
        ),
      );
    } catch (e) {
      return (farms: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({FarmModel? farm, Failure? failure})> getFarm(int id) async {
    try {
      final farm = await _dataSource.getFarm(id);
      return (farm: farm, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          farm: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        farm: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to load farm',
        ),
      );
    } catch (e) {
      return (farm: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({FarmModel? farm, Failure? failure})> createFarm({
    required String name,
    required String location,
    int? farmManager,
  }) async {
    try {
      final farm = await _dataSource.createFarm(
        name: name,
        location: location,
        farmManager: farmManager,
      );
      return (farm: farm, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          farm: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        farm: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to create farm',
        ),
      );
    } catch (e) {
      return (farm: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<({FarmModel? farm, Failure? failure})> updateFarm({
    required int id,
    String? name,
    String? location,
    int? farmManager,
  }) async {
    try {
      final farm = await _dataSource.updateFarm(
        id: id,
        name: name,
        location: location,
        farmManager: farmManager,
      );
      return (farm: farm, failure: null);
    } on DioException catch (e) {
      if (e.response == null) {
        return (
          farm: null,
          failure: const NetworkFailure(message: 'No internet connection'),
        );
      }
      return (
        farm: null,
        failure: ServerFailure(
          message: e.response?.data['detail'] ?? 'Failed to update farm',
        ),
      );
    } catch (e) {
      return (farm: null, failure: ServerFailure(message: e.toString()));
    }
  }

  Future<Failure?> deleteFarm(int id) async {
    try {
      await _dataSource.deleteFarm(id);
      return null;
    } on DioException catch (e) {
      if (e.response == null) {
        return const NetworkFailure(message: 'No internet connection');
      }
      return ServerFailure(
        message: e.response?.data['detail'] ?? 'Failed to delete farm',
      );
    } catch (e) {
      return ServerFailure(message: e.toString());
    }
  }
}
