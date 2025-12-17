import '../constants/app_constants.dart';

class Validators {
  Validators._();

  // Email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  // Password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Mínimo ${AppConstants.minPasswordLength} caracteres';
    }
    return null;
  }

  // Required
  static String? required(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  // Number
  static String? number(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (int.tryParse(value) == null) {
      return 'Debe ser un número válido';
    }
    return null;
  }

  // Positive Number
  static String? positiveNumber(
    String? value, [
    String fieldName = 'Este campo',
  ]) {
    final numberError = number(value, fieldName);
    if (numberError != null) return numberError;

    if (int.parse(value!) <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }

  // Decimal
  static String? decimal(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (double.tryParse(value) == null) {
      return 'Debe ser un número válido';
    }
    return null;
  }

  // Positive Decimal
  static String? positiveDecimal(
    String? value, [
    String fieldName = 'Este campo',
  ]) {
    final decimalError = decimal(value, fieldName);
    if (decimalError != null) return decimalError;

    if (double.parse(value!) <= 0) {
      return 'Debe ser mayor a 0';
    }
    return null;
  }

  // Min Length
  static String? minLength(
    String? value,
    int min, [
    String fieldName = 'Este campo',
  ]) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (value.length < min) {
      return 'Mínimo $min caracteres';
    }
    return null;
  }

  // Max Length
  static String? maxLength(
    String? value,
    int max, [
    String fieldName = 'Este campo',
  ]) {
    if (value != null && value.length > max) {
      return 'Máximo $max caracteres';
    }
    return null;
  }

  // Phone
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^\d{7,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Teléfono inválido';
    }
    return null;
  }

  // Confirm Password
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirme la contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}
