import 'package:dio/dio.dart';
import '../../../data/models/shed_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';

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
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final data = {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        };

        await _offlineService.addToQueue(
          endpoint: ApiConstants.sheds,
          method: 'POST',
          data: data,
          entityType: 'shed',
        );

        final tempId = -DateTime.now().millisecondsSinceEpoch;
        final placeholder = ShedModel(
          id: tempId,
          name: name,
          farm: farmId,
          farmName: null,
          capacity: capacity,
          assignedWorker: assignedWorkerId,
          assignedWorkerName: null,
          currentFlock: null,
          currentOccupancy: 0,
          isOccupied: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          final key = 'sheds_$farmId';
          final cached = _offlineService.getCachedData(key);
          if (cached != null && cached is List) {
            final List updated = List.from(cached);
            updated.add(placeholder.toJson());
            await _offlineService.cacheData(key, updated);
          } else {
            await _offlineService.cacheData(key, [placeholder.toJson()]);
          }
        } catch (_) {}

        return placeholder;
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
        final data = {
          'name': name,
          'farm': farmId,
          'capacity': capacity,
          if (assignedWorkerId != null) 'assigned_worker': assignedWorkerId,
        };

        await _offlineService.addToQueue(
          endpoint: ApiConstants.shedDetail(id),
          method: 'PUT',
          data: data,
          entityType: 'shed',
          localId: id,
        );

        try {
          final key = 'sheds_$farmId';
          final cached = _offlineService.getCachedData(key);
          if (cached != null && cached is List) {
            final List updated = cached.map((e) => Map<String, dynamic>.from(e)).toList();
            var changed = false;
            for (var i = 0; i < updated.length; i++) {
              final map = updated[i];
              if (map['id'] == id) {
                map['name'] = name;
                map['capacity'] = capacity;
                if (assignedWorkerId != null) map['assigned_worker'] = assignedWorkerId;
                map['updated_at'] = DateTime.now().toIso8601String();
                updated[i] = map;
                changed = true;
                break;
              }
            }
            if (changed) await _offlineService.cacheData(key, updated);
          }
        } catch (_) {}

        return ShedModel(
          id: id,
          name: name,
          farm: farmId,
          farmName: null,
          capacity: capacity,
          assignedWorker: assignedWorkerId,
          assignedWorkerName: null,
          currentFlock: null,
          currentOccupancy: 0,
          isOccupied: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
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

        // Remove from cached lists so UI reflects deletion immediately
        try {
            final key = 'sheds_all';
          final cached = _offlineService.getCachedData(key);
          if (cached != null && cached is List) {
            final updated = cached.where((e) {
              try {
                final map = Map<String, dynamic>.from(e);
                return map['id'] != id;
              } catch (_) {
                return true;
              }
            }).toList();
            await _offlineService.cacheData(key, updated);
          }
        } catch (_) {}

        return;
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
