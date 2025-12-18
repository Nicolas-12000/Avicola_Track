import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/farms/presentation/screens/farms_list_screen.dart';
import '../../features/users/presentation/screens/users_list_screen.dart';
import '../../features/sheds/presentation/screens/sheds_list_screen.dart';
import '../../features/flocks/presentation/screens/flocks_list_screen.dart';

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      // Si no está autenticado y no está en login, redirigir a login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // Si está autenticado y está en login, redirigir a home
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      // No redirigir
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Dashboard Routes
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // Farms Routes
      GoRoute(
        path: '/farms',
        name: 'farms',
        builder: (context, state) => const FarmsListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-farm',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Create Farm - TODO'))),
          ),
          GoRoute(
            path: ':id',
            name: 'farm-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return Scaffold(
                body: Center(child: Text('Farm Detail $id - TODO')),
              );
            },
          ),
        ],
      ),

      // Users Routes
      GoRoute(
        path: '/users',
        name: 'users',
        builder: (context, state) => const UsersListScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-user',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Create User - TODO'))),
          ),
          GoRoute(
            path: ':id',
            name: 'user-detail',
            builder: (context, state) {
              final id = state.pathParameters['id'];
              return Scaffold(
                body: Center(child: Text('User Detail $id - TODO')),
              );
            },
          ),
        ],
      ),

      // Sheds Routes
      GoRoute(
        path: '/sheds',
        name: 'sheds',
        builder: (context, state) => const ShedsListScreen(),
      ),

      // Flocks Routes
      GoRoute(
        path: '/flocks',
        name: 'flocks',
        builder: (context, state) => const FlocksListScreen(),
      ),

      // Inventory Routes
      GoRoute(
        path: '/inventory',
        name: 'inventory',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Inventory - TODO'))),
      ),

      // Alarms Routes
      GoRoute(
        path: '/alarms',
        name: 'alarms',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Alarms - TODO'))),
      ),

      // Reports Routes
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Reports - TODO'))),
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Settings - TODO'))),
      ),
    ],

    // Error Page
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    ),
  );
});
