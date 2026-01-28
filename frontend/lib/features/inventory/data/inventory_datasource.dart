import 'package:dio/dio.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/offline_sync_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/errors/offline_exceptions.dart';

class InventoryDataSource {
  final Dio dio;
  final OfflineSyncService _offlineService;
  final ConnectivityService _connectivityService;

  InventoryDataSource(this.dio, this._offlineService, this._connectivityService);

  Future<List<InventoryItemModel>> getInventoryItems({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get(
        ApiConstants.inventory,
        queryParameters: queryParams,
      );

      final responseData = response.data;
      final List<dynamic> data = responseData is Map && responseData.containsKey('results')
          ? responseData['results']
          : responseData;
      try {
        final key = 'inventory_${farmId ?? 'all'}';
        await _offlineService.cacheData(key, data);
      } catch (_) {}

      return data
          .map(
            (json) => InventoryItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load inventory',
        stackTrace: stackTrace,
      );

      try {
        final key = 'inventory_${farmId ?? 'all'}';
        final cached = _offlineService.getCachedData(key);
        if (cached != null && cached is List) {
          return cached
              .map((json) => InventoryItemModel.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      } catch (_) {}

      rethrow;
    }
  }

  Future<InventoryItemModel> getInventoryItem(int id) async {
    try {
      final response = await dio.get(ApiConstants.inventoryDetail(id));
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load inventory item',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<InventoryItemModel> createInventoryItem({
    required int farmId,
    required String name,
    String? description,
    required String unit,
    required double currentStock,
    required double minimumStock,
    int? shedId,
    int alertThresholdDays = 5,
    int criticalThresholdDays = 2,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.inventory,
        data: {
          'farm': farmId,
          'name': name,
          'description': description ?? '',
          'unit': unit,
          'current_stock': currentStock,
          'minimum_stock': minimumStock,
          'shed': shedId,
          'alert_threshold_days': alertThresholdDays,
          'critical_threshold_days': criticalThresholdDays,
        },
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        final data = {
          'farm': farmId,
          'name': name,
          'description': description ?? '',
          'unit': unit,
          'current_stock': currentStock,
          'minimum_stock': minimumStock,
          'shed': shedId,
          'alert_threshold_days': alertThresholdDays,
          'critical_threshold_days': criticalThresholdDays,
        };
        await _offlineService.addToQueue(
          endpoint: ApiConstants.inventory,
          method: 'POST',
          data: data,
          entityType: 'inventory_item',
        );
        throw OfflineQueuedException('Inventario encolado para sincronizar');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to create inventory item',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<InventoryItemModel> updateInventoryItem({
    required int id,
    String? name,
    String? description,
    String? unit,
    double? minimumStock,
    int? alertThresholdDays,
    int? criticalThresholdDays,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (unit != null) data['unit'] = unit;
    if (minimumStock != null) data['minimum_stock'] = minimumStock;
    if (alertThresholdDays != null) {
      data['alert_threshold_days'] = alertThresholdDays;
    }
    if (criticalThresholdDays != null) {
      data['critical_threshold_days'] = criticalThresholdDays;
    }
    try {
      final response = await dio.patch(
        ApiConstants.inventoryDetail(id),
        data: data,
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.inventoryDetail(id),
          method: 'PATCH',
          data: data,
          entityType: 'inventory_item',
          localId: id,
        );
        throw OfflineQueuedException('Actualización en inventario encolada');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to update inventory item',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await dio.delete(ApiConstants.inventoryDetail(id));
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.inventoryDetail(id),
          method: 'DELETE',
          data: {'id': id},
          entityType: 'inventory_item',
          localId: id,
        );
        throw OfflineQueuedException('Eliminación en inventario encolada');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to delete inventory item',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<InventoryItemModel> adjustStock({
    required int id,
    required double quantityChange,
    required String reason,
  }) async {
    try {
      final response = await dio.post(
        '${ApiConstants.inventoryDetail(id)}adjust-stock/',
        data: {'quantity_change': quantityChange, 'reason': reason},
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: '${ApiConstants.inventoryDetail(id)}adjust-stock/',
          method: 'POST',
          data: {'quantity_change': quantityChange, 'reason': reason},
          entityType: 'inventory_adjustment',
          localId: id,
        );
        throw OfflineQueuedException('Ajuste de stock encolado');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to adjust stock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getStockAlerts({int? warehouseId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (warehouseId != null) {
        queryParams['warehouse'] = warehouseId;
      }

      final response = await dio.get(
        ApiConstants.inventoryStockAlerts,
        queryParameters: queryParams,
      );
      
      final responseData = response.data;
      final List<dynamic> data = responseData is Map && responseData.containsKey('results')
          ? responseData['results']
          : responseData;
      return List<Map<String, dynamic>>.from(data);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load stock alerts',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> bulkUpdateStock({
    required List<Map<String, dynamic>> updates,
  }) async {
    try {
      await dio.post(
        ApiConstants.inventoryBulkUpdateStock,
        data: {'updates': updates},
      );
    } catch (e, stackTrace) {
      final isConnected = _connectivityService.currentState.isConnected;
      if (!isConnected) {
        await _offlineService.addToQueue(
          endpoint: ApiConstants.inventoryBulkUpdateStock,
          method: 'POST',
          data: {'updates': updates},
          entityType: 'inventory_bulk',
        );
        throw OfflineQueuedException('Actualización masiva encolada');
      }

      ErrorHandler.logError(
        e,
        context: 'Failed to bulk update stock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addStock({
    required int itemId,
    required double quantity,
    required double unitCost,
    DateTime? expirationDate,
    String? batchNumber,
    String? supplier,
    String? notes,
  }) async {
    try {
      final data = {
        'item': itemId,
        'quantity': quantity,
        'unit_cost': unitCost,
        if (expirationDate != null)
          'expiration_date': expirationDate.toIso8601String().split('T')[0],
        if (batchNumber != null) 'batch_number': batchNumber,
        if (supplier != null) 'supplier': supplier,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        ApiConstants.inventoryAddStock(itemId),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to add stock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> consumeFifo({
    required int itemId,
    required double quantity,
    required int usedBy,
    String usedByType = 'Flock',
    String? notes,
  }) async {
    try {
      final data = {
        'item': itemId,
        'quantity': quantity,
        'used_by': usedBy,
        'used_by_type': usedByType,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.post(
        ApiConstants.inventoryConsumeFifo(itemId),
        data: data,
      );
      return response.data as Map<String, dynamic>;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to consume stock',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFifoBatches({
    required int itemId,
  }) async {
    try {
      final response = await dio.get(ApiConstants.inventoryFifoBatches(itemId));
      return List<Map<String, dynamic>>.from(response.data as List);
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        context: 'Failed to load FIFO batches',
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
