import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/notifications_service.dart';
import '../network/dio_client.dart';

/// Estado de notificaciones
class NotificationsState {
  final List<BackendNotification> notifications;
  final bool isInitialized;
  final bool isPolling;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isInitialized = false,
    this.isPolling = false,
    this.error,
  });

  NotificationsState copyWith({
    List<BackendNotification>? notifications,
    bool? isInitialized,
    bool? isPolling,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      isPolling: isPolling ?? this.isPolling,
      error: error,
    );
  }
}

/// Provider del servicio de notificaciones
final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

/// Provider de estado de notificaciones
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
      final service = ref.watch(notificationsServiceProvider);
      final dio = ref.watch(dioProvider);
      return NotificationsNotifier(service, dio);
    });

/// Notifier para gestionar notificaciones
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationsService _service;
  final Dio _dio;

  NotificationsNotifier(this._service, this._dio)
    : super(NotificationsState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize(_dio);

      state = state.copyWith(isInitialized: true);

      // Escuchar nuevas notificaciones del polling
      _service.onNotifications.listen((notifications) {
        state = state.copyWith(notifications: notifications);
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Iniciar polling cuando el usuario está autenticado
  void startPolling() {
    if (!state.isPolling) {
      _service.startPolling();
      state = state.copyWith(isPolling: true);
    }
  }

  /// Detener polling (al cerrar sesión o salir de la app)
  void stopPolling() {
    if (state.isPolling) {
      _service.stopPolling();
      state = state.copyWith(isPolling: false);
    }
  }

  /// Obtener notificaciones recientes manualmente
  Future<void> fetchRecentNotifications() async {
    try {
      final notifications = await _service.fetchRecentNotifications();
      state = state.copyWith(notifications: notifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Limpiar notificaciones (al cerrar sesión)
  void clearNotifications() {
    _service.clearShownNotifications();
    state = state.copyWith(notifications: []);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Provider para contar notificaciones no leídas
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsState = ref.watch(notificationsProvider);
  return notificationsState.notifications.length;
});
