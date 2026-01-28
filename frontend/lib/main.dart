import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/offline_sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/utils/error_handler.dart';
import 'core/widgets/connection_status_widget.dart';
import 'core/widgets/sync_status_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Inicializar Hive para offline sync
  try {
    await OfflineSyncService().initialize();
    // Iniciar sincronización automática cada 5 minutos
    OfflineSyncService().startAutoSync();
    ErrorHandler.logInfo('Offline sync service initialized with auto-sync');
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
