class ApiConstants {
  ApiConstants._();

  // Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // API Endpoints
  static const String apiPrefix = '/api';

  // Auth
  static const String login = '$apiPrefix/users/token/';
  static const String refreshToken = '$apiPrefix/users/token/refresh/';
  static const String register = '$apiPrefix/users/register/';
  static const String passwordReset = '$apiPrefix/users/password-reset/';
  static const String passwordResetConfirm =
      '$apiPrefix/users/password-reset-confirm/';

  // Users
  static const String users = '$apiPrefix/users/';
  static String userDetail(int id) => '$users$id/';

  // Farms
  static const String farms = '$apiPrefix/farms/';
  static String farmDetail(int id) => '$farms$id/';
  static String farmSheds(int farmId) => '$farms$farmId/sheds/';

  // Sheds
  static const String sheds = '$apiPrefix/sheds/';
  static String shedDetail(int id) => '$sheds$id/';

  // Flocks
  static const String flocks = '$apiPrefix/flocks/';
  static String flockDetail(int id) => '$flocks$id/';
  static String flockWeightRecords(int flockId) =>
      '$flocks$flockId/weight-records/';
  static String flockMortalityRecords(int flockId) =>
      '$flocks$flockId/mortality-records/';

  // Inventory
  static const String inventory = '$apiPrefix/inventory/';
  static String inventoryDetail(int id) => '$inventory$id/';
  static String inventoryConsume(int id) => '$inventory$id/consume/';
  static String inventoryAddStock(int id) => '$inventory$id/add-stock/';

  // Alarms
  static const String alarms = '$apiPrefix/alarms/';
  static String alarmDetail(int id) => '$alarms$id/';
  static String alarmResolve(int id) => '$alarms$id/resolve/';
  static const String alarmConfigurations = '$apiPrefix/alarm-configurations/';

  // Reports
  static const String reports = '$apiPrefix/reports/';
  static String reportDetail(int id) => '$reports$id/';
  static String reportGenerate = '$reports/generate/';
  static String reportDownload(int id) => '$reports$id/download/';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
