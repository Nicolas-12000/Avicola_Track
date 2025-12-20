import 'dart:async';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/sync_queue_item.dart';
import '../utils/error_handler.dart';

/// Servicio de sincronización offline
/// Gestiona la cola de operaciones pendientes cuando no hay conexión
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final Logger _logger = Logger();
  static const String _queueBoxName = 'sync_queue';
  static const String _cacheBoxName = 'offline_cache';

  Box<SyncQueueItem>? _queueBox;
  Box? _cacheBox;
  Dio? _dio;

  bool _isSyncing = false;
  Timer? _syncTimer;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get onSyncStatusChange => _statusController.stream;

  /// Inicializar Hive y abrir cajas
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Registrar adaptadores
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(SyncQueueItemAdapter());
      }

      // Abrir cajas
      _queueBox = await Hive.openBox<SyncQueueItem>(_queueBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);

      _logger.i(
        'OfflineSyncService initialized. Queue items: ${_queueBox!.length}',
      );
    } catch (e) {
      _logger.e('Error initializing OfflineSyncService: $e');
      rethrow;
    }
  }

  /// Configurar cliente Dio
  void setDioClient(Dio dio) {
    _dio = dio;
  }

  /// Agregar operación a la cola de sincronización
  Future<String> addToQueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> data,
    required String entityType,
    int? localId,
  }) async {
    if (_queueBox == null) {
      ErrorHandler.logError(
        Exception('Queue box is null'),
        context: 'OfflineSyncService not initialized',
        stackTrace: StackTrace.current,
      );
      throw Exception('OfflineSyncService not initialized');
    }

    final id = const Uuid().v4();
    final item = SyncQueueItem(
      id: id,
      endpoint: endpoint,
      method: method,
      data: data,
      createdAt: DateTime.now(),
      entityType: entityType,
      localId: localId,
    );

    await _queueBox!.put(id, item);
    _logger.i('Added to sync queue: $entityType - $method $endpoint');

    _emitStatus();
    return id;
  }

  /// Obtener todos los items pendientes
  List<SyncQueueItem> getPendingItems() {
    if (_queueBox == null) return [];
    return _queueBox!.values.toList();
  }

  /// Obtener conteo de items pendientes
  int get pendingCount => _queueBox?.length ?? 0;

  /// Sincronizar todos los items pendientes
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      _logger.w('Sync already in progress');
      return SyncResult(success: 0, failed: 0, total: 0);
    }

    if (_dio == null) {
      _logger.w('Dio client not set');
      return SyncResult(success: 0, failed: 0, total: 0);
    }

    if (_queueBox == null || _queueBox!.isEmpty) {
      _logger.i('No items to sync');
      return SyncResult(success: 0, failed: 0, total: 0);
    }

    _isSyncing = true;
    _emitStatus();

    final items = getPendingItems();
    int successCount = 0;
    int failedCount = 0;

    _logger.i('Starting sync of ${items.length} items');

    for (final item in items) {
      try {
        await _syncItem(item);
        await _queueBox!.delete(item.id);
        successCount++;
        _logger.i('Synced successfully: ${item.entityType} (${item.id})');
      } catch (e, stackTrace) {
        failedCount++;
        ErrorHandler.logError(
          e,
          context: 'Failed to sync item ${item.id}',
          stackTrace: stackTrace,
        );

        // Incrementar contador de reintentos
        final updatedItem = item.copyWith(
          retryCount: item.retryCount + 1,
          errorMessage: e.toString(),
        );
        await _queueBox!.put(item.id, updatedItem);

        // Si ha fallado muchas veces, eliminar
        if (updatedItem.retryCount >= 5) {
          _logger.w('Item ${item.id} failed 5 times, removing from queue');
          await _queueBox!.delete(item.id);
        }
      }
    }

    _isSyncing = false;
    _emitStatus();

    final result = SyncResult(
      success: successCount,
      failed: failedCount,
      total: items.length,
    );

    _logger.i('Sync completed: ${result.success}/${result.total} successful');
    return result;
  }

  /// Sincronizar un item individual
  Future<void> _syncItem(SyncQueueItem item) async {
    Response response;

    switch (item.method.toUpperCase()) {
      case 'POST':
        response = await _dio!.post(item.endpoint, data: item.data);
        break;
      case 'PUT':
        response = await _dio!.put(item.endpoint, data: item.data);
        break;
      case 'PATCH':
        response = await _dio!.patch(item.endpoint, data: item.data);
        break;
      case 'DELETE':
        response = await _dio!.delete(item.endpoint, data: item.data);
        break;
      default:
        ErrorHandler.logError(
          Exception('Unsupported HTTP method: ${item.method}'),
          context: 'Unsupported HTTP method',
          stackTrace: StackTrace.current,
        );
        throw Exception('Unsupported HTTP method: ${item.method}');
    }

    if (response.statusCode! < 200 || response.statusCode! >= 300) {
      ErrorHandler.logError(
        Exception('HTTP ${response.statusCode}: ${response.statusMessage}'),
        context: 'HTTP error during sync',
        stackTrace: StackTrace.current,
      );
      throw Exception('HTTP ${response.statusCode}: ${response.statusMessage}');
    }
  }

  /// Iniciar sincronización automática periódica
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    stopAutoSync();

    _logger.i('Starting auto-sync every ${interval.inMinutes} minutes');
    _syncTimer = Timer.periodic(interval, (_) async {
      if (_queueBox != null && _queueBox!.isNotEmpty) {
        await syncAll();
      }
    });
  }

  /// Detener sincronización automática
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Guardar datos en caché offline
  Future<void> cacheData(String key, dynamic data) async {
    if (_cacheBox == null) return;
    await _cacheBox!.put(key, data);
  }

  /// Obtener datos de caché
  dynamic getCachedData(String key) {
    return _cacheBox?.get(key);
  }

  /// Limpiar caché
  Future<void> clearCache() async {
    await _cacheBox?.clear();
    _logger.i('Cache cleared');
  }

  /// Eliminar item de la cola
  Future<void> removeFromQueue(String id) async {
    await _queueBox?.delete(id);
    _emitStatus();
  }

  /// Emitir estado actual
  void _emitStatus() {
    _statusController.add(
      SyncStatus(
        isSyncing: _isSyncing,
        pendingCount: pendingCount,
        lastSyncTime: DateTime.now(),
      ),
    );
  }

  /// Dispose
  Future<void> dispose() async {
    stopAutoSync();
    await _queueBox?.close();
    await _cacheBox?.close();
    _statusController.close();
  }
}

/// Estado de sincronización
class SyncStatus {
  final bool isSyncing;
  final int pendingCount;
  final DateTime lastSyncTime;

  SyncStatus({
    required this.isSyncing,
    required this.pendingCount,
    required this.lastSyncTime,
  });
}

/// Resultado de sincronización
class SyncResult {
  final int success;
  final int failed;
  final int total;

  SyncResult({
    required this.success,
    required this.failed,
    required this.total,
  });

  bool get hasErrors => failed > 0;
  double get successRate => total > 0 ? (success / total) : 0.0;
}
