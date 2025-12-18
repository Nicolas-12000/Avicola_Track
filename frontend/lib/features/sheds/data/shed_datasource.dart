import 'package:dio/dio.dart';
import '../../../data/models/shed_model.dart';

class ShedDataSource {
  final Dio dio;

  ShedDataSource(this.dio);

  Future<List<ShedModel>> getSheds({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get('/sheds/', queryParameters: queryParams);

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ShedModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sheds: $e');
    }
  }

  Future<ShedModel> getShed(int id) async {
    try {
      final response = await dio.get('/sheds/$id/');
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load shed: $e');
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
        '/sheds/',
        data: {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        },
      );
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create shed: $e');
    }
  }

  Future<ShedModel> updateShed({
    required int id,
    required String name,
    required int capacity,
    int? assignedWorkerId,
  }) async {
    try {
      final response = await dio.put(
        '/sheds/$id/',
        data: {
          'name': name,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        },
      );
      return ShedModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update shed: $e');
    }
  }

  Future<void> deleteShed(int id) async {
    try {
      await dio.delete('/sheds/$id/');
    } catch (e) {
      throw Exception('Failed to delete shed: $e');
    }
  }
}
