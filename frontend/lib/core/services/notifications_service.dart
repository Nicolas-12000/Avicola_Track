import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

/// Modelo de notificación del backend
class BackendNotification {
  final int id;
  final int? alarmId;
  final Map<String, dynamic>? alarmDetails;
  final String notificationType;
  final String status;
  final DateTime createdAt;

  BackendNotification({
    required this.id,
    this.alarmId,
    this.alarmDetails,
    required this.notificationType,
    required this.status,
    required this.createdAt,
  });

  factory BackendNotification.fromJson(Map<String, dynamic> json) {
    return BackendNotification(
      id: json['id'],
      alarmId: json['alarm'],
      alarmDetails: json['alarm_details'],
      notificationType: json['notification_type'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get title {
    if (alarmDetails != null) {
      final priority = alarmDetails!['priority'] ?? '';
      final type = alarmDetails!['type'] ?? '';
      return '$type - Prioridad: $priority';
    }
    return 'Notificación';
  }

  String get body {
    return alarmDetails?['description'] ?? 'Nueva notificación';
  }

  String get priorityEmoji {
    final priority = alarmDetails?['priority']?.toString().toLowerCase();
    if (priority == 'high' || priority == 'critical') return '🔴';
    if (priority == 'medium') return '🟡';
    return '🟢';
  }
}

/// Servicio de notificaciones nativo (sin Firebase)
/// Usa polling periódico al backend y notificaciones locales
class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Timer? _pollingTimer;
  final Set<int> _shownNotificationIds = {};

  final StreamController<List<BackendNotification>> _notificationsController =
      StreamController<List<BackendNotification>>.broadcast();
  Stream<List<BackendNotification>> get onNotifications =>
      _notificationsController.stream;

  List<BackendNotification> _currentNotifications = [];
  List<BackendNotification> get currentNotifications => _currentNotifications;

  Dio? _dio;

  /// Inicializar el servicio
  Future<void> initialize(Dio dio) async {
    _dio = dio;

    try {
      await _initializeLocalNotifications();
      _logger.i('NotificationsService initialized successfully');
    } catch (e) {
      _logger.e('Error initializing NotificationsService: $e');
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'avicolatrack_alarms',
      'Alarmas AvícolaTrack',
      description: 'Notificaciones de alarmas y eventos importantes',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Iniciar polling periódico (cada 30 segundos cuando hay conexión)
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    stopPolling(); // Detener polling anterior si existe

    _logger.i('Starting notifications polling every ${interval.inSeconds}s');

    // Hacer primera llamada inmediata
    _fetchNotifications();

    // Iniciar timer periódico
    _pollingTimer = Timer.periodic(interval, (_) {
      _fetchNotifications();
    });
  }

  /// Detener polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _logger.i('Notifications polling stopped');
  }

  /// Obtener notificaciones del backend
  Future<void> _fetchNotifications() async {
    if (_dio == null) {
      _logger.w('Dio not initialized, skipping fetch');
      return;
    }

    try {
      final response = await _dio!.get(ApiConstants.notificationsUnread);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> notificationsList = data['notifications'] ?? [];

        final notifications = notificationsList
            .map((json) => BackendNotification.fromJson(json))
            .toList();

        _currentNotifications = notifications;
        _notificationsController.add(notifications);

        // Mostrar notificaciones nuevas
        for (final notification in notifications) {
          if (!_shownNotificationIds.contains(notification.id)) {
            await _showLocalNotification(notification);
            _shownNotificationIds.add(notification.id);
          }
        }

        _logger.d('Fetched ${notifications.length} notifications');
      }
    } catch (e) {
      _logger.e('Error fetching notifications: $e');
      // No hacer nada en caso de error (modo silencioso para polling)
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(BackendNotification notification) async {
    try {
      await _localNotifications.show(
        notification.id,
        '${notification.priorityEmoji} ${notification.title}',
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'avicolatrack_alarms',
            'Alarmas AvícolaTrack',
            channelDescription:
                'Notificaciones de alarmas y eventos importantes',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: notification.alarmId?.toString(),
      );

      _logger.i('Showed notification: ${notification.title}');
    } catch (e) {
      _logger.e('Error showing notification: $e');
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    // La navegación se maneja desde el UI cuando el usuario toca la notificación
  }

  /// Obtener notificaciones recientes (últimos 7 días)
  Future<List<BackendNotification>> fetchRecentNotifications() async {
    if (_dio == null) return [];

    try {
      final response = await _dio!.get(ApiConstants.notificationsRecent);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> notificationsList = data['notifications'] ?? [];

        return notificationsList
            .map((json) => BackendNotification.fromJson(json))
            .toList();
      }
    } catch (e) {
      _logger.e('Error fetching recent notifications: $e');
    }

    return [];
  }

  /// Limpiar notificaciones mostradas (al cerrar sesión)
  void clearShownNotifications() {
    _shownNotificationIds.clear();
    _currentNotifications = [];
    _notificationsController.add([]);
  }

  /// Dispose
  void dispose() {
    stopPolling();
    _notificationsController.close();
  }
}
