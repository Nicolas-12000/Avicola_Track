import 'package:dio/dio.dart';
import '../../../data/models/shed_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/offline_exceptions.dart';

class ShedDataSource {
  final Dio dio;
  final OfflineSyncService _offlineService;
  final ConnectivityService _connectivityService;

  ShedDataSource(this.dio, this._offlineService, this._connectivityService);

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

      // Cache response for offline
      try {
        final key = 'sheds_${farmId ?? 'all'}';
        await _offlineService.cacheData(key, data);
      } catch (_) {}
      return data
          .map((json) => ShedModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load sheds',
        stackTrace: stackTrace,
      );

      // Fallback to cached data when available
      try {
        final key = 'sheds_${farmId ?? 'all'}';
        final cached = _offlineService.getCachedData(key);
        if (cached != null && cached is List) {
          return cached
              .map((json) => ShedModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      } catch (_) {}

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
      // If no connectivity, enqueue operation for later sync
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final endpoint = ApiConstants.sheds;
        final method = 'POST';
        final data = {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        };

        await _offlineService.addToQueue(
          endpoint: endpoint,
          method: method,
          data: data,
          entityType: 'shed',
        );

        throw OfflineQueuedException('Operación encolada: se sincronizará cuando haya conexión');
      }

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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final endpoint = ApiConstants.shedDetail(id);
        final method = 'PUT';
        final data = {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        };

        await _offlineService.addToQueue(
          endpoint: endpoint,
          method: method,
          data: data,
          entityType: 'shed',
          localId: id,
        );

        throw OfflineQueuedException('Actualización encolada: se sincronizará cuando haya conexión');
      }

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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final endpoint = ApiConstants.shedDetail(id);
        final method = 'DELETE';
        final data = {'id': id};

        await _offlineService.addToQueue(
          endpoint: endpoint,
          method: method,
          data: data,
          entityType: 'shed',
          localId: id,
        );

        throw OfflineQueuedException('Eliminación encolada: se sincronizará cuando haya conexión');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to delete shed',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
