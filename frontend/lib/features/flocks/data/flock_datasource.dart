import 'package:dio/dio.dart';
import '../../../data/models/flock_model.dart';
import '../../../data/models/weight_record_model.dart';
import '../../../data/models/mortality_record_model.dart';

class FlockDataSource {
  final Dio dio;

  FlockDataSource(this.dio);

  Future<List<FlockModel>> getFlocks({
    int? farmId,
    int? shedId,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (farmId != null) queryParams['farm'] = farmId;
      if (shedId != null) queryParams['shed'] = shedId;
      if (status != null) queryParams['status'] = status;

      final response = await dio.get('/flocks/', queryParameters: queryParams);

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => FlockModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load flocks: $e');
    }
  }

  Future<FlockModel> getFlock(int id) async {
    try {
      final response = await dio.get('/flocks/$id/');
      return FlockModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load flock: $e');
    }
  }

  Future<FlockModel> createFlock({
    required int shedId,
    required String breed,
    required int initialQuantity,
    required String gender,
    required DateTime arrivalDate,
    double? initialWeight,
    String? supplier,
  }) async {
    try {
      final response = await dio.post(
        '/flocks/',
        data: {
          'shed': shedId,
          'breed': breed,
          'initial_quantity': initialQuantity,
          'current_quantity': initialQuantity,
          'gender': gender,
          'arrival_date': arrivalDate.toIso8601String().split('T')[0],
          'initial_weight': initialWeight,
          'supplier': supplier,
          'status': 'Active',
        },
      );
      return FlockModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create flock: $e');
    }
  }

  Future<FlockModel> updateFlock({
    required int id,
    int? currentQuantity,
    double? currentWeight,
    String? status,
    DateTime? saleDate,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (currentQuantity != null) data['current_quantity'] = currentQuantity;
      if (currentWeight != null) data['current_weight'] = currentWeight;
      if (status != null) data['status'] = status;
      if (saleDate != null)
        data['sale_date'] = saleDate.toIso8601String().split('T')[0];

      final response = await dio.patch('/flocks/$id/', data: data);
      return FlockModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update flock: $e');
    }
  }

  Future<void> deleteFlock(int id) async {
    try {
      await dio.delete('/flocks/$id/');
    } catch (e) {
      throw Exception('Failed to delete flock: $e');
    }
  }

  // Weight Records
  Future<List<WeightRecordModel>> getWeightRecords(int flockId) async {
    try {
      final response = await dio.get(
        '/weight-records/',
        queryParameters: {'flock': flockId},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => WeightRecordModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load weight records: $e');
    }
  }

  Future<WeightRecordModel> createWeightRecord({
    required int flockId,
    required double averageWeight,
    required int sampleSize,
    required DateTime recordDate,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '/weight-records/',
        data: {
          'flock': flockId,
          'average_weight': averageWeight,
          'sample_size': sampleSize,
          'record_date': recordDate.toIso8601String().split('T')[0],
          'notes': notes,
        },
      );
      return WeightRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to create weight record: $e');
    }
  }

  // Mortality Records
  Future<List<MortalityRecordModel>> getMortalityRecords(int flockId) async {
    try {
      final response = await dio.get(
        '/mortality-records/',
        queryParameters: {'flock': flockId},
      );
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) =>
                MortalityRecordModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load mortality records: $e');
    }
  }

  Future<MortalityRecordModel> createMortalityRecord({
    required int flockId,
    required int quantity,
    required String cause,
    required DateTime recordDate,
    double? temperature,
    String? notes,
  }) async {
    try {
      final response = await dio.post(
        '/mortality-records/',
        data: {
          'flock': flockId,
          'quantity': quantity,
          'cause': cause,
          'record_date': recordDate.toIso8601String().split('T')[0],
          'temperature': temperature,
          'notes': notes,
        },
      );
      return MortalityRecordModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (e) {
      throw Exception('Failed to create mortality record: $e');
    }
  }
}
