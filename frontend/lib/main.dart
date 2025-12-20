import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/offline_sync_service.dart';
import 'core/utils/error_handler.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Hive para offline sync
  try {
    await OfflineSyncService().initialize();
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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'AvícolaTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
