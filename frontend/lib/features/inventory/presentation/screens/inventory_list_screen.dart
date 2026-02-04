import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../data/models/inventory_item_model.dart';
import '../providers/inventory_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class InventoryListScreen extends ConsumerStatefulWidget {
  final int? farmId;

  const InventoryListScreen({this.farmId, super.key});

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      final userFarmId = authState.user?.assignedFarm;
      final isAdmin =
          authState.user?.role == 'admin' ||
          authState.user?.role == 'superadmin';

      // Si es administrador de granja, solo mostrar su granja
      final farmIdToLoad = isAdmin ? widget.farmId : userFarmId;

      ref
          .read(inventoryProvider.notifier)
          .loadInventoryItems(farmId: farmIdToLoad);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(inventoryProvider.notifier).loadMoreItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Inventario'),
        backgroundColor: AppColors.primary,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterDialog(),
              ),
              if (inventoryState.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (inventoryState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: () {
                ref.read(inventoryProvider.notifier).clearFilters();
              },
              tooltip: 'Limpiar filtros',
            ),
        ],
      ),
      body: inventoryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventoryState.error != null
          ? Center(child: Text('Error: ${inventoryState.error}'))
          : inventoryState.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No hay items en inventario',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(inventoryProvider.notifier)
                  .loadInventoryItems(farmId: inventoryState.selectedFarmId),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Cards
                  _buildStatsRow(inventoryState),
                  const SizedBox(height: 16),

                  // Farm Filter (solo para admins)
                  _buildFarmFilter(),
                  const SizedBox(height: 16),

                  // Critical Items
                  if (inventoryState.criticalItems.isNotEmpty) ...[
                    _buildSectionHeader('Crítico', Colors.red),
                    ...inventoryState.criticalItems.map(
                      (item) => _buildInventoryCard(item),
                    ),
                  ],

                  // Low Stock Items
                  if (inventoryState.lowStockItems.isNotEmpty) ...[
                    _buildSectionHeader('Stock Bajo', Colors.orange),
                    ...inventoryState.lowStockItems.map(
                      (item) => _buildInventoryCard(item),
                    ),
                  ],

                  // Warning Items
                  if (inventoryState.warningItems.isNotEmpty) ...[
                    _buildSectionHeader('Advertencia', Colors.amber),
                    ...inventoryState.warningItems.map(
                      (item) => _buildInventoryCard(item),
                    ),
                  ],

                  // Normal Items
                  if (inventoryState.normalItems.isNotEmpty) ...[
                    _buildSectionHeader('Normal', Colors.green),
                    ...inventoryState.normalItems.map(
                      (item) => _buildInventoryCard(item),
                    ),
                  ],

                  // Loading indicator at bottom
                  if (inventoryState.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // End of list indicator
                  if (!inventoryState.hasMoreData &&
                      inventoryState.items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No hay más items para mostrar',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInventoryDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsRow(InventoryState state) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total',
            state.items.length.toString(),
            Icons.inventory_2,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Crítico',
            state.criticalItems.length.toString(),
            Icons.warning,
            Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Bajo Stock',
            state.lowStockItems.length.toString(),
            Icons.trending_down,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Alerta',
            state.alertItems.length.toString(),
            Icons.schedule,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmFilter() {
    final authState = ref.watch(authProvider);
    final isAdmin =
        authState.user?.role == 'admin' || authState.user?.role == 'superadmin';

    // Si no es admin, no mostrar el filtro
    if (!isAdmin) return const SizedBox.shrink();

    final farmsState = ref.watch(farmsProvider);
    final inventoryState = ref.watch(inventoryProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.filter_alt, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: inventoryState.selectedFarmId,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Granja',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas las granjas'),
                  ),
                  ...farmsState.farms.map((farm) {
                    return DropdownMenuItem<int?>(
                      value: farm.id,
                      child: Text(farm.name),
                    );
                  }),
                ],
                onChanged: (farmId) {
                  ref.read(inventoryProvider.notifier).filterByFarm(farmId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItemModel item) {
    final statusColor = _getStatusColor(item.stockStatusLabel);
    final stockPercentage = (item.currentStock / item.minimumStock * 100).clamp(
      0,
      200,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showInventoryDialog(item: item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description ?? 'Sin descripción',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(item.stockStatusLabel),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Stock Actual: ${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Mínimo: ${item.minimumStock.toStringAsFixed(1)} ${item.unit}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (stockPercentage / 100).clamp(0, 1),
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ),

              // Additional Info
              const SizedBox(height: 12),
              Row(
                children: [
                  if (item.daysUntilEmpty != null) ...[
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${item.daysUntilEmpty!.toStringAsFixed(0)} días restantes',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (item.isCritical) ...[
                    const Icon(
                      Icons.error,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Crítico',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else if (item.isAlert) ...[
                    const Icon(
                      Icons.warning,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Alerta',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showAdjustStockDialog(item, isAdd: false),
                    icon: const Icon(Icons.remove_circle_outline, size: 18),
                    label: const Text('Consumir'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _showAdjustStockDialog(item, isAdd: true),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Agregar'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.red,
                    onPressed: () => _confirmDelete(item),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'out_of_stock':
        return Colors.red;
      case 'critical':
        return Colors.red;
      case 'low_stock':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      case 'normal':
      default:
        return Colors.green;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'out_of_stock':
        return 'Sin Stock';
      case 'critical':
        return 'Crítico';
      case 'low_stock':
        return 'Bajo';
      case 'warning':
        return 'Alerta';
      case 'normal':
      default:
        return 'Normal';
    }
  }

  void _showInventoryDialog({InventoryItemModel? item}) {
    final isEdit = item != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name);
    final descriptionController = TextEditingController(text: item?.description);
    final unitController = TextEditingController(text: item?.unit);
    final currentStockController = TextEditingController(
      text: item?.currentStock.toString(),
    );
    final minimumStockController = TextEditingController(
      text: item?.minimumStock.toString(),
    );

    int? selectedFarmId = item?.farmId ?? widget.farmId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Editar Item' : 'Nuevo Item',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Farm Selector (solo si no está filtrado)
                  if (widget.farmId == null)
                    Consumer(
                      builder: (context, ref, _) {
                        final farmsState = ref.watch(farmsProvider);
                        return DropdownButtonFormField<int>(
                          initialValue: selectedFarmId,
                          decoration: const InputDecoration(
                            labelText: 'Granja',
                            border: OutlineInputBorder(),
                          ),
                          items: farmsState.farms
                              .map(
                                (farm) => DropdownMenuItem(
                                  value: farm.id,
                                  child: Text(farm.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => selectedFarmId = value,
                          validator: (value) =>
                              value == null ? 'Requerido' : null,
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: unitController,
                    decoration: const InputDecoration(
                      labelText: 'Unidad (KG, TON, BAG, LB)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: currentStockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Actual',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: !isEdit, // No editable en modo edit
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Requerido';
                            if (double.tryParse(value!) == null) {
                              return 'Número inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: minimumStockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Mínimo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Requerido';
                            if (double.tryParse(value!) == null) {
                              return 'Número inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            if (isEdit) {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .updateInventoryItem(
                                    id: item.id,
                                    name: nameController.text,
                                    description: descriptionController.text.isNotEmpty
                                        ? descriptionController.text
                                        : null,
                                    unit: unitController.text,
                                    minimumStock: double.parse(
                                      minimumStockController.text,
                                    ),
                                  );
                            } else {
                              ref
                                  .read(inventoryProvider.notifier)
                                  .createInventoryItem(
                                    farmId: selectedFarmId!,
                                    name: nameController.text,
                                    description: descriptionController.text.isNotEmpty
                                        ? descriptionController.text
                                        : null,
                                    unit: unitController.text,
                                    currentStock: double.parse(
                                      currentStockController.text,
                                    ),
                                    minimumStock: double.parse(
                                      minimumStockController.text,
                                    ),
                                  );
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: Text(isEdit ? 'Guardar' : 'Crear'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAdjustStockDialog(InventoryItemModel item, {required bool isAdd}) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isAdd ? 'Agregar Stock' : 'Consumir Stock'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Item: ${item.name}'),
              Text('Stock actual: ${item.currentStock} ${item.unit}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: const OutlineInputBorder(),
                  suffixText: item.unit,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Requerido';
                  final qty = double.tryParse(value!);
                  if (qty == null || qty <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final quantity = double.parse(quantityController.text);
                ref
                    .read(inventoryProvider.notifier)
                    .adjustStock(
                      id: item.id,
                      quantityChange: isAdd ? quantity : -quantity,
                      reason: reasonController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: Text(isAdd ? 'Agregar' : 'Consumir'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text('¿Eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(inventoryProvider.notifier).deleteInventoryItem(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final inventoryState = ref.read(inventoryProvider);
    Set<String> selectedFilters = Set.from(inventoryState.activeStockFilters);
    String searchQuery = inventoryState.searchQuery ?? '';
    final searchController = TextEditingController(text: searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtrar Inventario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            selectedFilters.clear();
                            searchController.clear();
                            searchQuery = '';
                          });
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Búsqueda por nombre
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por nombre',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setSheetState(() {
                                  searchController.clear();
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setSheetState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Filtros por estado de stock
                  const Text(
                    'Estado de Stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Sin Stock',
                        value: 'out_of_stock',
                        color: Colors.red,
                        isSelected: selectedFilters.contains('out_of_stock'),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedFilters.add('out_of_stock');
                            } else {
                              selectedFilters.remove('out_of_stock');
                            }
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Crítico',
                        value: 'critical',
                        color: Colors.red,
                        isSelected: selectedFilters.contains('critical'),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedFilters.add('critical');
                            } else {
                              selectedFilters.remove('critical');
                            }
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Stock Bajo',
                        value: 'low_stock',
                        color: Colors.orange,
                        isSelected: selectedFilters.contains('low_stock'),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedFilters.add('low_stock');
                            } else {
                              selectedFilters.remove('low_stock');
                            }
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Advertencia',
                        value: 'warning',
                        color: Colors.amber,
                        isSelected: selectedFilters.contains('warning'),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedFilters.add('warning');
                            } else {
                              selectedFilters.remove('warning');
                            }
                          });
                        },
                      ),
                      _buildFilterChip(
                        label: 'Normal',
                        value: 'normal',
                        color: Colors.green,
                        isSelected: selectedFilters.contains('normal'),
                        onSelected: (selected) {
                          setSheetState(() {
                            if (selected) {
                              selectedFilters.add('normal');
                            } else {
                              selectedFilters.remove('normal');
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botón aplicar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(inventoryProvider.notifier).setStockFilters(selectedFilters);
                        ref.read(inventoryProvider.notifier).setSearchQuery(
                          searchQuery.isEmpty ? null : searchQuery,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color color,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.3),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.grey[300]!,
      ),
    );
  }
}
