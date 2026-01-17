import 'package:flutter/material.dart';

/// Sistema de colores empresarial de AvícolaTrack
class AppColors {
  AppColors._();

  // ==================== TEMA CLARO ====================

  // Primarios - Azul Profesional (Confianza, Estabilidad)
  static const Color primary = Color(0xFFE10600);
  static const Color primaryLight = Color(0xFFE10600);
  static const Color primaryDark = Color(0xFFB00400);

  // Secundarios - Verde Avícola (Naturaleza, Vida)
  static const Color secondary = Color(0xFF000000);
  static const Color secondaryLight = Color(0xFF4A4A4A);
  static const Color secondaryDark = Color(0xFF000000);

  // Acento - Naranja Energético (CTAs, Alertas)
  static const Color accent = Color(0xFFB00400);
  static const Color accentLight = Color(0xFFE10600);
  static const Color accentDark = Color(0xFFB00400);

  // Fondos y Superficies
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF2F2F2);

  // Textos
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Estados Semánticos
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF17A2B8);

  // ==================== TEMA OSCURO ====================

  // Primarios Oscuro
  static const Color darkPrimary = Color(0xFF4A90E2);
  static const Color darkPrimaryLight = Color(0xFF5AA1F3);
  static const Color darkPrimaryDark = Color(0xFF3A7FD1);

  // Fondos Oscuro
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);

  // Textos Oscuro
  static const Color darkTextPrimary = Color(0xFFE8EAED);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextDisabled = Color(0xFF6C757D);

  // ==================== COLORES ESPECIALES ====================

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardShadowHover => [
    BoxShadow(
      color: textPrimary.withValues(alpha: 0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
