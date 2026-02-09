import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/connection_status_widget.dart';
import 'core/widgets/sync_status_banner.dart';
import 'core/providers/notifications_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar locale para formato de fechas en español
  await initializeDateFormatting('es', null);

  // Inicializar servicio de conectividad
  try {
    await ConnectivityService().initialize();
    ErrorHandler.logInfo('Connectivity service initialized');
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      context: 'Connectivity initialization',
      stackTrace: stackTrace,
    );
  }

  // Inicializar Hive para offline sync (solo abrir cajas, el auto-sync lo maneja el provider)
  try {
    await OfflineSyncService().initialize();
    ErrorHandler.logInfo('Offline sync service initialized (Hive boxes ready)');
  } catch (e, stackTrace) {
    ErrorHandler.logError(
      e,
      context: 'Offline sync initialization',
      stackTrace: stackTrace,
    );
  }

  runApp(const ProviderScope(child: AvicolaTrackApp()));
}

class AvicolaTrackApp extends ConsumerWidget {
  const AvicolaTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final authState = ref.watch(authProvider);
    
    // Iniciar/detener polling de notificaciones según estado de autenticación
    ref.listen<AuthState>(authProvider, (previous, current) {
      if (current.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        // Usuario acaba de autenticarse
        ErrorHandler.logInfo('🔔 Starting notifications polling');
        ref.read(notificationsProvider.notifier).startPolling();
      } else if (!current.isAuthenticated && (previous?.isAuthenticated ?? false)) {
        // Usuario acaba de cerrar sesión
        ErrorHandler.logInfo('🔔 Stopping notifications polling');
        ref.read(notificationsProvider.notifier).stopPolling();
        ref.read(notificationsProvider.notifier).clearNotifications();
      }
    });
    
    // Si ya está autenticado al cargar la app, iniciar polling
    if (authState.isAuthenticated) {
      // Usar addPostFrameCallback para evitar modificar estado durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationsProvider.notifier).startPolling();
      });
    }

    return MaterialApp.router(
      title: 'Avicola San Lorenzo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        // Envolver con widget de estado de conexión y banner de sincronización
        return ConnectionSnackBarWrapper(
          child: Column(
            children: [
              const SyncStatusBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}
