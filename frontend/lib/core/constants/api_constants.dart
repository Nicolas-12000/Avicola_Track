class ApiConstants {
  ApiConstants._();

  // Base URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // CAMBIO: Usa la IP de tu PC para que el celular pueda conectar. Ejemplo: 192.168.1.15
    defaultValue: 'http://192.168.0.18:8000/',
  );

  // API Endpoints
  static const String apiPrefix = '/api';

  // Auth
  static const String login = '$apiPrefix/auth/login/';
  static const String refreshToken = '$apiPrefix/auth/refresh/';
  static const String register = '$apiPrefix/auth/register/';
  static const String passwordReset = '$apiPrefix/auth/password-reset/';
  static const String passwordResetConfirm =
      '$apiPrefix/auth/password-reset-confirm/';

  // Users
  static const String users = '$apiPrefix/admin-users/';
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
  static String reportDetail(int id) => '${reports}$id/';
  static const String reportGenerate = '${reports}generate/';
  static String reportDownload(int id) => '${reports}$id/download/';
  static const String reportTypes = '${reports}types/';
  static const String quickProductivity = '${reports}quick_productivity/';
  static const String reportTemplates = '$apiPrefix/templates/';

  // Veterinary
  static const String veterinary = '$apiPrefix/veterinary/';
  static const String veterinaryVisits = '$veterinary/visits/';
  static String veterinaryVisitDetail(int id) => '$veterinaryVisits$id/';
  static String veterinaryVisitComplete(int id) =>
      '$veterinaryVisits$id/complete/';
  static const String veterinaryVisitsTodayUpcoming =
      '$veterinaryVisits/today_upcoming/';
  static const String vaccinations = '$veterinary/vaccinations/';
  static String vaccinationDetail(int id) => '$vaccinations$id/';
  static String vaccinationApply(int id) => '$vaccinations$id/apply/';
  static const String vaccinationsUpcoming = '$vaccinations/upcoming/';
  static const String medications = '$veterinary/medications/';
  static String medicationDetail(int id) => '$medications$id/';
  static String medicationRecordApplication(int id) =>
      '$medications$id/record_application/';
  static const String medicationsActive = '$medications/active/';
  static const String medicationsWithdrawal = '$medications/withdrawal/';
  static const String diseases = '$veterinary/diseases/';
  static String diseaseDetail(int id) => '$diseases$id/';
  static const String biosecurityChecklists =
      '$veterinary/biosecurity-checklists/';
  static String biosecurityChecklistDetail(int id) =>
      '$biosecurityChecklists$id/';
  static const String biosecurityComplianceStats =
      '$biosecurityChecklists/compliance_stats/';

  // Alarms - endpoints adicionales
  static const String alarmsDashboard = '${alarms}dashboard/';
  static String alarmAcknowledge(int id) => '${alarms}$id/acknowledge/';
  static const String alarmsBulkAcknowledge = '${alarms}bulk-acknowledge/';
  static const String notificationsUnread = '$apiPrefix/notifications/unread/';
  static const String notificationsRecent = '$apiPrefix/notifications/recent/';

  // Flocks - endpoints adicionales
  static const String flocksDashboard = '$apiPrefix/dashboard/';
  static const String flocksImportExcel = '$flocks/import-excel/';
  static const String breedReferences = '$apiPrefix/references/';

  // Inventory - endpoints adicionales
  static const String inventoryStockAlerts = '$inventory/stock-alerts/';
  static const String inventoryBulkUpdateStock =
      '$inventory/bulk-update-stock/';
  static String inventoryConsumeFifo(int id) => '$inventory$id/consume-fifo/';
  static String inventoryFifoBatches(int id) => '$inventory$id/fifo-batches/';

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
