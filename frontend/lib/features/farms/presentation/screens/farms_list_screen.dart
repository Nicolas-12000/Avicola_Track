import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../providers/farms_provider.dart';

class FarmsListScreen extends ConsumerStatefulWidget {
  const FarmsListScreen({super.key});

  @override
  ConsumerState<FarmsListScreen> createState() => _FarmsListScreenState();
}

class _FarmsListScreenState extends ConsumerState<FarmsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(farmsProvider.notifier).loadFarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final farmsState = ref.watch(farmsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text('Granjas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              // TODO: Implementar filtros
            },
          ),
        ],
      ),
      body: farmsState.isLoading && farmsState.farms.isEmpty
          ? const LoadingWidget()
          : farmsState.error != null && farmsState.farms.isEmpty
          ? app.ErrorWidget(
              message: farmsState.error!,
              onRetry: () {
                ref.read(farmsProvider.notifier).loadFarms();
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(farmsProvider.notifier).loadFarms();
              },
              child: farmsState.farms.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: farmsState.farms.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final farm = farmsState.farms[index];
                        return _buildFarmCard(farm);
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateFarmDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Granja'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 24),
          Text(
            'No hay granjas registradas',
            style: AppTextStyles.textTheme.titleLarge?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera granja para comenzar',
            style: AppTextStyles.textTheme.bodyMedium?.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateFarmDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Crear Granja'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmCard(farm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navegar a detalle
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ver detalle de ${farm.name}')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.business,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.name,
                            style: AppTextStyles.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  farm.location,
                                  style: AppTextStyles.textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outlined, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Eliminar',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditFarmDialog(farm);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(farm);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      'Galpones',
                      farm.activeSheds.toString(),
                      Icons.home_outlined,
                    ),
                    _buildStatColumn(
                      'Capacidad',
                      farm.totalCapacity.toString(),
                      Icons.inventory_2_outlined,
                    ),
                    if (farm.farmManagerName != null)
                      _buildStatColumn(
                        'Gerente',
                        farm.farmManagerName!,
                        Icons.person_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showCreateFarmDialog() {
    _showFarmDialog(context, null);
  }

  void _showEditFarmDialog(farm) {
    _showFarmDialog(context, farm);
  }

  void _showFarmDialog(BuildContext context, farm) {
    final nameController = TextEditingController(text: farm?.name ?? '');
    final locationController = TextEditingController(
      text: farm?.location ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(farm == null ? 'Nueva Granja' : 'Editar Granja'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Granja',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Ubicación',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese una ubicación';
                    }
                    return null;
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
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);

                final success = farm == null
                    ? await ref
                          .read(farmsProvider.notifier)
                          .createFarm(
                            name: nameController.text,
                            location: locationController.text,
                          )
                    : await ref
                          .read(farmsProvider.notifier)
                          .updateFarm(
                            id: farm.id,
                            name: nameController.text,
                            location: locationController.text,
                          );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? farm == null
                                  ? 'Granja creada exitosamente'
                                  : 'Granja actualizada exitosamente'
                            : 'Error al guardar la granja',
                      ),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(farm == null ? 'Crear' : 'Guardar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(farm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Está seguro de eliminar la granja "${farm.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await ref
                  .read(farmsProvider.notifier)
                  .deleteFarm(farm.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Granja eliminada exitosamente'
                          : 'Error al eliminar la granja',
                    ),
                    backgroundColor: success
                        ? AppColors.success
                        : AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
