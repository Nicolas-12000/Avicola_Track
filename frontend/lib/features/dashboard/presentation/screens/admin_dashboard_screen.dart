import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../../core/widgets/app_drawer.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../flocks/presentation/providers/flocks_provider.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/flock_model.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al iniciar
    Future.microtask(() {
      ref.read(farmsProvider.notifier).loadFarms();
      ref.read(flocksProvider.notifier).loadFlocks();
      ref.read(alarmsProvider.notifier).loadAlarms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final farmsState = ref.watch(farmsProvider);
    final flocksState = ref.watch(flocksProvider);
    final alarmsState = ref.watch(alarmsProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${user?.firstName ?? 'Admin'}',
              style: AppTextStyles.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Panel de Administración',
              style: AppTextStyles.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              context.push('/alarms');
            },
          ),
          const SizedBox(width: 8),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPIs Grid
                    _buildKPIsGrid(
                      farmsState.farms.length,
                      flocksState,
                      alarmsState,
                    ),

                    const SizedBox(height: 32),

                    // Gráfica de Producción
                    _buildProductionChart(),

                    const SizedBox(height: 32),

                    // Lista de Granjas
                    _buildFarmsList(farmsState),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/farms');
        },
        icon: const Icon(Icons.add),
        label: const Text('Granjas'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildKPIsGrid(int totalFarms, flocksState, alarmsState) {
    // Calcular total de aves vivas actualmente
    final totalBirds = flocksState.activeFlocks.fold<int>(
      0,
      (int sum, FlockModel flock) => sum + flock.currentQuantity,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid
        final crossAxisCount = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            StatCard(
              title: 'Total Granjas',
              value: totalFarms.toString(),
              icon: Icons.business,
              color: AppColors.primary,
              trend: '+12%',
              isPositiveTrend: true,
            ),
            StatCard(
              title: 'Lotes Activos',
              value: '${flocksState.activeFlocks.length}',
              icon: Icons.egg_outlined,
              color: AppColors.secondary,
              subtitle: 'En producción',
            ),
            StatCard(
              title: 'Aves Vivas',
              value: '$totalBirds',
              icon: Icons.pets_outlined,
              color: AppColors.accent,
              subtitle: 'Total en sistema',
            ),
            StatCard(
              title: 'Alarmas Pendientes',
              value: '${alarmsState.unresolvedCount}',
              icon: Icons.warning_amber_outlined,
              color: AppColors.warning,
              subtitle: 'Requieren atención',
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductionChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Producción Últimos 30 Días',
                style: AppTextStyles.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.assessment),
                            title: const Text('Ver reportes completos'),
                            onTap: () {
                              Navigator.pop(context);
                              context.push('/reports');
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Mensaje para indicar que los datos vienen de reportes
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.assessment, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  'Datos de Producción',
                  style: AppTextStyles.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los gráficos de producción detallados están disponibles en la sección de Reportes',
                  style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push('/reports'),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ver Reportes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmsList(FarmsState farmsState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Granjas Recientes',
              style: AppTextStyles.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push('/farms');
              },
              child: const Text('Ver todas'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (farmsState.farms.isEmpty)
          Card(
            color: AppColors.surfaceVariant.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay granjas registradas',
                    style: AppTextStyles.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primera granja para comenzar a gestionar tu producción avícola',
                    style: AppTextStyles.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/farms'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Granja'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: farmsState.farms.length > 5
                ? 5
                : farmsState.farms.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final farm = farmsState.farms[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.business, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farm.name,
                            style: AppTextStyles.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            farm.location,
                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${farm.activeSheds} galpones',
                          style: AppTextStyles.textTheme.labelMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cap: ${farm.totalCapacity}',
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        final farmName =
                            farmsState.farms.isNotEmpty &&
                                index < farmsState.farms.length
                            ? farmsState.farms[index].name
                            : 'Granja';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🏢 Ver detalle de $farmName'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Ir a Granjas',
                              onPressed: () => context.push('/farms'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
