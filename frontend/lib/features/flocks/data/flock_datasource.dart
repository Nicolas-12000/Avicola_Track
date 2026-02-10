import 'package:dio/dio.dart';
import '../../../data/models/flock_model.dart';
import '../../../data/models/weight_record_model.dart';
import '../../../data/models/mortality_record_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/offline_exceptions.dart';

class FlockDataSource {
  final Dio dio;
  final OfflineSyncService _offlineService;
  final ConnectivityService _connectivityService;

  FlockDataSource(this.dio, this._offlineService, this._connectivityService);

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

      final response = await dio.get(
        ApiConstants.flocks,
        queryParameters: queryParams,
      );

      // Handle paginated response from Django REST Framework
      final responseData = response.data;
      final List<dynamic> data = responseData is Map<String, dynamic> && responseData.containsKey('results')
          ? responseData['results'] as List<dynamic>
          : responseData as List<dynamic>;
          
      // Cache for offline
      try {
        final key = 'flocks_${farmId ?? 'all'}_${shedId ?? 'all'}_${status ?? 'all'}';
        await _offlineService.cacheData(key, data);
      } catch (_) {}

      return data
          .map((json) => FlockModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load flocks',
        stackTrace: stackTrace,
      );

      // Fallback cache
      try {
        final key = 'flocks_${farmId ?? 'all'}_${shedId ?? 'all'}_${status ?? 'all'}';
        final cached = _offlineService.getCachedData(key);
        if (cached != null && cached is List) {
          return cached
              .map((json) => FlockModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      } catch (_) {}

      rethrow;
    }
  }

  Future<FlockModel> getFlock(int id) async {
    try {
      final response = await dio.get(ApiConstants.flockDetail(id));
      return FlockModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load flock',
        stackTrace: stackTrace,
      );
      rethrow;
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
    // Si ya sabemos que no hay conexión, evitamos esperar al timeout de Dio
    if (!_connectivityService.currentState.isConnected) {
      return _createFlockOffline(
        shedId: shedId,
        breed: breed,
        initialQuantity: initialQuantity,
        gender: gender,
        arrivalDate: arrivalDate,
        initialWeight: initialWeight,
        supplier: supplier,
      );
    }

    try {
      final response = await dio.post(
        ApiConstants.flocks,
        data: {
          'shed': shedId,
          'breed': breed,
          'initial_quantity': initialQuantity,
          'current_quantity': initialQuantity,
          'gender': gender,
          'arrival_date': arrivalDate.toIso8601String().split('T')[0],
          'initial_weight': initialWeight,
          'supplier': supplier ?? '', // backend no acepta null
          'status': 'ACTIVE', // backend choice
        },
      );
      if (response.statusCode == 201) {
        return FlockModel.fromJson(response.data as Map<String, dynamic>);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: response.data,
      );
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        return _createFlockOffline(
          shedId: shedId,
          breed: breed,
          initialQuantity: initialQuantity,
          gender: gender,
          arrivalDate: arrivalDate,
          initialWeight: initialWeight,
          supplier: supplier,
        );
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to create flock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<FlockModel> _createFlockOffline({
    required int shedId,
    required String breed,
    required int initialQuantity,
    required String gender,
    required DateTime arrivalDate,
    double? initialWeight,
    String? supplier,
  }) async {
    final data = {
      'shed': shedId,
      'breed': breed,
      'initial_quantity': initialQuantity,
      'current_quantity': initialQuantity,
      'gender': gender,
      'arrival_date': arrivalDate.toIso8601String().split('T')[0],
      'initial_weight': initialWeight,
      'supplier': supplier ?? '',
      'status': 'ACTIVE',
    };

    await _offlineService.addToQueue(
      endpoint: ApiConstants.flocks,
      method: 'POST',
      data: data,
      entityType: 'flock',
    );

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final placeholder = FlockModel(
      id: tempId,
      shedId: shedId,
      shedName: null,
      farmId: 0,
      farmName: null,
      breed: breed,
      initialQuantity: initialQuantity,
      currentQuantity: initialQuantity,
      initialWeight: initialWeight,
      currentWeight: null,
      gender: gender,
      arrivalDate: arrivalDate,
      saleDate: null,
      supplier: supplier ?? '',
      status: 'Pending',
      createdAt: DateTime.now(),
      updatedAt: null,
    );

    try {
      final key = 'flocks_all_${shedId}_all';
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

  Future<FlockModel> updateFlock({
    required int id,
    int? currentQuantity,
    double? currentWeight,
    String? status,
    DateTime? saleDate,
  }) async {
    // Short-circuit si sabemos que no hay conexión
    if (!_connectivityService.currentState.isConnected) {
      return _updateFlockOffline(
        id: id,
        currentQuantity: currentQuantity,
        currentWeight: currentWeight,
        status: status,
        saleDate: saleDate,
      );
    }

    try {
      final Map<String, dynamic> data = {};
      if (currentQuantity != null) data['current_quantity'] = currentQuantity;
      if (currentWeight != null) data['current_weight'] = currentWeight;
      if (status != null) data['status'] = status;
      if (saleDate != null) {
        data['sale_date'] = saleDate.toIso8601String().split('T')[0];
      }

      final response = await dio.patch(ApiConstants.flockDetail(id), data: data);
      return FlockModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        return _updateFlockOffline(
          id: id,
          currentQuantity: currentQuantity,
          currentWeight: currentWeight,
          status: status,
          saleDate: saleDate,
        );
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to update flock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<FlockModel> _updateFlockOffline({
    required int id,
    int? currentQuantity,
    double? currentWeight,
    String? status,
    DateTime? saleDate,
  }) async {
    final Map<String, dynamic> data = {};
    if (currentQuantity != null) data['current_quantity'] = currentQuantity;
    if (currentWeight != null) data['current_weight'] = currentWeight;
    if (status != null) data['status'] = status;
    if (saleDate != null) {
      data['sale_date'] = saleDate.toIso8601String().split('T')[0];
    }

    await _offlineService.addToQueue(
      endpoint: ApiConstants.flockDetail(id),
      method: 'PATCH',
      data: data,
      entityType: 'flock',
      localId: id,
    );

    // Update cached flocks so UI reflects changes immediately
    try {
      const candidates = <String>['flocks_all_all_all'];
      for (final key in candidates) {
        try {
          final cached = _offlineService.getCachedData(key);
          if (cached != null && cached is List) {
            final List updated = cached.map((e) => Map<String, dynamic>.from(e)).toList();
            var changed = false;
            for (var i = 0; i < updated.length; i++) {
              final map = updated[i];
              if (map['id'] == id) {
                data.forEach((k, v) => map[k] = v);
                map['status'] = 'Pending';
                updated[i] = map;
                changed = true;
                break;
              }
            }
            if (changed) await _offlineService.cacheData(key, updated);
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Return provisional flock model
    final provisional = FlockModel(
      id: id,
      shedId: data['shed'] ?? 0,
      shedName: null,
      farmId: data['farm'] ?? 0,
      farmName: null,
      breed: data['breed'] ?? '',
      initialQuantity: data['initial_quantity'] ?? 0,
      currentQuantity: data['current_quantity'] ?? data['initial_quantity'] ?? 0,
      initialWeight: (data['initial_weight'] is num) ? (data['initial_weight'] as num).toDouble() : null,
      currentWeight: null,
      gender: data['gender'] ?? 'Mixed',
      arrivalDate: DateTime.now(),
      saleDate: null,
      supplier: data['supplier'] ?? '',
      status: 'Pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return provisional;
  }

  Future<void> deleteFlock(int id) async {
    try {
      await dio.delete(ApiConstants.flockDetail(id));
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.flockDetail(id),
          method: 'DELETE',
          data: {'id': id},
          entityType: 'flock',
          localId: id,
        );

        // Remove from cached lists so UI reflects deletion immediately
        try {
          const candidates = <String>['flocks_all_all_all'];
          for (final key in candidates) {
            try {
              final cached = _offlineService.getCachedData(key);
              if (cached != null && cached is List) {
                final updated = cached.where((entry) {
                  try {
                    final map = Map<String, dynamic>.from(entry);
                    return map['id'] != id;
                  } catch (_) {
                    return true;
                  }
                }).toList();
                await _offlineService.cacheData(key, updated);
              }
            } catch (_) {}
          }
        } catch (_) {}

        return;
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to delete flock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Weight Records
  Future<List<WeightRecordModel>> getWeightRecords(int flockId) async {
    try {
      final response = await dio.get(
        ApiConstants.dailyWeights,
        queryParameters: {'flock': flockId},
      );
      
      final responseData = response.data;
      final List<dynamic> data = responseData is Map<String, dynamic> && responseData.containsKey('results')
          ? responseData['results'] as List<dynamic>
          : response.data as List<dynamic>;
      
      return data
          .map(
            (json) => WeightRecordModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load weight records',
        stackTrace: stackTrace,
      );
      rethrow;
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
        ApiConstants.dailyWeights,
        data: {
          'flock': flockId,
          'average_weight': averageWeight,
          'sample_size': sampleSize,
          'record_date': recordDate.toIso8601String().split('T')[0],
          'notes': notes,
        },
      );
      return WeightRecordModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final data = {
          'flock': flockId,
          'average_weight': averageWeight,
          'sample_size': sampleSize,
          'record_date': recordDate.toIso8601String().split('T')[0],
          'notes': notes,
        };
        await _offlineService.addToQueue(
          endpoint: ApiConstants.dailyWeights,
          method: 'POST',
          data: data,
          entityType: 'weight_record',
          localId: flockId,
        );
        throw OfflineQueuedException('Peso encolado para sincronizar');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to create weight record',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Mortality Records
  Future<List<MortalityRecordModel>> getMortalityRecords(int flockId) async {
    try {
      final response = await dio.get(
        ApiConstants.mortality,
        queryParameters: {'flock': flockId},
      );
      
      final responseData = response.data;
      final List<dynamic> data = responseData is Map<String, dynamic> && responseData.containsKey('results')
          ? responseData['results'] as List<dynamic>
          : response.data as List<dynamic>;
      
      return data
          .map(
            (json) =>
                MortalityRecordModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load mortality records',
        stackTrace: stackTrace,
      );
      rethrow;
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
        ApiConstants.mortality,
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
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final data = {
          'flock': flockId,
          'quantity': quantity,
          'cause': cause,
          'record_date': recordDate.toIso8601String().split('T')[0],
          'temperature': temperature,
          'notes': notes,
        };
        await _offlineService.addToQueue(
          endpoint: ApiConstants.mortality,
          method: 'POST',
          data: data,
          entityType: 'mortality_record',
          localId: flockId,
        );
        throw OfflineQueuedException('Mortalidad encolada para sincronizar');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to create mortality record',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDashboard({int? flockId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (flockId != null) {
        queryParams['flock_id'] = flockId;
      }

      final response = await dio.get(
        ApiConstants.flocksDashboard,
        queryParameters: queryParams,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load flock dashboard',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> importExcel({
    required String filePath,
    required String importType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'import_type': importType,
      });

      final response = await dio.post(
        ApiConstants.flocksImportExcel,
        data: formData,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to import Excel file',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBreedReferences() async {
    try {
      final response = await dio.get(ApiConstants.breedReferences);
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load breed references',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
