/// Utilidades centralizadas para parsear valores JSON de la API.
/// Elimina la duplicación de `_toDouble`, `_toDoubleNullable`, `_toInt`
/// que estaba repetida en cada modelo.
class JsonParsers {
  JsonParsers._();

  /// Parsea un valor dinámico a double, con fallback a [defaultValue].
  static double toDouble(dynamic value, [double defaultValue = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parsea un valor dinámico a double nullable.
  static double? toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parsea un valor dinámico a int, con fallback a [defaultValue].
  static int toInt(dynamic value, [int defaultValue = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Parsea un valor dinámico a int nullable.
  static int? toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parsea una fecha ISO string a DateTime, con fallback.
  static DateTime? toDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Convierte DateTime a formato date-only string para API (yyyy-MM-dd).
  static String toDateString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }
}
