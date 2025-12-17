import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateTimeHelper {
  DateTimeHelper._();

  // Format DateTime to display
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat(AppConstants.timeFormat).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  // Format for API
  static String formatForApi(DateTime date) {
    return DateFormat(AppConstants.apiDateFormat).format(date);
  }

  // Parse from API
  static DateTime? parseFromApi(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Relative time (hace 2 horas, ayer, etc.)
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Hace ${difference.inSeconds}s';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return formatDate(date);
    }
  }

  // Age in days
  static int ageInDays(DateTime birthDate) {
    final now = DateTime.now();
    return now.difference(birthDate).inDays;
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  // Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
