import 'package:dio/dio.dart';
import '../../../data/models/shed_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';

class ShedDataSource {
  final Dio dio;

  ShedDataSource(this.dio);

  Future<List<ShedModel>> getSheds({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get(
        ApiConstants.sheds,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final List<dynamic> data = responseData is Map<String, dynamic> && responseData.containsKey('results')
          ? responseData['results'] as List<dynamic>
          : responseData as List<dynamic>;
      return data
          .map((json) => ShedModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load sheds',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ShedModel> getShed(int id) async {
    try {
      final response = await dio.get(ApiConstants.shedDetail(id));
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load shed',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ShedModel> createShed({
    required String name,
    required int farmId,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.sheds,
        data: {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        },
      );
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to create shed',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<ShedModel> updateShed({
    required int id,
    required String name,
    required int farmId,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    try {
      final response = await dio.put(
        ApiConstants.shedDetail(id),
        data: {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        },
      );
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to update shed',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteShed(int id) async {
    try {
      await dio.delete(ApiConstants.shedDetail(id));
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to delete shed',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
