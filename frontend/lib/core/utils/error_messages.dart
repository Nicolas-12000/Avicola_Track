class ErrorMessages {
  ErrorMessages._();

  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Errores de permisos
    if (errorString.contains('403') || errorString.contains('forbidden') || errorString.contains('no tiene permiso')) {
      return 'No tienes permisos para realizar esta acción. Contacta al administrador.';
    }

    // Errores de autenticación
    if (errorString.contains('401') || errorString.contains('unauthorized') || errorString.contains('no autenticado')) {
      return 'Tu sesión ha expirado. Por favor inicia sesión nuevamente.';
    }

    // Errores de servidor
    if (errorString.contains('500') || errorString.contains('502') || errorString.contains('503')) {
      return 'Error del servidor. Por favor intenta nuevamente más tarde.';
    }

    // Errores de red
    if (errorString.contains('network') || errorString.contains('connection') || errorString.contains('timeout')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    }

    // Errores de validación
    if (errorString.contains('400') || errorString.contains('bad request') || errorString.contains('requerido')) {
      return 'Datos incorrectos. Verifica la información e intenta nuevamente.';
    }

    // Errores de tipo (Map vs List, etc.)
    if (errorString.contains('type') && errorString.contains('subtype')) {
      return 'Error al procesar los datos. Por favor recarga la página.';
    }

    // Errores 404
    if (errorString.contains('404') || errorString.contains('not found') || errorString.contains('no encontrado')) {
      return 'Recurso no encontrado. La información solicitada no existe.';
    }

    // Mensaje genérico para otros errores
    return 'Ocurrió un error inesperado. Por favor intenta nuevamente.';
  }

  static String getEmptyStateMessage(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'granjas':
      case 'farms':
        return 'No hay granjas registradas. Crea tu primera granja para comenzar.';
      case 'galpones':
      case 'sheds':
        return 'No hay galpones registrados. Crea un galpón en esta granja.';
      case 'lotes':
      case 'flocks':
        return 'No hay lotes activos. Crea un lote para comenzar a gestionar aves.';
      case 'usuarios':
      case 'users':
        return 'No hay usuarios registrados. Crea usuarios para gestionar el sistema.';
      case 'alarmas':
      case 'alarms':
        return 'No hay alarmas pendientes. ¡Todo está funcionando correctamente!';
      case 'reportes':
      case 'reports':
        return 'No hay reportes generados. Selecciona un tipo de reporte para comenzar.';
      case 'inventario':
      case 'inventory':
        return 'No hay items en el inventario. Agrega productos para gestionar el stock.';
      default:
        return 'No hay información disponible en este momento.';
    }
  }
}
