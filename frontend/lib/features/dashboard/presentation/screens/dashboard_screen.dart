import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../farms/presentation/providers/farms_provider.dart';
import '../../../flocks/presentation/providers/flocks_provider.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final farmsState = ref.watch(farmsProvider);
    final flocksState = ref.watch(flocksProvider);
    final alarmsState = ref.watch(alarmsProvider);

    // Cargar datos al iniciar si no están cargados
    if (farmsState.farms.isEmpty && !farmsState.isLoading) {
      Future.microtask(() => ref.read(farmsProvider.notifier).loadFarms());
    }
    if (flocksState.flocks.isEmpty && !flocksState.isLoading) {
      Future.microtask(() => ref.read(flocksProvider.notifier).loadFlocks());
    }
    if (alarmsState.alarms.isEmpty && !alarmsState.isLoading) {
      Future.microtask(() => ref.read(alarmsProvider.notifier).loadAlarms());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/alarms'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saludo
            Text(
              '👋 Hola, ${user?.firstName ?? 'Usuario'}',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Rol: ${user?.role ?? 'No asignado'}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),

            // KPIs
            _buildKPISection(context, ref),

            const SizedBox(height: 32),

            // Mensaje informativo si no hay datos
            if (farmsState.farms.isEmpty &&
                flocksState.flocks.isEmpty &&
                !farmsState.isLoading &&
                !flocksState.isLoading)
              Card(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay datos todavía',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Comienza creando tu primera granja desde el menú lateral',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Mensaje temporal
            if (farmsState.farms.isNotEmpty ||
                flocksState.flocks.isNotEmpty ||
                farmsState.isLoading ||
                flocksState.isLoading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.construction,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '¡Bienvenido a AvícolaTrack!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gestiona tus granjas, lotes, inventario y más desde el menú lateral',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isLargeScreen = constraints.maxWidth > 600;
                          final cardWidth = isLargeScreen
                              ? (constraints.maxWidth - 48) / 4
                              : (constraints.maxWidth - 32) / 2;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _QuickAccessCard(
                                  icon: Icons.agriculture,
                                  label: 'Mis Granjas',
                                  color: AppColors.primary,
                                  onTap: () => context.push('/farms'),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _QuickAccessCard(
                                  icon: Icons.pets,
                                  label: 'Lotes',
                                  color: AppColors.secondary,
                                  onTap: () => context.push('/flocks'),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _QuickAccessCard(
                                  icon: Icons.inventory,
                                  label: 'Inventario',
                                  color: AppColors.success,
                                  onTap: () => context.push('/inventory'),
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _QuickAccessCard(
                                  icon: Icons.notifications_active,
                                  label: 'Alarmas',
                                  color: AppColors.warning,
                                  onTap: () => context.push('/alarms'),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPISection(BuildContext context, WidgetRef ref) {
    final farmsState = ref.watch(farmsProvider);
    final flocksState = ref.watch(flocksProvider);
    final alarmsState = ref.watch(alarmsProvider);

    // Calcular total de aves vivas actualmente
    final totalBirds = flocksState.activeFlocks.fold<int>(
      0,
      (sum, flock) => sum + flock.currentQuantity,
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          context,
          title: 'Granjas',
          value: '${farmsState.farms.length}',
          icon: Icons.business,
          color: AppColors.primary,
        ),
        _buildKPICard(
          context,
          title: 'Lotes Activos',
          value: '${flocksState.activeFlocks.length}',
          icon: Icons.agriculture,
          color: AppColors.secondary,
        ),
        _buildKPICard(
          context,
          title: 'Aves Totales',
          value: '$totalBirds',
          icon: Icons.pets,
          color: AppColors.accent,
        ),
        _buildKPICard(
          context,
          title: 'Alarmas',
          value: '${alarmsState.unresolvedCount}',
          icon: Icons.warning,
          color: AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget de acceso rápido para el dashboard
class _QuickAccessCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
