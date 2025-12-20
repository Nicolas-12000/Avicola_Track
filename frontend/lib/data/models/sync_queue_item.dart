import 'package:hive/hive.dart';

part 'sync_queue_item.g.dart';

/// Item en la cola de sincronización offline
/// Se usa para guardar operaciones pendientes cuando no hay conexión
@HiveType(typeId: 0)
class SyncQueueItem {
  @HiveField(0)
  final String id; // UUID único

  @HiveField(1)
  final String endpoint; // Ejemplo: '/flocks/weight/'

  @HiveField(2)
  final String method; // 'POST', 'PUT', 'PATCH', 'DELETE'

  @HiveField(3)
  final Map<String, dynamic> data; // Datos a enviar

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final int retryCount;

  @HiveField(6)
  final String? errorMessage;

  @HiveField(7)
  final String entityType; // 'weight_record', 'mortality_record', 'inventory_adjustment'

  @HiveField(8)
  final int? localId; // ID temporal local (para referencias)

  SyncQueueItem({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.data,
    required this.createdAt,
    this.retryCount = 0,
    this.errorMessage,
    required this.entityType,
    this.localId,
  });

  SyncQueueItem copyWith({
    String? id,
    String? endpoint,
    String? method,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
    String? errorMessage,
    String? entityType,
    int? localId,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      endpoint: endpoint ?? this.endpoint,
      method: method ?? this.method,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
      entityType: entityType ?? this.entityType,
      localId: localId ?? this.localId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'endpoint': endpoint,
      'method': method,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
      'error_message': errorMessage,
      'entity_type': entityType,
      'local_id': localId,
    };
  }

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'],
      endpoint: json['endpoint'],
      method: json['method'],
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['created_at']),
      retryCount: json['retry_count'] ?? 0,
      errorMessage: json['error_message'],
      entityType: json['entity_type'],
      localId: json['local_id'],
    );
  }
}
