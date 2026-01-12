import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isSystemAdmin = user?.role == 'Administrador Sistema';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Usuario',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          if (isSystemAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.agriculture),
              title: const Text('Granjas'),
              onTap: () {
                Navigator.pop(context);
                context.push('/farms');
              },
            ),
            ListTile(
              leading: const Icon(Icons.warehouse),
              title: const Text('Galpones'),
              onTap: () {
                Navigator.pop(context);
                context.push('/sheds');
              },
            ),
          ],
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Lotes'),
            onTap: () {
              Navigator.pop(context);
              context.push('/flocks');
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2),
            title: const Text('Inventario'),
            onTap: () {
              Navigator.pop(context);
              context.push('/inventory');
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Veterinaria'),
            onTap: () {
              Navigator.pop(context);
              context.push('/veterinary');
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Alarmas'),
            onTap: () {
              Navigator.pop(context);
              context.push('/alarms');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reportes'),
            onTap: () {
              Navigator.pop(context);
              context.push('/reports');
            },
          ),
          if (isSystemAdmin) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Usuarios'),
              onTap: () {
                Navigator.pop(context);
                context.push('/users');
              },
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              context.push('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
