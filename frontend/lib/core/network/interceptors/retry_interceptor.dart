import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

/// Interceptor que reintenta requests fallidas por errores de red
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final Duration retryDelay;
  final bool useExponentialBackoff;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.useExponentialBackoff = true,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Solo reintentar en errores de red, no en errores HTTP
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }

    final options = err.requestOptions;
    final retryCount = options.extra['retryCount'] ?? 0;

    if (retryCount >= retries) {
      // Ya no más reintentos
      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'Conexión fallida después de $retries intentos',
          type: err.type,
        ),
      );
    }

    // Calcular delay
    final delay = useExponentialBackoff
        ? retryDelay * (1 << retryCount) // Exponencial: 1s, 2s, 4s
        : retryDelay;

    print('🔄 Retry ${retryCount + 1}/$retries para ${options.path} en ${delay.inSeconds}s');

    await Future.delayed(delay);

    // Incrementar contador y reintentar
    options.extra['retryCount'] = retryCount + 1;

    try {
      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      // Delegar al siguiente intento o fallar
      return onError(e, handler);
    }
  }

  bool _shouldRetry(DioException err) {
    // Reintentar en errores de red
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;

      case DioExceptionType.badResponse:
        // Reintentar solo en errores 5xx del servidor
        final statusCode = err.response?.statusCode;
        return statusCode != null && statusCode >= 500 && statusCode < 600;

      case DioExceptionType.unknown:
        // Verificar si es error de socket
        return err.error is SocketException;

      default:
        return false;
    }
  }
}
