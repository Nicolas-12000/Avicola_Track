import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/stat_card.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart' as app;
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final farmsState = ref.watch(farmsProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
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
              // TODO: Navegar a notificaciones
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Navegar a configuración
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
                    _buildKPIsGrid(farmsState.farms.length),

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

  Widget _buildKPIsGrid(int totalFarms) {
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
            const StatCard(
              title: 'Lotes Activos',
              value: '0',
              icon: Icons.egg_outlined,
              color: AppColors.secondary,
              subtitle: 'En producción',
            ),
            const StatCard(
              title: 'Aves Vivas',
              value: '0',
              icon: Icons.pets_outlined,
              color: AppColors.accent,
              subtitle: 'Total en sistema',
            ),
            const StatCard(
              title: 'Alarmas Pendientes',
              value: '0',
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
                  // TODO: Mostrar opciones
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.textDisabled.withValues(alpha: 0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppTextStyles.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: AppTextStyles.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 40),
                      const FlSpot(1, 45),
                      const FlSpot(2, 42),
                      const FlSpot(3, 50),
                      const FlSpot(4, 48),
                      const FlSpot(5, 55),
                      const FlSpot(6, 60),
                    ],
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.business_outlined,
                    size: 64,
                    color: AppColors.textDisabled,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay granjas registradas',
                    style: AppTextStyles.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea tu primera granja para comenzar',
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: AppColors.textDisabled,
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
                        // TODO: Navegar a detalle de granja
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
