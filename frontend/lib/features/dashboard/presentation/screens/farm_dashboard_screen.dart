import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/charts.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../sheds/presentation/providers/sheds_provider.dart';
import '../../../flocks/presentation/providers/flocks_provider.dart';
import '../../../inventory/presentation/providers/inventory_provider.dart';
import 'package:go_router/go_router.dart';

class FarmDashboardScreen extends ConsumerStatefulWidget {
  final int? farmId;

  const FarmDashboardScreen({this.farmId, super.key});

  @override
  ConsumerState<FarmDashboardScreen> createState() =>
      _FarmDashboardScreenState();
}

class _FarmDashboardScreenState extends ConsumerState<FarmDashboardScreen> {
  int? selectedFarmId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    selectedFarmId = widget.farmId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFarm();
    });
  }

  Future<void> _initializeFarm() async {
    // Cargar granjas si no están cargadas
    final farmsState = ref.read(farmsProvider);
    if (farmsState.farms.isEmpty && !farmsState.isLoading) {
      await ref.read(farmsProvider.notifier).loadFarms();
    }
    
    // Auto-seleccionar la primera granja si no hay farmId
    if (selectedFarmId == null) {
      final farms = ref.read(farmsProvider).farms;
      if (farms.isNotEmpty) {
        setState(() {
          selectedFarmId = farms.first.id;
        });
      }
    }
    
    _loadDashboardData();
  }

  void _loadDashboardData() {
    if (selectedFarmId != null) {
      ref.read(shedsProvider.notifier).loadSheds(farmId: selectedFarmId);
      ref.read(flocksProvider.notifier).loadFlocks(farmId: selectedFarmId);
      ref
          .read(inventoryProvider.notifier)
          .loadInventoryItems(farmId: selectedFarmId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmsState = ref.watch(farmsProvider);
    
    // Auto-seleccionar granja cuando se cargan (solo una vez)
    if (!_initialized && farmsState.farms.isNotEmpty && selectedFarmId == null) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedFarmId = farmsState.farms.first.id;
        });
        _loadDashboardData();
      });
    }
    final shedsState = ref.watch(shedsProvider);
    final flocksState = ref.watch(flocksProvider);
    final inventoryState = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Granja'),
        backgroundColor: AppColors.primary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: farmsState.farms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Farm Selector
                  if (farmsState.farms.length > 1)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedFarmId,
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar Granja',
                            border: InputBorder.none,
                          ),
                          items: farmsState.farms
                              .map(
                                (farm) => DropdownMenuItem(
                                  value: farm.id,
                                  child: Text(farm.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFarmId = value;
                            });
                            _loadDashboardData();
                          },
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // KPIs Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildKPICard(
                          'Galpones',
                          '${shedsState.sheds.length}',
                          Icons.home,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKPICard(
                          'Lotes Activos',
                          '${flocksState.activeFlocks.length}',
                          Icons.pets,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildKPICard(
                          'Ocupación',
                          _calculateOccupancy(shedsState.sheds),
                          Icons.pie_chart,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Estado de Lotes Section
                  _buildSectionHeader('Estado de Lotes', Icons.pets),
                  const SizedBox(height: 12),
                  _buildFlocksGrid(flocksState),

                  const SizedBox(height: 24),

                  // Gráfica de Ocupación Section
                  _buildSectionHeader('Ocupación de Galpones', Icons.pie_chart),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 280,
                        child: OccupancyPieChart(
                          occupiedSheds: shedsState.sheds
                              .where((s) => s.isOccupied)
                              .length,
                          totalSheds: shedsState.sheds.length,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Inventario Resumen Section
                  _buildSectionHeader('Inventario', Icons.inventory),
                  const SizedBox(height: 12),
                  _buildInventorySummary(inventoryState),

                  const SizedBox(height: 24),

                  // Galpones Section
                  _buildSectionHeader('Galpones', Icons.home),
                  const SizedBox(height: 12),
                  _buildShedsGrid(shedsState),
                ],
              ),
            ),
    );
  }

  Widget _buildKPICard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildFlocksGrid(FlocksState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.activeFlocks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No hay lotes activos',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: state.activeFlocks.length > 4 ? 4 : state.activeFlocks.length,
      itemBuilder: (context, index) {
        final flock = state.activeFlocks[index];
        final statusColor = flock.status == 'active'
            ? Colors.green
            : Colors.orange;

        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () => context.push('/flocks'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lote #${flock.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    flock.breed,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.pets, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${flock.initialQuantity} aves',
                        style: const TextStyle(fontSize: 12),
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

  Widget _buildInventorySummary(InventoryState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInventoryRow(
              'Crítico',
              state.criticalItems.length,
              Colors.red,
            ),
            const Divider(),
            _buildInventoryRow(
              'Stock Bajo',
              state.lowStockItems.length,
              Colors.orange,
            ),
            const Divider(),
            _buildInventoryRow(
              'Normal',
              state.normalItems.length,
              Colors.green,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/inventory'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver Inventario Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        Text(
          '$count items',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildShedsGrid(ShedsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sheds.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'No hay galpones registrados',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: state.sheds.length > 4 ? 4 : state.sheds.length,
      itemBuilder: (context, index) {
        final shed = state.sheds[index];
        final occupancyColor = shed.isOccupied ? Colors.green : Colors.grey;

        return Card(
          elevation: 2,
          child: InkWell(
            onTap: () => context.push('/sheds'),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        shed.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        shed.isOccupied
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: occupancyColor,
                        size: 20,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Capacidad: ${shed.capacity}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    shed.isOccupied ? 'Ocupado' : 'Disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: occupancyColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _calculateOccupancy(List sheds) {
    if (sheds.isEmpty) return '0%';
    final occupied = sheds.where((s) => s.isOccupied).length;
    final percentage = (occupied / sheds.length * 100).toStringAsFixed(0);
    return '$percentage%';
  }
}
