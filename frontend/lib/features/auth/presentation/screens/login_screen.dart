import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/snackbar_helper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Debug: print('🔑 LoginScreen: Iniciando proceso de login');
    final success = await ref
        .read(authProvider.notifier)
        .login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );

    if (!mounted) return;

    // Debug: print('🔑 LoginScreen: Login result = $success, isAuthenticated = ${ref.read(authProvider).isAuthenticated}');
    
    if (success) {
      // El router redirigirá automáticamente al home cuando detecte isAuthenticated = true
      // Debug: print('🔑 LoginScreen: Llamando context.go("/")');
      context.go('/');
      // Debug: print('🔑 LoginScreen: context.go("/") ejecutado');
    } else {
      final error = ref.read(authProvider).error;
      SnackBarHelper.showError(context, error ?? 'Error al iniciar sesión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/images/login.png',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),

                    // Título
                    Text(
                      'Iniciar Sesión',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestión Inteligente de Granjas Avícolas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // Usuario
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Usuario o Email',
                        hintText: 'Ingresa tu usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.required,
                      enabled: !authState.isLoading,
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        hintText: 'Ingresa tu contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      enabled: !authState.isLoading,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                    const SizedBox(height: 12),

                    // Recordar sesión
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: authState.isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Recordar sesión',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                'Mantener sesión activa al cerrar la app',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón de login
                    ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Olvidé contraseña
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () => _showPasswordRecoveryDialog(context),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),

                    const SizedBox(height: 32),

                    // Versión
                    Text(
                      'Versión 1.0.0',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo de recuperación de contraseña
  void _showPasswordRecoveryDialog(BuildContext context) {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo electrónico y te enviaremos instrucciones para restablecer tu contraseña.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tu correo';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✉️ Se ha enviado un correo a ${emailController.text}',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
