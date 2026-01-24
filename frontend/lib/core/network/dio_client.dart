import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../services/connectivity_service.dart';
import 'interceptors/connectivity_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

/// Provider principal de Dio con todos los interceptores configurados
final dioProvider = Provider<Dio>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: ApiConstants.defaultHeaders,
      // Treat 4xx as errors so 401 triggers refresh/logout handling
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  // 1. Interceptor de conectividad - verifica conexión antes de cada request
  dio.interceptors.add(ConnectivityInterceptor(connectivityService));

  // 2. Interceptor de autenticación - agrega token y maneja refresh
  dio.interceptors.add(_AuthInterceptor(dio));

  // 3. Interceptor de reintentos - reintenta en errores de red
  dio.interceptors.add(RetryInterceptor(dio: dio, retries: 3));

  // 4. Logger en desarrollo
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        requestHeader: true,
        responseHeader: false,
        logPrint: (o) => print('🌐 DIO: $o'),
      ),
    );
  }

  return dio;
});

/// Provider de Dio sin interceptor de auth (para refresh token)
final dioWithoutAuthProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectionTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: ApiConstants.defaultHeaders,
    ),
  );
});

/// Interceptor de autenticación interno
class _AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  final List<_QueuedRequest> _requestQueue = [];

  _AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Endpoints que no requieren autenticación
    final publicEndpoints = [
      ApiConstants.login,
      ApiConstants.refreshToken,
      ApiConstants.register,
      ApiConstants.passwordReset,
    ];

    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    if (!isPublicEndpoint) {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Si ya estamos refrescando, encolar la request
    if (_isRefreshing) {
      _requestQueue.add(_QueuedRequest(
        options: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshed = await _refreshToken();

      if (refreshed) {
        // Reintentar request original
        final options = err.requestOptions;
        final token = await SecureStorage.getToken();
        options.headers['Authorization'] = 'Bearer $token';

        try {
          final response = await _dio.fetch(options);
          handler.resolve(response);

          // Procesar requests encoladas
          _processQueue(true);
        } catch (e) {
          handler.reject(err);
          _processQueue(false);
        }
      } else {
        // No se pudo refrescar - limpiar sesión
        await SecureStorage.deleteTokens();
        handler.reject(err);
        _processQueue(false);
      }
    } catch (e) {
      await SecureStorage.deleteTokens();
      handler.reject(err);
      _processQueue(false);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken == null) return false;

      // Usar un Dio sin interceptor de auth para evitar loop infinito
      final plainDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        headers: ApiConstants.defaultHeaders,
      ));

      final response = await plainDio.post(
        ApiConstants.refreshToken,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newToken = response.data['access'];
        await SecureStorage.saveToken(newToken);

        // Si el backend devuelve nuevo refresh token
        if (response.data['refresh'] != null) {
          await SecureStorage.saveRefreshToken(response.data['refresh']);
        }

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _processQueue(bool success) {
    for (final request in _requestQueue) {
      if (success) {
        // Reintentar con nuevo token
        _retryRequest(request);
      } else {
        // Rechazar todas las requests encoladas
        request.handler.reject(DioException(
          requestOptions: request.options,
          error: 'Token refresh failed',
        ));
      }
    }
    _requestQueue.clear();
  }

  Future<void> _retryRequest(_QueuedRequest request) async {
    try {
      final token = await SecureStorage.getToken();
      request.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.fetch(request.options);
      request.handler.resolve(response);
    } catch (e) {
      request.handler.reject(DioException(
        requestOptions: request.options,
        error: e,
      ));
    }
  }
}

/// Request encolada mientras se refresca el token
class _QueuedRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _QueuedRequest({required this.options, required this.handler});
}
