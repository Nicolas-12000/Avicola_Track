import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../errors/exceptions.dart';

/// Clase centralizada para manejo de errores
/// Proporciona mensajes amigables al usuario y logging detallado
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Procesar error y obtener mensaje amigable para el usuario
  static String getUserMessage(dynamic error, {String? context}) {
    // Log completo del error para debugging
    _logger.e('Error${context != null ? ' en $context' : ''}: $error');

    // Manejar DioException de manera específica
    if (error is DioException) {
      return _handleDioException(error);
    }

    // Manejar excepciones de app
    if (error is AppException) {
      return error.message;
    }

    // Manejar errores de socket
    if (error is SocketException) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    }

    // Manejar string de errores
    final errorString = error.toString();

    if (errorString.contains('SocketException')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    } else if (errorString.contains('TimeoutException') ||
        errorString.contains('timeout')) {
      return 'La operación tardó demasiado tiempo. Intenta nuevamente.';
    } else if (errorString.contains('FormatException')) {
      return 'Error al procesar los datos. Intenta nuevamente.';
    } else if (errorString.contains('401')) {
      return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
    } else if (errorString.contains('403')) {
      return 'No tienes permiso para realizar esta acción.';
    } else if (errorString.contains('404')) {
      return 'No se encontró el recurso solicitado.';
    } else if (errorString.contains('500')) {
      return 'Error del servidor. Por favor, intenta más tarde.';
    }

    return 'Ha ocurrido un error. Por favor, intenta nuevamente.';
  }

  /// Manejar errores específicos de Dio
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Conexión lenta. No se pudo conectar al servidor a tiempo.';

      case DioExceptionType.sendTimeout:
        return 'Conexión lenta. Los datos tardaron mucho en enviarse.';

      case DioExceptionType.receiveTimeout:
        return 'El servidor tardó mucho en responder. Intenta nuevamente.';

      case DioExceptionType.connectionError:
        return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';

      case DioExceptionType.badCertificate:
        return 'Error de seguridad en la conexión. Contacta al soporte.';

      case DioExceptionType.cancel:
        return 'La operación fue cancelada.';

      case DioExceptionType.badResponse:
        return _handleBadResponse(error);

      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return 'No hay conexión a internet. Verifica tu red.';
        }
        if (error.error is AppException) {
          return (error.error as AppException).message;
        }
        return 'Error de conexión desconocido. Intenta nuevamente.';
    }
  }

  /// Manejar respuestas HTTP con error
  static String _handleBadResponse(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    // Intentar extraer mensaje del backend
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['detail'] ?? data['message'] ?? data['error'];

      // Manejar errores de validación de Django
      if (data['non_field_errors'] is List) {
        serverMessage = (data['non_field_errors'] as List).first.toString();
      }
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? 'Datos inválidos. Verifica la información.';
      case 401:
        return 'Sesión expirada. Por favor, inicia sesión nuevamente.';
      case 403:
        return serverMessage ?? 'No tienes permiso para esta acción.';
      case 404:
        return serverMessage ?? 'El recurso solicitado no existe.';
      case 409:
        return serverMessage ?? 'Conflicto con los datos existentes.';
      case 422:
        return serverMessage ?? 'Los datos enviados no son válidos.';
      case 429:
        return 'Demasiadas solicitudes. Espera un momento e intenta de nuevo.';
      case 500:
        return 'Error interno del servidor. Intenta más tarde.';
      case 502:
        return 'Servidor no disponible temporalmente.';
      case 503:
        return 'Servicio en mantenimiento. Intenta más tarde.';
      case 504:
        return 'El servidor no respondió a tiempo.';
      default:
        return serverMessage ?? 'Error del servidor ($statusCode).';
    }
  }

  /// Log de información general
  static void logInfo(String message, {String? context}) {
    _logger.i('${context != null ? '[$context] ' : ''}$message');
  }

  /// Log de advertencia
  static void logWarning(String message, {String? context}) {
    _logger.w('${context != null ? '[$context] ' : ''}$message');
  }

  /// Log de error con stack trace
  static void logError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
  }) {
    _logger.e(
      '${context != null ? '[$context] ' : ''}$error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log de debug (solo en desarrollo)
  static void logDebug(String message, {String? context}) {
    _logger.d('${context != null ? '[$context] ' : ''}$message');
  }

  /// Mensajes de éxito específicos
  static String getSuccessMessage(String operation) {
    switch (operation) {
      case 'login':
        return '¡Bienvenido! Sesión iniciada correctamente.';
      case 'logout':
        return 'Sesión cerrada correctamente.';
      case 'create':
        return 'Creado exitosamente.';
      case 'update':
        return 'Actualizado exitosamente.';
      case 'delete':
        return 'Eliminado exitosamente.';
      case 'sync':
        return 'Sincronización completada.';
      default:
        return 'Operación completada exitosamente.';
    }
  }
}
