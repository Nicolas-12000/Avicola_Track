import 'package:dio/dio.dart';
import '../../../data/models/inventory_item_model.dart';

class InventoryDataSource {
  final Dio dio;

  InventoryDataSource(this.dio);

  Future<List<InventoryItemModel>> getInventoryItems({int? farmId}) async {
    try {
      final queryParams = farmId != null ? {'farm': farmId} : null;
      final response = await dio.get(
        '/inventory/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => InventoryItemModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load inventory: $e');
    }
  }

  Future<InventoryItemModel> getInventoryItem(int id) async {
    try {
      final response = await dio.get('/inventory/$id/');
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to load inventory item: $e');
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
        '/inventory/',
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
    } catch (e) {
      throw Exception('Failed to create inventory item: $e');
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
      if (averageConsumption != null)
        data['average_consumption'] = averageConsumption;
      if (expirationDate != null)
        data['expiration_date'] = expirationDate.toIso8601String().split(
          'T',
        )[0];
      if (supplier != null) data['supplier'] = supplier;

      final response = await dio.patch('/inventory/$id/', data: data);
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to update inventory item: $e');
    }
  }

  Future<void> deleteInventoryItem(int id) async {
    try {
      await dio.delete('/inventory/$id/');
    } catch (e) {
      throw Exception('Failed to delete inventory item: $e');
    }
  }

  Future<InventoryItemModel> adjustStock({
    required int id,
    required double quantityChange,
    required String reason,
  }) async {
    try {
      final response = await dio.post(
        '/inventory/$id/adjust-stock/',
        data: {'quantity_change': quantityChange, 'reason': reason},
      );
      return InventoryItemModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to adjust stock: $e');
    }
  }
}
