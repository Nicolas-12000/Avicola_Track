import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../data/models/inventory_item_model.dart';
import '../../data/inventory_datasource.dart';
import '../../domain/inventory_repository.dart';

// State
class InventoryState {
  final List<InventoryItemModel> items;
  final bool isLoading;
  final String? error;

  InventoryState({this.items = const [], this.isLoading = false, this.error});

  InventoryState copyWith({
    List<InventoryItemModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Getters por estado de stock
  List<InventoryItemModel> get criticalItems =>
      items.where((i) => i.stockStatus == 'out_of_stock').toList();

  List<InventoryItemModel> get lowStockItems =>
      items.where((i) => i.stockStatus == 'low_stock').toList();

  List<InventoryItemModel> get warningItems =>
      items.where((i) => i.stockStatus == 'warning').toList();

  List<InventoryItemModel> get normalItems =>
      items.where((i) => i.stockStatus == 'normal').toList();

  List<InventoryItemModel> get expiringItems =>
      items.where((i) => i.isExpiringSoon && !i.isExpired).toList();

  List<InventoryItemModel> get expiredItems =>
      items.where((i) => i.isExpired).toList();
}

// Notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository repository;

  InventoryNotifier(this.repository) : super(InventoryState());

  Future<void> loadInventoryItems({int? farmId}) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await repository.getInventoryItems(farmId: farmId);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) =>
          state = state.copyWith(items: items, isLoading: false, error: null),
    );
  }

  Future<void> createInventoryItem({
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
    final result = await repository.createInventoryItem(
      farmId: farmId,
      name: name,
      category: category,
      unit: unit,
      currentStock: currentStock,
      minimumStock: minimumStock,
      averageConsumption: averageConsumption,
      expirationDate: expirationDate,
      supplier: supplier,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      item,
    ) {
      state = state.copyWith(items: [...state.items, item], error: null);
    });
  }

  Future<void> updateInventoryItem({
    required int id,
    required String name,
    required String category,
    required String unit,
    required double minimumStock,
    double? averageConsumption,
    String? supplier,
  }) async {
    final result = await repository.updateInventoryItem(
      id: id,
      name: name,
      category: category,
      unit: unit,
      minimumStock: minimumStock,
      averageConsumption: averageConsumption,
      supplier: supplier,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      updatedItem,
    ) {
      final updatedItems = state.items.map((item) {
        return item.id == id ? updatedItem : item;
      }).toList();
      state = state.copyWith(items: updatedItems, error: null);
    });
  }

  Future<void> deleteInventoryItem(int id) async {
    final result = await repository.deleteInventoryItem(id);

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      _,
    ) {
      final updatedItems = state.items.where((item) => item.id != id).toList();
      state = state.copyWith(items: updatedItems, error: null);
    });
  }

  Future<void> adjustStock({
    required int id,
    required double quantityChange,
    required String reason,
  }) async {
    final result = await repository.adjustStock(
      id: id,
      quantityChange: quantityChange,
      reason: reason,
    );

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      updatedItem,
    ) {
      final updatedItems = state.items.map((item) {
        return item.id == id ? updatedItem : item;
      }).toList();
      state = state.copyWith(items: updatedItems, error: null);
    });
  }
}

// Providers
final inventoryDataSourceProvider = Provider<InventoryDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return InventoryDataSource(dio);
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final dataSource = ref.watch(inventoryDataSourceProvider);
  return InventoryRepository(dataSource);
});

final inventoryProvider =
    StateNotifierProvider<InventoryNotifier, InventoryState>((ref) {
      final repository = ref.watch(inventoryRepositoryProvider);
      return InventoryNotifier(repository);
    });
