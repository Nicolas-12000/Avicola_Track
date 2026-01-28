import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/offline_provider.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../data/models/inventory_item_model.dart';
import '../../data/inventory_datasource.dart';
import '../../domain/inventory_repository.dart';

// State
class InventoryState {
  final List<InventoryItemModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMoreData;
  final int? selectedFarmId;
  final Set<String> activeStockFilters; // Filtros de estado de stock activos
  final String? searchQuery; // Búsqueda por nombre

  InventoryState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMoreData = true,
    this.selectedFarmId,
    this.activeStockFilters = const {},
    this.searchQuery,
  });

  InventoryState copyWith({
    List<InventoryItemModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMoreData,
    int? selectedFarmId,
    Set<String>? activeStockFilters,
    String? searchQuery,
    bool clearSearchQuery = false,
  }) {
    return InventoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
      selectedFarmId: selectedFarmId ?? this.selectedFarmId,
      activeStockFilters: activeStockFilters ?? this.activeStockFilters,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }

  /// Items filtrados según filtros activos
  List<InventoryItemModel> get filteredItems {
    var result = items;

    // Filtrar por búsqueda
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      result = result.where((item) => 
        item.name.toLowerCase().contains(query) ||
        (item.description?.toLowerCase().contains(query) ?? false)
      ).toList();
    }

    // Filtrar por estado de stock
    if (activeStockFilters.isNotEmpty) {
      result = result.where((item) => 
        activeStockFilters.contains(item.stockStatusLabel)
      ).toList();
    }

    return result;
  }

  bool get hasActiveFilters => activeStockFilters.isNotEmpty || (searchQuery?.isNotEmpty ?? false);

  // Getters por estado de stock (ahora usando filteredItems)
  List<InventoryItemModel> get criticalItems =>
      filteredItems.where((i) => i.stockStatusLabel == 'out_of_stock').toList();

  List<InventoryItemModel> get lowStockItems =>
      filteredItems.where((i) => i.stockStatusLabel == 'low_stock').toList();

  List<InventoryItemModel> get warningItems =>
      filteredItems.where((i) => i.stockStatusLabel == 'warning').toList();

  List<InventoryItemModel> get normalItems =>
      filteredItems.where((i) => i.stockStatusLabel == 'normal' || i.stockStatusLabel == 'unknown').toList();

  List<InventoryItemModel> get alertItems =>
      items.where((i) => i.isAlert).toList();

  List<InventoryItemModel> get criticalThresholdItems =>
      items.where((i) => i.isCritical).toList();
}

// Notifier
class InventoryNotifier extends StateNotifier<InventoryState> {
  final InventoryRepository repository;

  InventoryNotifier(this.repository) : super(InventoryState());

  Future<void> loadInventoryItems({int? farmId, bool refresh = true}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 1,
        hasMoreData: true,
        selectedFarmId: farmId,
      );
    }

    final result = await repository.getInventoryItems(farmId: farmId);

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (items) => state = state.copyWith(
        items: items,
        isLoading: false,
        error: null,
        hasMoreData: items.length >= 30,
      ),
    );
  }

  Future<void> loadMoreItems() async {
    if (state.isLoadingMore || !state.hasMoreData) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;

    final result = await repository.getInventoryItems(
      farmId: state.selectedFarmId,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoadingMore: false, error: failure.message),
      (newItems) {
        final allItems = [...state.items, ...newItems];
        state = state.copyWith(
          items: allItems,
          isLoadingMore: false,
          currentPage: nextPage,
          hasMoreData: newItems.length >= 30,
          error: null,
        );
      },
    );
  }

  void filterByFarm(int? farmId) {
    loadInventoryItems(farmId: farmId, refresh: true);
  }

  /// Actualizar filtros de estado de stock
  void setStockFilters(Set<String> filters) {
    state = state.copyWith(activeStockFilters: filters);
  }

  /// Toggle un filtro de estado de stock
  void toggleStockFilter(String filter) {
    final newFilters = Set<String>.from(state.activeStockFilters);
    if (newFilters.contains(filter)) {
      newFilters.remove(filter);
    } else {
      newFilters.add(filter);
    }
    state = state.copyWith(activeStockFilters: newFilters);
  }

  /// Actualizar búsqueda por nombre
  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearchQuery: query == null || query.isEmpty,
    );
  }

  /// Limpiar todos los filtros
  void clearFilters() {
    state = state.copyWith(
      activeStockFilters: {},
      clearSearchQuery: true,
    );
  }

  Future<void> createInventoryItem({
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
    final result = await repository.createInventoryItem(
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

    result.fold((failure) => state = state.copyWith(error: failure.message), (
      item,
    ) {
      state = state.copyWith(items: [...state.items, item], error: null);
    });
  }

  Future<void> updateInventoryItem({
    required int id,
    String? name,
    String? description,
    String? unit,
    double? minimumStock,
    int? alertThresholdDays,
    int? criticalThresholdDays,
  }) async {
    final result = await repository.updateInventoryItem(
      id: id,
      name: name,
      description: description,
      unit: unit,
      minimumStock: minimumStock,
      alertThresholdDays: alertThresholdDays,
      criticalThresholdDays: criticalThresholdDays,
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
  final offline = ref.watch(offlineSyncServiceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return InventoryDataSource(dio, offline, connectivity);
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
