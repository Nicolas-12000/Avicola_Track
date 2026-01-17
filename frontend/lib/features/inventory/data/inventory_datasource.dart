import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/inventory_item_model.dart';
import '../../../core/utils/error_handler.dart';

class InventoryDataSource {
  final Dio dio;

  InventoryDataSource(this.dio);

  Future<List<InventoryItemModel>> getInventoryItems({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get(
        ApiConstants.inventory,
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
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
    required String category,
    required String unit,
    required double currentStock,
    required double minimumStock,
    double? averageConsumption,
    DateTime? expirationDate,
    String? supplier,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.inventory,
        data: {
          'farm': farmId,
          'name': name,
          'category': category,
          'unit': unit,
          'current_stock': currentStock,
          'minimum_stock': minimumStock,
          'average_consumption': averageConsumption,
          'expiration_date': expirationDate?.toIso8601String().split('T')[0],
          'supplier': supplier,
        },
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
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
    String? category,
    String? unit,
    double? currentStock,
    double? minimumStock,
    double? averageConsumption,
    DateTime? expirationDate,
    String? supplier,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (category != null) data['category'] = category;
      if (unit != null) data['unit'] = unit;
      if (currentStock != null) data['current_stock'] = currentStock;
      if (minimumStock != null) data['minimum_stock'] = minimumStock;
      if (averageConsumption != null) {
        data['average_consumption'] = averageConsumption;
      }
      if (expirationDate != null) {
        data['expiration_date'] = expirationDate.toIso8601String().split(
          'T',
        )[0];
      }
      if (supplier != null) data['supplier'] = supplier;

      final response = await dio.patch(
        ApiConstants.inventoryDetail(id),
        data: data,
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e, stackTrace) {
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
      return List<Map<String, dynamic>>.from(response.data as List);
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
