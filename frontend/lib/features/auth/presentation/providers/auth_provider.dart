import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/user_model.dart';
import '../../domain/auth_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.user,
    required this.isLoading,
    this.error,
  });

  factory AuthState.initial() {
    return AuthState(
      isAuthenticated: false,
      user: null,
      isLoading: true,
      error: null,
    );
  }

  AuthState copyWith({
    bool? isAuthenticated,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final isAuth = await repository.isAuthenticated();
      if (isAuth) {
        final user = await repository.getCurrentUser();
        state = state.copyWith(
          isAuthenticated: true,
          user: user,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isAuthenticated: false, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    // Debug: print('🔐 AuthNotifier.login: Iniciando login para $username');

    try {
      final user = await repository.login(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      
      // Debug: print('✅ AuthNotifier.login: Login exitoso. isAuthenticated = ${state.isAuthenticated}, user = ${user.username}');

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await repository.logout();
    state = AuthState.initial().copyWith(isLoading: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
