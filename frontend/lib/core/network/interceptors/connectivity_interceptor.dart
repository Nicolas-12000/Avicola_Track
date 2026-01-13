import 'package:dio/dio.dart';
import '../../services/connectivity_service.dart';
import '../../errors/exceptions.dart';

/// Interceptor que verifica conectividad antes de cada request
/// Evita requests innecesarias cuando no hay conexión
class ConnectivityInterceptor extends Interceptor {
  final ConnectivityService _connectivityService;

  ConnectivityInterceptor(this._connectivityService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final state = _connectivityService.currentState;

    // Si no hay internet, rechazar inmediatamente
    if (state.status == ConnectionStatus.noInternet) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: NetworkException(
            message: 'Sin conexión a internet. ${state.message}',
            code: 'NO_INTERNET',
          ),
        ),
      );
    }

    // Si no hay backend, advertir pero intentar
    if (state.status == ConnectionStatus.noBackend) {
      // Podríamos intentar de todos modos, o rechazar
      // Por ahora, intentamos pero con timeout corto
      options.connectTimeout = const Duration(seconds: 10);
      options.receiveTimeout = const Duration(seconds: 10);
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Convertir errores de conexión a mensajes amigables
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      // Forzar verificación de conectividad
      _connectivityService.checkConnection();

      return handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          type: err.type,
          error: NetworkException(
            message: 'Error de conexión. Verifica tu internet.',
            code: 'CONNECTION_ERROR',
          ),
        ),
      );
    }

    return handler.next(err);
  }
}
