import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/farm_model.dart';

class FarmDataSource {
  final Dio _dio;

  FarmDataSource(this._dio);

  /// Obtener todas las granjas
  Future<List<FarmModel>> getFarms() async {
    try {
      final response = await _dio.get(ApiConstants.farms);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => FarmModel.fromJson(json)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load farms',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Obtener una granja por ID
  Future<FarmModel> getFarm(int id) async {
    try {
      final response = await _dio.get(ApiConstants.farmDetail(id));

      if (response.statusCode == 200) {
        return FarmModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load farm',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Crear una nueva granja
  Future<FarmModel> createFarm({
    required String name,
    required String location,
    int? farmManager,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.farms,
        data: {
          'name': name,
          'location': location,
          if (farmManager != null) 'farm_manager': farmManager,
        },
      );

      if (response.statusCode == 201) {
        return FarmModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to create farm',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Actualizar una granja
  Future<FarmModel> updateFarm({
    required int id,
    String? name,
    String? location,
    int? farmManager,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (location != null) data['location'] = location;
      if (farmManager != null) data['farm_manager'] = farmManager;

      final response = await _dio.patch(
        ApiConstants.farmDetail(id),
        data: data,
      );

      if (response.statusCode == 200) {
        return FarmModel.fromJson(response.data);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to update farm',
      );
    } on DioException {
      rethrow;
    }
  }

  /// Eliminar una granja
  Future<void> deleteFarm(int id) async {
    try {
      final response = await _dio.delete(ApiConstants.farmDetail(id));

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete farm',
        );
      }
    } on DioException {
      rethrow;
    }
  }

  /// Obtener galpones de una granja
  Future<List<dynamic>> getFarmSheds(int farmId) async {
    try {
      final response = await _dio.get(ApiConstants.farmSheds(farmId));

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load farm sheds',
      );
    } on DioException {
      rethrow;
    }
  }
}
