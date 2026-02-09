import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/offline_sync_service.dart';
import '../services/connectivity_service.dart';
import '../network/dio_client.dart';
import '../utils/error_handler.dart';
import '../../data/models/sync_queue_item.dart';

/// Estado del sistema offline
class OfflineState {
  final bool isInitialized;
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final SyncResult? lastSyncResult;
  final String? error;

  OfflineState({
    this.isInitialized = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastSyncResult,
    this.error,
  });

  OfflineState copyWith({
    bool? isInitialized,
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    SyncResult? lastSyncResult,
    String? error,
  }) {
    return OfflineState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncResult: lastSyncResult ?? this.lastSyncResult,
      error: error,
    );
  }

  bool get hasPendingItems => pendingCount > 0;
}

/// Provider del servicio offline
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

/// Provider del estado offline
final offlineProvider = StateNotifierProvider<OfflineNotifier, OfflineState>((
  ref,
) {
  final service = ref.watch(offlineSyncServiceProvider);
  final dio = ref.watch(dioProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineNotifier(service, dio, connectivity);
});

/// Notifier para gestionar el estado offline
class OfflineNotifier extends StateNotifier<OfflineState> {
  final OfflineSyncService _service;
  final Dio _dio;
  final ConnectivityService _connectivity;

  OfflineNotifier(this._service, this._dio, this._connectivity)
      : super(OfflineState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
      _service.setDioClient(_dio);

      // Intentar sincronizar apenas se detecte conexión
      _connectivity.onStateChange.listen((stateChange) {
        final isOnline = stateChange.isConnected;
        if (isOnline && _service.pendingCount > 0 && !state.isSyncing) {
          syncNow();
        }
      });

      state = state.copyWith(
        isInitialized: true,
        pendingCount: _service.pendingCount,
      );

      // Escuchar cambios en el estado de sincronización
      _service.onSyncStatusChange.listen((status) {
        state = state.copyWith(
          isSyncing: status.isSyncing,
          pendingCount: status.pendingCount,
          lastSyncTime: status.lastSyncTime,
        );
      });

      // Iniciar auto-sync
      _service.startAutoSync();

      // Si hay items pendientes y hay conexión, sincronizar inmediatamente
      if (_service.pendingCount > 0 && _connectivity.currentState.isConnected) {
        ErrorHandler.logInfo('🔄 Pending items detected at startup, triggering sync...');
        unawaited(syncNow());
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Agregar operación a la cola
  Future<String> addToQueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    required String entityType,
    int? localId,
  }) async {
    final id = await _service.addToQueue(
      endpoint: endpoint,
      method: method,
      data: data,
      entityType: entityType,
      localId: localId,
    );

    state = state.copyWith(pendingCount: _service.pendingCount);

    // Si ya hay conexión, dispara sync inmediata para no esperar al cron
    if (_connectivity.currentState.isConnected && !state.isSyncing) {
      unawaited(syncNow());
    }
    return id;
  }

  /// Sincronizar manualmente
  Future<void> syncNow() async {
    if (state.isSyncing) {
      ErrorHandler.logInfo('🔄 syncNow called but already syncing, skipping');
      return;
    }

    ErrorHandler.logInfo('🚀 syncNow triggered - starting sync process');
    state = state.copyWith(isSyncing: true);

    try {
      final result = await _service.syncAll();
      ErrorHandler.logInfo('✅ Sync completed: ${result.success} success, ${result.failed} failed');
      state = state.copyWith(
        isSyncing: false,
        lastSyncResult: result,
        lastSyncTime: DateTime.now(),
        pendingCount: _service.pendingCount,
      );
    } catch (e) {
      ErrorHandler.logError('Sync failed: $e');
      state = state.copyWith(isSyncing: false, error: e.toString());
    }
  }

  /// Obtener items pendientes
  List<SyncQueueItem> getPendingItems() {
    return _service.getPendingItems();
  }

  /// Guardar en caché
  Future<void> cacheData(String key, dynamic data) async {
    await _service.cacheData(key, data);
  }

  /// Obtener de caché
  dynamic getCachedData(String key) {
    return _service.getCachedData(key);
  }

  /// Limpiar caché
  Future<void> clearCache() async {
    await _service.clearCache();
  }

  /// Eliminar item de la cola
  Future<void> removeItem(String id) async {
    await _service.removeFromQueue(id);
    state = state.copyWith(pendingCount: _service.pendingCount);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// Provider para verificar si hay conexión
final hasInternetProvider = StateProvider<bool>((ref) => true);

/// Provider para modo offline
final isOfflineModeProvider = Provider<bool>((ref) {
  final hasInternet = ref.watch(hasInternetProvider);
  return !hasInternet;
});
