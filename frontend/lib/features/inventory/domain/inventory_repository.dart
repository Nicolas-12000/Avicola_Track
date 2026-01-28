import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../data/models/inventory_item_model.dart';
import '../data/inventory_datasource.dart';

class InventoryRepository {
  final InventoryDataSource dataSource;

  InventoryRepository(this.dataSource);

  Future<Either<Failure, List<InventoryItemModel>>> getInventoryItems({
    int? farmId,
  }) async {
    try {
      final items = await dataSource.getInventoryItems(farmId: farmId);
      return Right(items);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to load inventory: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, InventoryItemModel>> getInventoryItem(int id) async {
    try {
      final item = await dataSource.getInventoryItem(id);
      return Right(item);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to load item: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, InventoryItemModel>> createInventoryItem({
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
      final item = await dataSource.createInventoryItem(
        farmId: farmId,
        name: name,
        description: description,
        unit: unit,
        currentStock: currentStock,
        minimumStock: minimumStock,
        shedId: shedId,
        alertThresholdDays: alertThresholdDays,
        criticalThresholdDays: criticalThresholdDays,
      );
      return Right(item);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to create item: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, InventoryItemModel>> updateInventoryItem({
    required int id,
    String? name,
    String? description,
    String? unit,
    double? minimumStock,
    int? alertThresholdDays,
    int? criticalThresholdDays,
  }) async {
    try {
      final item = await dataSource.updateInventoryItem(
        id: id,
        name: name,
        description: description,
        unit: unit,
        minimumStock: minimumStock,
        alertThresholdDays: alertThresholdDays,
        criticalThresholdDays: criticalThresholdDays,
      );
      return Right(item);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to update item: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, void>> deleteInventoryItem(int id) async {
    try {
      await dataSource.deleteInventoryItem(id);
      return Right(null);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to delete item: ${e.toString()}'),
      );
    }
  }

  Future<Either<Failure, InventoryItemModel>> adjustStock({
    required int id,
    required double quantityChange,
    required String reason,
  }) async {
    try {
      final item = await dataSource.adjustStock(
        id: id,
        quantityChange: quantityChange,
        reason: reason,
      );
      return Right(item);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to adjust stock: ${e.toString()}'),
      );
    }
  }
}
