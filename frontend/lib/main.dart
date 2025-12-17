import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: AvicolaTrackApp()));
}

class AvicolaTrackApp extends ConsumerWidget {
  const AvicolaTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AvícolaTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // TODO: Implement theme switcher
      routerConfig: router,
    );
  }
}
