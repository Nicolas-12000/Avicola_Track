import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

/// Pantalla de inicio que verifica la autenticación
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // El AuthNotifier ya verifica la autenticación en su constructor
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Escuchar cambios en el estado para navegar cuando termine la carga
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading) {
        // Si termina de cargar (con o sin error), navegar al Login
        // Nota: Si tuvieras persistencia de sesión, aquí verificarías 
        // si el usuario ya existe para enviarlo directo al '/dashboard'
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.cardShadow,
              ),
              child: Image.asset(
                'assets/images/icono.png',
                width: 110,
                height: 110,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),

            // Título
            const Text(
              'Avicola San Lorenzo',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestión Inteligente de Granjas',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 48),

            // Indicador de carga
            if (authState.isLoading)
              const CircularProgressIndicator(color: AppColors.primary)
            else if (authState.error != null)
              Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.primary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      authState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
