import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../core/widgets/app_drawer.dart';
import '../../../../data/models/shed_model.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../providers/sheds_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ShedsListScreen extends ConsumerStatefulWidget {
  final int? farmId;

  const ShedsListScreen({super.key, this.farmId});

  @override
  ConsumerState<ShedsListScreen> createState() => _ShedsListScreenState();
}

class _ShedsListScreenState extends ConsumerState<ShedsListScreen> {
  int? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _selectedFarmId = widget.farmId;
    Future.microtask(() {
      ref.read(shedsProvider.notifier).loadSheds(farmId: _selectedFarmId);
      ref.read(farmsProvider.notifier).loadFarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shedsState = ref.watch(shedsProvider);
    final farmsState = ref.watch(farmsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Galpones', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref
                  .read(shedsProvider.notifier)
                  .loadSheds(farmId: _selectedFarmId);
            },
          ),
        ],
      ),
      body: shedsState.isLoading && shedsState.sheds.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : shedsState.error != null
          ? Center(
              child: app.ErrorWidget(
                message: shedsState.error!,
                onRetry: () {
                  ref
                      .read(shedsProvider.notifier)
                      .loadSheds(farmId: _selectedFarmId);
                },
              ),
            )
          : shedsState.sheds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warehouse_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay galpones registrados',
                    style: AppTextStyles.textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega tu primer galpón',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(shedsProvider.notifier)
                    .loadSheds(farmId: _selectedFarmId);
              },
              child: Column(
                children: [
                  // Farm Filter
                  _buildFarmFilter(farmsState),

                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600
                            ? 3
                            : 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: shedsState.sheds.length,
                      itemBuilder: (context, index) {
                        final shed = shedsState.sheds[index];
                        return _buildShedCard(shed, farmsState.farms);
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _canCreateShed(ref)
          ? FloatingActionButton.extended(
              onPressed: () => _showShedDialog(context, null, farmsState.farms),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nuevo Galpón',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  bool _canCreateShed(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    return userRole == 'Administrador Sistema';
  }

  Widget _buildFarmFilter(FarmsState farmsState) {
    if (farmsState.farms.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.filter_list, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _selectedFarmId,
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Granja',
                  border: InputBorder.none,
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
                  setState(() {
                    _selectedFarmId = farmId;
                  });
                  ref.read(shedsProvider.notifier).loadSheds(farmId: farmId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShedCard(ShedModel shed, List farms) {
    final occupancyPercentage = shed.occupancyPercentage;
    Color statusColor = AppColors.success;
    if (occupancyPercentage >= 90) {
      statusColor = AppColors.error;
    } else if (occupancyPercentage >= 70) {
      statusColor = AppColors.warning;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar'),
                    onTap: () {
                      Navigator.pop(context);
                      _showShedDialog(context, shed, farms);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(shed);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.warehouse, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${occupancyPercentage.toStringAsFixed(0)}%',
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
              Text(
                shed.name,
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (shed.farmName != null)
                Row(
                  children: [
                    Icon(Icons.business, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shed.farmName!,
                        style: AppTextStyles.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ocupación',
                        style: AppTextStyles.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${shed.currentOccupancy}/${shed.capacity}',
                        style: AppTextStyles.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (shed.assignedWorkerName != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Galponero',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          shed.assignedWorkerName!.split(' ').first,
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShedDialog(BuildContext context, ShedModel? shed, List farms) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: shed?.name ?? '');
    final capacityController = TextEditingController(
      text: shed?.capacity.toString() ?? '',
    );

    int? selectedFarmId = shed?.farm ?? widget.farmId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shed == null ? 'Nuevo Galpón' : 'Editar Galpón'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.farmId == null)
                  DropdownButtonFormField<int>(
                    initialValue: selectedFarmId,
                    decoration: const InputDecoration(
                      labelText: 'Granja',
                      border: OutlineInputBorder(),
                    ),
                    items: farms.map<DropdownMenuItem<int>>((farm) {
                      return DropdownMenuItem<int>(
                        value: farm.id,
                        child: Text(farm.name),
                      );
                    }).toList(),
                    onChanged: (value) => selectedFarmId = value,
                    validator: (value) =>
                        value == null ? 'Seleccione una granja' : null,
                  ),
                if (widget.farmId == null) const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingrese un nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad',
                    border: OutlineInputBorder(),
                    suffixText: 'aves',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Ingrese la capacidad' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (shed == null) {
                  await ref
                      .read(shedsProvider.notifier)
                      .createShed(
                        name: nameController.text,
                        farmId: selectedFarmId!,
                        capacity: int.parse(capacityController.text),
                      );
                } else {
                  await ref
                      .read(shedsProvider.notifier)
                      .updateShed(
                        id: shed.id,
                        name: nameController.text,
                        capacity: int.parse(capacityController.text),
                      );
                }
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        shed == null
                            ? '✅ Galpón creado exitosamente'
                            : '✅ Galpón actualizado',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ShedModel shed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar el galpón "${shed.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await ref.read(shedsProvider.notifier).deleteShed(shed.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🗑️ Galpón eliminado')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
