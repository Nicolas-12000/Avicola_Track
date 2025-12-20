import 'package:logger/logger.dart';

/// Clase centralizada para manejo de errores
/// Proporciona mensajes amigables al usuario y logging detallado
class ErrorHandler {
  static final Logger _logger = Logger();

  /// Procesar error y obtener mensaje amigable para el usuario
  static String getUserMessage(dynamic error, {String? context}) {
    // Log completo del error para debugging
    _logger.e('Error${context != null ? ' en $context' : ''}: $error');

    // Retornar mensaje amigable según el tipo de error
    if (error.toString().contains('DioException')) {
      return _handleDioError(error);
    } else if (error.toString().contains('SocketException')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'La operación tardó demasiado tiempo. Intenta nuevamente.';
    } else if (error.toString().contains('FormatException')) {
      return 'Error al procesar los datos. Intenta nuevamente.';
    } else if (error.toString().contains('401')) {
      return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
    } else if (error.toString().contains('403')) {
      return 'No tienes permiso para realizar esta acción.';
    } else if (error.toString().contains('404')) {
      return 'No se encontró el recurso solicitado.';
    } else if (error.toString().contains('500')) {
      return 'Error del servidor. Por favor, intenta más tarde.';
    } else {
      return 'Ha ocurrido un error. Por favor, intenta nuevamente.';
    }
  }

  /// Manejar errores específicos de Dio
  static String _handleDioError(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains('Connection refused') ||
        errorString.contains('Failed host lookup')) {
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    } else if (errorString.contains('CERTIFICATE_VERIFY_FAILED')) {
      return 'Error de seguridad en la conexión.';
    } else {
      return 'Error de red. Por favor, intenta nuevamente.';
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
