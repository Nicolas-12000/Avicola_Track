import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/notifications_service.dart';
import '../network/dio_client.dart';

/// Estado de notificaciones
class NotificationsState {
  final List<BackendNotification> notifications;
  final bool isInitialized;
  final bool isPolling;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isInitialized = false,
    this.isPolling = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  NotificationsState copyWith({
    List<BackendNotification>? notifications,
    bool? isInitialized,
    bool? isPolling,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isInitialized: isInitialized ?? this.isInitialized,
      isPolling: isPolling ?? this.isPolling,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
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
  static const int _pageSize = 5;

  NotificationsNotifier(this._service, this._dio)
    : super(NotificationsState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize(_dio);

      state = state.copyWith(isInitialized: true);

      // Escuchar nuevas notificaciones del polling (unread stream)
      _service.onNotifications.listen((notifications) {
        // Only update unread count tracking, don't overwrite the paginated list
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

  /// Obtener primera página de notificaciones recientes
  Future<void> fetchRecentNotifications() async {
    try {
      final result = await _service.fetchRecentNotificationsPaginated(
        page: 1,
        pageSize: _pageSize,
      );
      final list = result['notifications'] as List<BackendNotification>;
      state = state.copyWith(
        notifications: list,
        hasMore: result['has_next'] as bool,
        currentPage: 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Cargar siguiente bloque de notificaciones
  Future<void> loadMoreNotifications() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _service.fetchRecentNotificationsPaginated(
        page: nextPage,
        pageSize: _pageSize,
      );
      final list = result['notifications'] as List<BackendNotification>;
      state = state.copyWith(
        notifications: [...state.notifications, ...list],
        hasMore: result['has_next'] as bool,
        currentPage: nextPage,
        isLoadingMore: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// Marcar una notificación como leída
  Future<void> markRead(int id) async {
    final ok = await _service.markNotificationRead(id);
    if (ok) {
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) {
            return BackendNotification(
              id: n.id,
              alarmId: n.alarmId,
              alarmDetails: n.alarmDetails,
              notificationType: n.notificationType,
              status: n.status,
              createdAt: n.createdAt,
              readAt: DateTime.now(),
              isRead: true,
            );
          }
          return n;
        }).toList(),
      );
    }
  }

  /// Eliminar una notificación (swipe to dismiss)
  Future<void> deleteNotification(int id) async {
    // Optimistic removal
    final removed = state.notifications.where((n) => n.id == id).toList();
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
    final ok = await _service.deleteNotification(id);
    if (!ok && removed.isNotEmpty) {
      // Rollback on failure
      state = state.copyWith(
        notifications: [...state.notifications, ...removed]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllRead() async {
    final ok = await _service.markAllRead();
    if (ok) {
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          return BackendNotification(
            id: n.id,
            alarmId: n.alarmId,
            alarmDetails: n.alarmDetails,
            notificationType: n.notificationType,
            status: n.status,
            createdAt: n.createdAt,
            readAt: DateTime.now(),
            isRead: true,
          );
        }).toList(),
      );
    }
  }

  /// Limpiar notificaciones (al cerrar sesión)
  void clearNotifications() {
    _service.clearShownNotifications();
    state = state.copyWith(notifications: [], currentPage: 0, hasMore: true);
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
  return notificationsState.notifications.where((n) => !n.isRead).length;
});
