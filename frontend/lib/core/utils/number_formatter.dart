import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  // Format number with thousands separator
  static String formatNumber(num number, {int decimals = 0}) {
    final formatter = NumberFormat(
      '#,###${decimals > 0 ? '.${'0' * decimals}' : ''}',
      'es_ES',
    );
    return formatter.format(number);
  }

  // Format percentage
  static String formatPercentage(num value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Format currency
  static String formatCurrency(
    num value, {
    String symbol = '\$',
    int decimals = 2,
  }) {
    final formatted = formatNumber(value, decimals: decimals);
    return '$symbol$formatted';
  }

  // Format weight (kg)
  static String formatWeight(num value, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)} kg';
  }

  // Format with unit
  static String formatWithUnit(num value, String unit, {int decimals = 2}) {
    return '${value.toStringAsFixed(decimals)} $unit';
  }

  // Compact number (1K, 1M, etc.)
  static String formatCompact(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  // Parse from string
  static double? parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  static int? parseInt(String? value) {
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }
}
