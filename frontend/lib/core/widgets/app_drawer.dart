import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/farms/presentation/providers/farms_provider.dart';
import '../../features/veterinary/presentation/providers/veterinary_visits_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userRole = user?.userRole;
    
    // Permisos basados en el rol
    final canViewAllFarms = userRole?.canViewAllFarms ?? false;
    final canViewReports = userRole?.canViewReports ?? false;
    final canCreateUsers = userRole?.canCreateUsers ?? false;
    final isVeterinarian = userRole?.isVeterinarian ?? false;
    final isShedKeeper = userRole?.isShedKeeper ?? false;
    final isFarmAdmin = userRole?.isFarmAdmin ?? false;

    return Drawer(
      child: Column(
        children: [
          // Header con información del usuario
          InkWell(
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Settings icon
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white70),
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/profile');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Nombre
                  Text(
                    user?.fullName.isNotEmpty == true 
                        ? user!.fullName 
                        : (user?.username ?? 'Usuario'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Rol badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role ?? 'Sin rol',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Dashboard - varía según el rol
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    if (isShedKeeper) {
                      context.go('/shed-keeper-dashboard');
                    } else if (isVeterinarian) {
                      context.go('/veterinary');
                    } else if (isFarmAdmin) {
                      context.go('/farms/dashboard');
                    } else {
                      context.go('/');
                    }
                  },
                ),
                
                // Granjas - Admin sistema y Admin de Granja pueden ver
                if (canViewAllFarms || isFarmAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'GESTIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.agriculture_outlined,
                    activeIcon: Icons.agriculture,
                    title: 'Granjas',
                    onTap: () {
                        if (isFarmAdmin) {
                          // Trigger farms load in background if empty, but don't await
                          final farmsState = ref.read(farmsProvider);
                          if (farmsState.farms.isEmpty) {
                            ref.read(farmsProvider.notifier).loadFarms();
                          }
                          final currentUserId = authState.user?.id;
                          final managed = ref
                              .read(farmsProvider)
                              .farms
                              .where((f) => f.farmManagerId == currentUserId)
                              .toList();
                          Navigator.pop(context);
                          if (managed.length == 1) {
                            context.push('/farms/${managed.first.id}');
                          } else {
                            context.push('/farms');
                          }
                        } else {
                          Navigator.pop(context);
                          context.push('/farms');
                        }
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.warehouse_outlined,
                    activeIcon: Icons.warehouse,
                    title: 'Galpones',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/sheds');
                    },
                  ),
                ],
                
                // Lotes - Todos menos veterinario
                if (!isVeterinarian)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.egg_outlined,
                    activeIcon: Icons.egg,
                    title: 'Lotes',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/flocks');
                    },
                  ),
                
                // Inventario - Admin sistema, admin granja y galponero
                if (canViewAllFarms || isFarmAdmin || isShedKeeper)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2,
                    title: 'Inventario',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/inventory');
                    },
                  ),
                
                // Veterinaria - Solo veterinarios y administradores del sistema (no galponeros ni admin de granja)
                if ((isVeterinarian || canViewAllFarms) && !isShedKeeper)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.medical_services_outlined,
                    activeIcon: Icons.medical_services,
                    title: 'Veterinaria',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/veterinary');
                    },
                  ),
                // Sección específica para veterinarios: accesos rápidos reutilizando el mismo drawer
                if (isVeterinarian) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'VETERINARIA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    title: 'Agenda',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/veterinary/agenda');
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.event,
                    activeIcon: Icons.event,
                    title: 'Visitas',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/veterinary/visits');
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.vaccines_outlined,
                    activeIcon: Icons.vaccines,
                    title: 'Vacunas',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/veterinary/vaccinations');
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.medication_outlined,
                    activeIcon: Icons.medication,
                    title: 'Medicamentos',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/veterinary/medications');
                    },
                  ),
                ],

                // Calendario de visitas - solo para Administrador de Granja
                if (isFarmAdmin)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_month_outlined,
                    activeIcon: Icons.calendar_month,
                    title: 'Calendario de visitas',
                    onTap: () async {
                      // Ensure farms are loaded so we can determine managed farms
                      final farmsState = ref.read(farmsProvider);
                      if (farmsState.farms.isEmpty) {
                        ref.read(farmsProvider.notifier).loadFarms();
                      }

                      final currentUserId = authState.user?.id;
                      final managed = ref
                          .read(farmsProvider)
                          .farms
                          .where((f) => f.farmManagerId == currentUserId)
                          .toList();

                      if (managed.length == 1) {
                        // Directly open agenda for the single managed farm
                        final id = managed.first.id;
                        ref.read(veterinaryAgendaFarmProvider.notifier).state = id;
                        Navigator.pop(context);
                        context.push('/veterinary/agenda');
                        return;
                      }

                      if (managed.isEmpty) {
                        // Fallback: open general agenda
                        ref.read(veterinaryAgendaFarmProvider.notifier).state = null;
                        Navigator.pop(context);
                        context.push('/veterinary/agenda');
                        return;
                      }

                      // Multiple farms: ask the user to pick one while drawer is still open
                      final selected = await showDialog<int?>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Selecciona una granja'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: managed.length,
                              itemBuilder: (context, index) {
                                final farm = managed[index];
                                return ListTile(
                                  title: Text(farm.name),
                                  onTap: () => Navigator.of(context).pop(farm.id),
                                );
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(null),
                              child: const Text('Cancelar'),
                            ),
                          ],
                        ),
                      );

                      if (selected != null) {
                        ref.read(veterinaryAgendaFarmProvider.notifier).state = selected;
                        Navigator.pop(context);
                        context.push('/veterinary/agenda');
                      }
                    },
                  ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'MONITOREO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                // Alarmas - Todos pueden ver
                _buildMenuItem(
                  context: context,
                  icon: Icons.notifications_outlined,
                  activeIcon: Icons.notifications,
                  title: 'Alarmas',
                  badgeColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/alarms');
                  },
                ),
                
                // Reportes - Solo admin sistema y admin granja
                if (canViewReports)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.assessment_outlined,
                    activeIcon: Icons.assessment,
                    title: 'Reportes',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/reports');
                    },
                  ),
                
                // Usuarios - Solo quienes pueden crear usuarios
                if (canCreateUsers) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'ADMINISTRACIÓN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    title: 'Usuarios',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/users');
                    },
                  ),
                ],
              ],
            ),
          ),
          
          // Perfil universal (accesible para todos los usuarios)
          _buildMenuItem(
            context: context,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            title: 'Mi Perfil',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),

          // Footer con logout
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout, color: Colors.red, size: 20),
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                final authNotifier = ref.read(authProvider.notifier);
                Navigator.pop(context);
                await authNotifier.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: badgeColor != null
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
