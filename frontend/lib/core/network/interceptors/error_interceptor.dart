import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../errors/exceptions.dart';

/// Interceptor que maneja errores HTTP y los convierte a excepciones tipadas
class ErrorInterceptor extends Interceptor {
  final Logger _logger = Logger();
  static const int maxRetries = 3;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _logger.e(
      'HTTP Error: ${err.response?.statusCode} - ${err.requestOptions.path}',
      error: err.message,
    );

    // Mapear errores HTTP a excepciones custom
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Tiempo de espera agotado. Verifica tu conexión.',
            ),
          ),
        );

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        String message = 'Error del servidor';

        // Intentar extraer mensaje del backend
        if (err.response?.data is Map) {
          final data = err.response!.data as Map<String, dynamic>;
          message =
              data['detail'] ?? data['message'] ?? data['error'] ?? message;
        }

        if (statusCode != null) {
          if (statusCode >= 400 && statusCode < 500) {
            // Errores de cliente
            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                response: err.response,
                error: ServerException(message: message),
              ),
            );
          } else if (statusCode >= 500) {
            // Errores de servidor - considerar retry
            final retryCount = err.requestOptions.extra['retryCount'] ?? 0;

            if (retryCount < maxRetries) {
              _logger.i(
                'Retrying request (attempt ${retryCount + 1}/$maxRetries)',
              );

              // Esperar antes de reintentar (exponential backoff)
              await Future.delayed(Duration(seconds: 2 << retryCount));

              final options = err.requestOptions;
              options.extra['retryCount'] = retryCount + 1;

              try {
                final response = await Dio().fetch(options);
                return handler.resolve(response);
              } catch (e) {
                // Si falla, continuar con error original
              }
            }

            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                response: err.response,
                error: ServerException(
                  message: 'Error del servidor. Intenta nuevamente.',
                ),
              ),
            );
          }
        }
        break;

      case DioExceptionType.cancel:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: Exception('Petición cancelada'),
          ),
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: NetworkException(
              message: 'Sin conexión a internet. Verifica tu red.',
            ),
          ),
        );

      default:
        break;
    }

    return handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      'Response: ${response.statusCode} - ${response.requestOptions.path}',
    );
    return handler.next(response);
  }
}
