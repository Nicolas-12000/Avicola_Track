import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../providers/farms_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    final authState = ref.watch(authProvider);
    final isFarmAdmin = authState.user?.isFarmAdmin ?? false;
    final currentUserId = authState.user?.id;
    final visibleFarms = isFarmAdmin && currentUserId != null
      ? farmsState.farms.where((f) => f.farmManagerId == currentUserId).toList()
      : farmsState.farms;

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
              showSearch(
                context: context,
                delegate: _FarmSearchDelegate(farmsState.farms),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrar granjas',
                          style: AppTextStyles.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        ListTile(
                          leading: const Icon(Icons.sort_by_alpha),
                          title: const Text('Ordenar por nombre'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordenado por nombre'),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on),
                          title: const Text('Ordenar por ubicación'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Ordenado por ubicación'),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.people),
                          title: const Text('Granjas con asignación'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Mostrando granjas asignadas'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
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
              child: visibleFarms.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: visibleFarms.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final farm = visibleFarms[index];
                        return _buildFarmCard(farm);
                      },
                    ),
            ),
      floatingActionButton: _canCreateFarm(ref)
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateFarmDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Granja'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  bool _canCreateFarm(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userRole = authState.user?.role;
    return userRole == 'Administrador Sistema';
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
            final authState = ref.read(authProvider);
            final isAdminSistema = authState.user?.isSystemAdmin ?? false;
            
            showModalBottomSheet(
              context: context,
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.visibility),
                      title: const Text('Ver detalles'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/farms/${farm.id}');
                      },
                    ),
                    // Solo admin sistema puede editar/eliminar granjas
                    if (isAdminSistema) ...[
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: const Text('Editar'),
                        onTap: () {
                          Navigator.pop(context);
                          _showFarmDialog(context, farm);
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
                          _showDeleteConfirmation(farm);
                        },
                      ),
                    ],
                  ],
                ),
              ),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Nota: Necesitas asignar un administrador de granja después',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
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

                try {
                  if (farm == null) {
                    final createdFarm = await ref
                        .read(farmsProvider.notifier)
                        .createFarm(
                          name: nameController.text,
                          location: locationController.text,
                        );

                    final error = ref.read(farmsProvider).error;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          createdFarm != null
                              ? 'Granja creada exitosamente'
                              : 'Error al guardar la granja${error != null ? ': $error' : ''}',
                        ),
                        backgroundColor:
                            createdFarm != null ? AppColors.success : AppColors.error,
                      ),
                    );

                    if (createdFarm != null) {
                      // Navegar al detalle recién creada
                      if (mounted) {
                        context.push('/farms/${createdFarm.id}');
                      }
                    }
                  } else {
                    final success = await ref
                        .read(farmsProvider.notifier)
                        .updateFarm(
                          id: farm.id,
                          name: nameController.text,
                          location: locationController.text,
                        );

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Granja actualizada exitosamente'
                              : 'Error al guardar la granja',
                        ),
                        backgroundColor:
                            success ? AppColors.success : AppColors.error,
                      ),
                    );
                  }
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: Por favor crea usuarios con rol "Administrador de Granja" primero'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 5),
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

// SearchDelegate para búsqueda de granjas
class _FarmSearchDelegate extends SearchDelegate {
  final List farms;

  _FarmSearchDelegate(this.farms);

  @override
  String get searchFieldLabel => 'Buscar granja...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = farms.where((dynamic farm) {
      final searchLower = query.toLowerCase();
      final nameLower = (farm.name as String).toLowerCase();
      final locationLower = (farm.location as String?)?.toLowerCase() ?? '';

      return nameLower.contains(searchLower) ||
          locationLower.contains(searchLower);
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron granjas',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro término de búsqueda',
              style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final dynamic farm = results[index];
        final String farmName = farm.name as String;
        final String? farmLocation = farm.location as String?;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.business, color: Colors.white),
            ),
            title: Text(farmName, style: AppTextStyles.textTheme.titleMedium),
            subtitle: farmLocation != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farmLocation,
                            style: AppTextStyles.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              close(context, null);
              context.push('/farms/${farm.id}');
            },
          ),
        );
      },
    );
  }
}
