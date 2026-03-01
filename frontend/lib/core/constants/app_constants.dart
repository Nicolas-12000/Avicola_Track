class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AvícolaTrack';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String storageKeyToken = 'auth_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUser = 'user_data';
  static const String storageKeyTheme = 'theme_mode';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyBiometric = 'biometric_enabled';
  static const String storageKeyRememberMe = 'remember_me';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Validation
  static const int minPasswordLength = 7;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Debounce
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // Refresh
  static const Duration autoRefreshInterval = Duration(minutes: 5);

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 1);
  static const Duration offlineDataRetention = Duration(days: 30);

  // Roles
  static const String roleAdmin = 'Administrador';
  static const String roleFarmManager = 'Administrador de Granja';
  static const String roleWorker = 'Galponero';
  static const String roleVet = 'Veterinario';

  // Status
  static const String statusActive = 'ACTIVE';
  static const String statusSold = 'SOLD';
  static const String statusFinished = 'FINISHED';
  static const String statusTransferred = 'TRANSFERRED';

  // Alarm Types
  static const String alarmMortality = 'MORTALITY';
  static const String alarmWeight = 'WEIGHT';
  static const String alarmStock = 'STOCK';
  static const String alarmConsumption = 'CONSUMPTION';

  // Date Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';

  // File Limits
  static const int maxImageSizeMB = 5;
  static const int maxDocumentSizeMB = 10;
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];
  static const List<String> allowedDocumentExtensions = [
    'pdf',
    'xlsx',
    'xls',
    'csv',
  ];
}
