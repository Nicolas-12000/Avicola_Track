import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Token Management
  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.storageKeyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.storageKeyToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: AppConstants.storageKeyRefreshToken,
      value: token,
    );
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.storageKeyRefreshToken);
  }

  static Future<void> deleteTokens() async {
    await _storage.delete(key: AppConstants.storageKeyToken);
    await _storage.delete(key: AppConstants.storageKeyRefreshToken);
  }

  // User Data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: AppConstants.storageKeyUser, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: AppConstants.storageKeyUser);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: AppConstants.storageKeyUser);
  }

  // Biometric
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: AppConstants.storageKeyBiometric,
      value: enabled.toString(),
    );
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: AppConstants.storageKeyBiometric);
    return value == 'true';
  }

  // Remember Me
  static Future<void> setRememberMe(bool remember) async {
    await _storage.write(
      key: AppConstants.storageKeyRememberMe,
      value: remember.toString(),
    );
  }

  static Future<bool> getRememberMe() async {
    final value = await _storage.read(key: AppConstants.storageKeyRememberMe);
    return value == 'true';
  }

  // Clear All
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
