import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/farm_model.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/offline_exceptions.dart';

class FarmDataSource {
  final Dio _dio;
  final OfflineSyncService _offlineService;
  final ConnectivityService _connectivityService;

  FarmDataSource(this._dio, this._offlineService, this._connectivityService);

  /// Obtener todas las granjas
  Future<List<FarmModel>> getFarms() async {
    try {
      final response = await _dio.get(ApiConstants.farms);

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map && responseData.containsKey('results')
            ? responseData['results']
            : responseData;
        // cache
        try {
          await _offlineService.cacheData('farms_all', data);
        } catch (_) {}

        return data.map((json) => FarmModel.fromJson(json)).toList();
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load farms',
      );
    } on DioException {
      // Try cached fallback
      try {
        final cached = _offlineService.getCachedData('farms_all');
        if (cached != null && cached is List) {
          return cached.map((json) => FarmModel.fromJson(Map<String, dynamic>.from(json))).toList();
        }
      } catch (_) {}

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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final id = await _offlineService.addToQueue(
          endpoint: ApiConstants.farms,
          method: 'POST',
          data: {
            'name': name,
            'location': location,
            if (farmManager != null) 'farm_manager': farmManager,
          },
          entityType: 'farm',
        );

        throw OfflineQueuedException('Creación de granja encolada: $id');
      }

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
    final data = <String, dynamic>{};
    try {
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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.farmDetail(id),
          method: 'PATCH',
          data: data,
          entityType: 'farm',
          localId: id,
        );

        throw OfflineQueuedException('Actualización de granja encolada');
      }

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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.farmDetail(id),
          method: 'DELETE',
          data: {'id': id},
          entityType: 'farm',
          localId: id,
        );

        throw OfflineQueuedException('Eliminación de granja encolada');
      }

      rethrow;
    }
  }

  /// Obtener galpones de una granja
  Future<List<dynamic>> getFarmSheds(int farmId) async {
    try {
      final response = await _dio.get(ApiConstants.farmSheds(farmId));

      if (response.statusCode == 200) {
        final responseData = response.data;
        final List<dynamic> data = responseData is Map && responseData.containsKey('results')
            ? responseData['results']
            : responseData;
        return data;
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
