import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Base font family
  static const String _fontFamily = 'Inter';

  static TextTheme get textTheme => const TextTheme(
    // Display (Headings grandes)
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.2,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.3,
    ),

    // Headline (Títulos de sección)
    headlineLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.3,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.4,
    ),

    // Title (Títulos de cards/items)
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.4,
    ),

    // Body (Texto normal)
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
      fontFamily: _fontFamily,
      height: 1.5,
    ),

    // Label (Botones, chips)
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      fontFamily: _fontFamily,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      fontFamily: _fontFamily,
      letterSpacing: 0.1,
    ),
  );

  // Estilos personalizados
  static const TextStyle kpiValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: _fontFamily,
    letterSpacing: -0.5,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: _fontFamily,
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: _fontFamily,
    letterSpacing: 0.5,
  );
}
