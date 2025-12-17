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
  }) async {
    try {
      final authResponse = await dataSource.login(
        username: username,
        password: password,
      );

      // Guardar tokens
      await SecureStorage.saveToken(authResponse.accessToken);
      await SecureStorage.saveRefreshToken(authResponse.refreshToken);

      // Guardar datos de usuario
      final userData = jsonEncode(authResponse.user);
      await SecureStorage.saveUserData(userData);

      return UserModel.fromJson(authResponse.user);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearAll();
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
