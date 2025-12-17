import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: ApiConstants.defaultHeaders,
    ),
  );

  // Interceptor para agregar token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expirado, intentar refresh
          final refreshed = await _refreshToken(dio);
          if (refreshed) {
            // Reintentar request original
            final options = error.requestOptions;
            final token = await SecureStorage.getToken();
            options.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(options);
              return handler.resolve(response);
            } catch (e) {
              return handler.reject(error);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  // Logger en desarrollo
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
      ),
    );
  }

  return dio;
});

Future<bool> _refreshToken(Dio dio) async {
  try {
    final refreshToken = await SecureStorage.getRefreshToken();
    if (refreshToken == null) return false;

    final response = await dio.post(
      ApiConstants.refreshToken,
      data: {'refresh': refreshToken},
    );

    if (response.statusCode == 200) {
      final newToken = response.data['access'];
      await SecureStorage.saveToken(newToken);
      return true;
    }
    return false;
  } catch (e) {
    return false;
  }
}
