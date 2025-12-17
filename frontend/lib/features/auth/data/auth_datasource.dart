import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/auth_response.dart';
import '../../../data/models/user_model.dart';

class AuthDataSource {
  final Dio dio;

  AuthDataSource(this.dio);

  Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
      );

      return AuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dio.get('${ApiConstants.users}me/');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado. Verifica tu conexión.');
    } else if (e.type == DioExceptionType.connectionError) {
      return Exception('Error de conexión. Verifica tu red.');
    } else if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final message =
          e.response?.data['detail'] ??
          e.response?.data['message'] ??
          'Error del servidor';

      if (statusCode == 401) {
        return Exception('Credenciales inválidas');
      } else if (statusCode == 403) {
        return Exception('No tienes permisos para esta acción');
      } else if (statusCode == 404) {
        return Exception('Recurso no encontrado');
      } else if (statusCode != null && statusCode >= 500) {
        return Exception('Error del servidor. Intenta más tarde.');
      }

      return Exception(message);
    }

    return Exception('Error desconocido. Intenta nuevamente.');
  }
}

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthDataSource(dio);
});
