import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../core/widgets/app_drawer.dart';
import '../../../../data/models/flock_model.dart';
import '../providers/flocks_provider.dart';
import '../../../sheds/presentation/providers/sheds_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class FlocksListScreen extends ConsumerStatefulWidget {
  final int? farmId;
  final int? shedId;

  const FlocksListScreen({super.key, this.farmId, this.shedId});

  @override
  ConsumerState<FlocksListScreen> createState() => _FlocksListScreenState();
}

class _FlocksListScreenState extends ConsumerState<FlocksListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedFarmId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedFarmId = widget.farmId;
    Future.microtask(() {
      ref
          .read(flocksProvider.notifier)
          .loadFlocks(farmId: _selectedFarmId, shedId: widget.shedId);
      ref.read(shedsProvider.notifier).loadSheds(farmId: _selectedFarmId);
      ref.read(farmsProvider.notifier).loadFarms();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flocksState = ref.watch(flocksProvider);
    final shedsState = ref.watch(shedsProvider);
    final farmsState = ref.watch(farmsProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Lotes', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Activos'),
            Tab(text: 'Vendidos'),
            Tab(text: 'Terminados'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref
                  .read(flocksProvider.notifier)
                  .loadFlocks(farmId: _selectedFarmId, shedId: widget.shedId);
            },
          ),
        ],
      ),
      body: flocksState.isLoading && flocksState.flocks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : flocksState.error != null
          ? Center(
              child: app.ErrorWidget(
                message: flocksState.error!,
                onRetry: () {
                  ref
                      .read(flocksProvider.notifier)
                      .loadFlocks(
                        farmId: _selectedFarmId,
                        shedId: widget.shedId,
                      );
                },
              ),
            )
          : Column(
              children: [
                _buildFarmFilter(farmsState),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFlocksList(
                        flocksState.activeFlocks,
                        shedsState.sheds,
                      ),
                      _buildFlocksList(
                        flocksState.soldFlocks,
                        shedsState.sheds,
                      ),
                      _buildFlocksList(
                        flocksState.terminatedFlocks,
                        shedsState.sheds,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _canCreateFlock(ref)
          ? FloatingActionButton.extended(
              onPressed: () => _showFlockDialog(context, null, shedsState.sheds),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nuevo Lote', style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  bool _canCreateFlock(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    return userRole == 'Administrador Sistema';
  }

  /// Verifica si el usuario puede editar lotes (admin sistema o admin granja)
  bool _canEditFlock() {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.userRole;
    return userRole?.canViewAllFarms == true || userRole?.isFarmAdmin == true;
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
                value: _selectedFarmId,
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
                  ref
                      .read(flocksProvider.notifier)
                      .loadFlocks(farmId: farmId, shedId: widget.shedId);
                  ref.read(shedsProvider.notifier).loadSheds(farmId: farmId);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlocksList(List<FlockModel> flocks, List sheds) {
    if (flocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay lotes en esta categoría',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(flocksProvider.notifier)
            .loadFlocks(farmId: widget.farmId, shedId: widget.shedId);
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final flocksState = ref.read(flocksProvider);
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200 &&
              !flocksState.isLoadingMore &&
              flocksState.hasMoreData) {
            ref.read(flocksProvider.notifier).loadMoreFlocks();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: flocks.length + (ref.watch(flocksProvider).isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == flocks.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final flock = flocks[index];
            return _buildFlockCard(flock, sheds);
          },
        ),
      ),
    );
  }

  Widget _buildFlockCard(FlockModel flock, List sheds) {
    final mortalityColor = flock.mortalityRate < 5
        ? AppColors.success
        : flock.mortalityRate < 10
        ? AppColors.warning
        : AppColors.error;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Lote #${flock.id}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.pets,
                    'Cantidad actual',
                    '${flock.currentQuantity} aves',
                  ),
                  _buildInfoRow(Icons.biotech, 'Raza', flock.breed),
                  _buildInfoRow(Icons.info_outline, 'Estado', flock.status),
                  _buildInfoRow(
                    flock.productionStage.icon,
                    'Etapa',
                    flock.productionStage.label,
                  ),
                  if (flock.processingStage != null)
                    _buildInfoRow(
                      Icons.precision_manufacturing,
                      'Sub-etapa',
                      flock.processingStage!.label,
                    ),
                  _buildInfoRow(
                    Icons.calendar_today,
                    'Edad',
                    '${flock.ageInWeeks} semanas (${flock.ageInDays} días)',
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Acciones disponibles:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const Icon(Icons.edit_calendar),
                    title: const Text('Registro Diario'),
                    subtitle: const Text('Peso, mortalidad, alimento, etc.'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/flocks/${flock.id}/daily-records');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_shipping),
                    title: const Text('Despachos / Pesas'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/flocks/${flock.id}/dispatches');
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
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
                    child: Icon(Icons.groups, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lote #${flock.id} - ${flock.breed}',
                          style: AppTextStyles.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (flock.shedName != null)
                          Text(
                            'Galpón: ${flock.shedName}',
                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: flock.isActive
                          ? AppColors.success.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      flock.status,
                      style: TextStyle(
                        color: flock.isActive ? AppColors.success : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Etapa de producción
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(flock.productionStage.icon, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      flock.productionStage.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    if (flock.processingStage != null) ...[
                      const Text(' › ', style: TextStyle(color: Colors.grey)),
                      Text(
                        flock.processingStage!.label,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.calendar_today,
                      label: 'Edad',
                      value: '${flock.ageInWeeks} sem (${flock.ageInDays}d)',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.pets,
                      label: 'Aves',
                      value: '${flock.currentQuantity}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.warning_amber,
                      label: 'Mortalidad',
                      value: '${flock.mortalityRate.toStringAsFixed(1)}%',
                      color: mortalityColor,
                    ),
                  ),
                  if (flock.currentWeight != null)
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.scale,
                        label: 'Peso',
                        value: '${flock.currentWeight!.toStringAsFixed(2)} kg',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Llegada: ${DateFormat('dd/MM/yyyy').format(flock.arrivalDate)}',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (_canEditFlock())
                    TextButton.icon(
                      onPressed: () => _showFlockDialog(context, flock, sheds),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Editar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? AppColors.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFlockDialog(BuildContext context, FlockModel? flock, List sheds) {
    final formKey = GlobalKey<FormState>();
    final breedController = TextEditingController(text: flock?.breed ?? '');
    final quantityController = TextEditingController(
      text: flock?.initialQuantity.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: flock?.initialWeight?.toString() ?? '',
    );
    final supplierController = TextEditingController(
      text: flock?.supplier ?? '',
    );

    int? selectedShedId = flock?.shedId ?? widget.shedId;
    String selectedGender = flock?.gender ?? 'X';
    ProductionStage selectedStage = flock?.productionStage ?? ProductionStage.growOut;
    DateTime selectedDate = flock?.arrivalDate ?? DateTime.now();

    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(flock == null ? 'Nuevo Lote' : 'Editar Lote'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.shedId == null)
                    DropdownButtonFormField<int>(
                      value: selectedShedId,
                      decoration: const InputDecoration(
                        labelText: 'Galpón',
                        border: OutlineInputBorder(),
                      ),
                      items: sheds.map<DropdownMenuItem<int>>((shed) {
                        return DropdownMenuItem<int>(
                          value: shed.id,
                          child: Text(shed.name),
                        );
                      }).toList(),
                      onChanged: (value) => selectedShedId = value,
                      validator: (value) =>
                          value == null ? 'Seleccione un galpón' : null,
                    ),
                  if (widget.shedId == null) const SizedBox(height: 16),
                  TextFormField(
                    controller: breedController,
                    decoration: const InputDecoration(
                      labelText: 'Raza',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Ingrese la raza' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                      suffixText: 'aves',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Ingrese la cantidad' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Macho')),   // Backend espera 'M'
                      DropdownMenuItem(value: 'F', child: Text('Hembra')),  // Backend espera 'F'
                      DropdownMenuItem(value: 'X', child: Text('Mixto')),   // Backend espera 'X'
                    ],
                    onChanged: (value) => selectedGender = value!,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso inicial (opcional)',
                      border: OutlineInputBorder(),
                      suffixText: 'kg',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: supplierController,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProductionStage>(
                    value: selectedStage,
                    decoration: const InputDecoration(
                      labelText: 'Etapa de producción',
                      border: OutlineInputBorder(),
                    ),
                    items: ProductionStage.values.map((stage) {
                      return DropdownMenuItem(
                        value: stage,
                        child: Row(
                          children: [
                            Icon(stage.icon, size: 18),
                            const SizedBox(width: 8),
                            Text(stage.label),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => selectedStage = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Fecha de llegada'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
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
                  if (flock == null) {
                    await ref
                        .read(flocksProvider.notifier)
                        .createFlock(
                          shedId: selectedShedId!,
                          breed: breedController.text,
                          initialQuantity: int.parse(quantityController.text),
                          gender: selectedGender,
                          arrivalDate: selectedDate,
                          initialWeight: weightController.text.isEmpty
                              ? null
                              : double.parse(weightController.text),
                          supplier: supplierController.text.isEmpty
                              ? null
                              : supplierController.text,
                          productionStage: selectedStage.value,
                        );
                  }

                  if (!mounted) return;

                  final error = ref.read(flocksProvider).error;
                  // Use the parent screen context (captured above) after async
                  Navigator.pop(parentContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        error == null
                            ? '✅ Lote creado exitosamente'
                            : 'Error: $error',
                      ),
                      backgroundColor:
                          error == null ? null : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget helper para mostrar información en el diálogo de detalles
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
