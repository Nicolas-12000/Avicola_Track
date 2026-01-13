import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/user_roles.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/farms/presentation/screens/farms_list_screen.dart';
import '../../features/users/presentation/screens/users_list_screen.dart';
import '../../features/sheds/presentation/screens/sheds_list_screen.dart';
import '../../features/flocks/presentation/screens/flocks_list_screen.dart';
import '../../features/inventory/presentation/screens/inventory_list_screen.dart';
import '../../features/alarms/presentation/screens/alarms_list_screen.dart';
import '../../features/dashboard/presentation/screens/farm_dashboard_screen.dart';
import '../../features/dashboard/presentation/screens/shed_keeper_dashboard_screen.dart';
import '../../features/reports/presentation/screens/reports_list_screen.dart';
import '../../features/veterinary/presentation/screens/veterinary_dashboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';

/// Helper para obtener la ruta inicial según el rol del usuario
String _getInitialRouteForRole(UserRole? role) {
  if (role == null) return '/';
  return role.initialRoute;
}

// Router Provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final user = authState.user;
      final userRole = user?.userRole;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnLogin = state.matchedLocation == '/login';

      print('🚦 Router redirect: location=${state.matchedLocation}, isAuth=$isAuthenticated, isLoading=$isLoading, role=${userRole?.name}');

      // Mientras carga, mostrar splash
      if (isLoading && !isOnSplash) {
        print('🚦 Router: Redirigiendo a splash (cargando)');
        return '/splash';
      }

      // Si terminó de cargar
      if (!isLoading) {
        // Si está en splash, redirigir según autenticación y rol
        if (isOnSplash) {
          if (isAuthenticated) {
            final dest = _getInitialRouteForRole(userRole);
            print('🚦 Router: Desde splash -> $dest (rol: ${userRole?.name})');
            return dest;
          } else {
            print('🚦 Router: Desde splash -> /login');
            return '/login';
          }
        }

        // Si no está autenticado y no está en login, redirigir a login
        if (!isAuthenticated && !isOnLogin) {
          print('🚦 Router: No autenticado -> /login');
          return '/login';
        }

        // Si está autenticado y está en login, redirigir según rol
        if (isAuthenticated && isOnLogin) {
          final dest = _getInitialRouteForRole(userRole);
          print('🚦 Router: Autenticado en login -> $dest');
          return dest;
        }
        
        // Proteger rutas según el rol
        if (isAuthenticated && userRole != null) {
          final location = state.matchedLocation;
          
          // Galponero solo puede acceder a su dashboard y registro de datos
          if (userRole.isShedKeeper) {
            final allowedPaths = ['/shed-keeper-dashboard', '/flocks', '/alarms'];
            final isAllowed = allowedPaths.any((p) => location.startsWith(p));
            if (!isAllowed && location != '/') {
              print('🚦 Router: Galponero sin acceso a $location -> /shed-keeper-dashboard');
              return '/shed-keeper-dashboard';
            }
            if (location == '/') {
              return '/shed-keeper-dashboard';
            }
          }
          
          // Veterinario solo puede acceder a veterinary
          if (userRole.isVeterinarian) {
            final allowedPaths = ['/veterinary', '/alarms'];
            final isAllowed = allowedPaths.any((p) => location.startsWith(p));
            if (!isAllowed && location != '/') {
              print('🚦 Router: Veterinario sin acceso a $location -> /veterinary');
              return '/veterinary';
            }
            if (location == '/') {
              return '/veterinary';
            }
          }
          
          // Admin de granja puede acceder a casi todo menos a crear granjas/usuarios generales
          if (userRole.isFarmAdmin) {
            if (location == '/') {
              return '/farms/dashboard';
            }
          }
        }
      }

      // No redirigir
      print('🚦 Router: Sin redirección');
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

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
          GoRoute(
            path: 'dashboard',
            name: 'farm-dashboard',
            builder: (context, state) => const FarmDashboardScreen(),
          ),
        ],
      ),

      // Dashboard Routes
      GoRoute(
        path: '/shed-keeper-dashboard',
        name: 'shed-keeper-dashboard',
        builder: (context, state) => const ShedKeeperDashboardScreen(),
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
        builder: (context, state) => const InventoryListScreen(),
      ),

      // Alarms Routes
      GoRoute(
        path: '/alarms',
        name: 'alarms',
        builder: (context, state) => const AlarmsListScreen(),
      ),

      // Reports Routes
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportsListScreen(),
      ),

      // Veterinary Routes
      GoRoute(
        path: '/veterinary',
        name: 'veterinary-dashboard',
        builder: (context, state) => const VeterinaryDashboardScreen(),
      ),

      // Profile/Settings Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        redirect: (context, state) => '/profile',
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
