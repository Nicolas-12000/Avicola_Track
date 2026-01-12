import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../data/models/user_model.dart';
import '../data/auth_datasource.dart';

class AuthRepository {
  final AuthDataSource dataSource;

  AuthRepository(this.dataSource);

  Future<UserModel> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Debug: print('📡 AuthRepository.login: Llamando a dataSource.login');
      final authResponse = await dataSource.login(
        username: username,
        password: password,
      );

      // Debug: print('✅ AuthRepository: Backend respondió exitosamente');
      // Debug: print('📄 user_info recibido: ${authResponse.user}');

      // Guardar tokens
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveRefreshToken(authResponse.refreshToken);
      // Debug: print('🔑 Tokens guardados en SecureStorage');

      // Guardar datos de usuario
      final userData = jsonEncode(authResponse.user);
      await SecureStorage.saveUserData(userData);
      // Debug: print('💾 user_data guardado: $userData');

      // Guardar preferencia de recordar sesión
      await SecureStorage.setRememberMe(rememberMe);

      // Debug: print('🔄 Parseando UserModel.fromJson...');
      final user = UserModel.fromJson(authResponse.user);
      // Debug: print('✅ UserModel parseado exitosamente: id=${user.id}, role=${user.role}');
      
      return user;
    } catch (e) {
      // Debug: print('❌ ERROR en AuthRepository.login: $e');
      // Debug: print('📚 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Solo limpiar si el usuario no eligió recordar la sesión
    final rememberMe = await SecureStorage.getRememberMe();
    if (rememberMe) {
      // Solo cerrar sesión actual pero mantener credenciales
      await SecureStorage.deleteTokens();
    } else {
      // Limpiar todo
      await SecureStorage.clearAll();
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final userDataString = await SecureStorage.getUserData();
      if (userDataString == null) return null;

      final userData = jsonDecode(userDataString) as Map<String, dynamic>;
      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await SecureStorage.getToken();
    return token != null;
  }

  Future<bool> refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final authResponse = await dataSource.refreshToken(refreshToken);
      await SecureStorage.saveToken(authResponse.accessToken);
      return true;
    } catch (e) {
      return false;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepository(dataSource);
});
