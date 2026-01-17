import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../constants/api_constants.dart';
import '../../storage/secure_storage.dart';

/// Interceptor para autenticación JWT (DEPRECATED)
/// 
/// NOTA: Este interceptor ya no se usa directamente.
/// La lógica de autenticación está integrada en dio_client.dart
/// para evitar problemas de refresh token y race conditions.
/// 
/// Se mantiene como referencia y para casos específicos donde
/// se necesite un Dio separado con autenticación.
@Deprecated('Use the built-in auth interceptor in dio_client.dart instead')
class AuthInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Endpoints que no requieren autenticación
    final publicEndpoints = [ApiConstants.login, ApiConstants.refreshToken];

    final isPublicEndpoint = publicEndpoints.any(
      (endpoint) => options.path.contains(endpoint),
    );

    if (!isPublicEndpoint) {
      // Obtener access token
      final accessToken = await SecureStorage.getToken();

      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
        _logger.d('Added Bearer token to request: ${options.path}');
      } else {
        _logger.w(
          'No access token found for protected endpoint: ${options.path}',
        );
      }
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Si es error 401 (Unauthorized), intentar refresh token
    if (err.response?.statusCode == 401) {
      _logger.w('Received 401 Unauthorized, attempting token refresh...');

      try {
        final refreshToken = await SecureStorage.getRefreshToken();

        if (refreshToken != null) {
          // IMPORTANTE: Usar Dio sin interceptores para evitar loops
          final dio = Dio(BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            headers: ApiConstants.defaultHeaders,
          ));
          
          final response = await dio.post(
            ApiConstants.refreshToken,
            data: {'refresh': refreshToken},
          );

          if (response.statusCode == 200) {
            final newAccessToken = response.data['access'];
            await SecureStorage.saveToken(newAccessToken);

            _logger.i('Token refreshed successfully');

            // Reintentar request original con nuevo token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';

            final retryResponse = await dio.fetch(options);
            return handler.resolve(retryResponse);
          }
        }
      } catch (e) {
        _logger.e('Token refresh failed', error: e);
        // Limpiar tokens inválidos
        await SecureStorage.deleteTokens();
        // Usuario debe hacer login nuevamente
      }
    }

    return handler.next(err);
  }
}
