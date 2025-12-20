import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/offline_provider.dart';

/// Ejemplo de cómo usar el sistema offline en un provider existente
/// Este es un wrapper que puede ser usado para cualquier operación CRUD

/// Extension para agregar capacidad offline a providers
extension OfflineCapable on StateNotifierProvider {
  /// Ejemplo de método para crear registro de peso offline
  static Future<bool> createWeightRecordOffline({
    required WidgetRef ref,
    required int flockId,
    required double weight,
    required DateTime date,
    int? sampleSize,
  }) async {
    final isOffline = ref.read(isOfflineModeProvider);

    final data = {
      'flock': flockId,
      'weight': weight,
      'date': date.toIso8601String().split('T')[0],
      'sample_size': sampleSize ?? 10,
    };

    if (isOffline) {
      // Guardar en cola offline
      await ref
          .read(offlineProvider.notifier)
          .addToQueue(
            endpoint: '/flocks/weight/',
            method: 'POST',
            data: data,
            entityType: 'weight_record',
          );

      // Guardar en caché local (opcional, para mostrar en UI)
      final localId = DateTime.now().millisecondsSinceEpoch;
      await ref.read(offlineProvider.notifier).cacheData(
        'weight_record_$localId',
        {...data, 'id': localId, 'status': 'pending'},
      );

      return true;
    } else {
      // Online: intentar enviar directamente
      try {
        // Aquí iría la llamada normal al provider
        // await ref.read(flocksProvider.notifier).createWeightRecord(...);
        return true;
      } catch (e) {
        // Si falla, agregar a cola offline
        await ref
            .read(offlineProvider.notifier)
            .addToQueue(
              endpoint: '/flocks/weight/',
              method: 'POST',
              data: data,
              entityType: 'weight_record',
            );
        return false;
      }
    }
  }

  /// Ejemplo para mortalidad
  static Future<bool> createMortalityRecordOffline({
    required WidgetRef ref,
    required int flockId,
    required int quantity,
    required DateTime date,
    String? cause,
    String? notes,
  }) async {
    final isOffline = ref.read(isOfflineModeProvider);

    final data = {
      'flock': flockId,
      'quantity': quantity,
      'date': date.toIso8601String().split('T')[0],
      'cause': cause ?? 'Unknown',
      'notes': notes,
    };

    if (isOffline) {
      await ref
          .read(offlineProvider.notifier)
          .addToQueue(
            endpoint: '/flocks/mortality/',
            method: 'POST',
            data: data,
            entityType: 'mortality_record',
          );
      return true;
    } else {
      try {
        // Llamada online normal
        return true;
      } catch (e) {
        await ref
            .read(offlineProvider.notifier)
            .addToQueue(
              endpoint: '/flocks/mortality/',
              method: 'POST',
              data: data,
              entityType: 'mortality_record',
            );
        return false;
      }
    }
  }

  /// Ejemplo para ajuste de inventario
  static Future<bool> adjustInventoryOffline({
    required WidgetRef ref,
    required int itemId,
    required double quantity,
    required String adjustmentType, // 'addition' o 'consumption'
    String? notes,
  }) async {
    final isOffline = ref.read(isOfflineModeProvider);

    final data = {
      'item_id': itemId,
      'quantity': quantity,
      'adjustment_type': adjustmentType,
      'notes': notes,
      'date': DateTime.now().toIso8601String(),
    };

    if (isOffline) {
      await ref
          .read(offlineProvider.notifier)
          .addToQueue(
            endpoint: '/inventory/items/$itemId/adjust/',
            method: 'POST',
            data: data,
            entityType: 'inventory_adjustment',
          );
      return true;
    } else {
      try {
        // Llamada online normal
        return true;
      } catch (e) {
        await ref
            .read(offlineProvider.notifier)
            .addToQueue(
              endpoint: '/inventory/items/$itemId/adjust/',
              method: 'POST',
              data: data,
              entityType: 'inventory_adjustment',
            );
        return false;
      }
    }
  }
}

/// Helper para verificar si una operación está en cola
class OfflineHelper {
  static bool hasOffline({required WidgetRef ref, required String entityType}) {
    final pendingItems = ref.read(offlineProvider.notifier).getPendingItems();
    return pendingItems.any((item) => item.entityType == entityType);
  }

  static List<Map<String, dynamic>> getOfflineItems({
    required WidgetRef ref,
    required String entityType,
  }) {
    final pendingItems = ref.read(offlineProvider.notifier).getPendingItems();
    return pendingItems
        .where((item) => item.entityType == entityType)
        .map((item) => item.data)
        .toList();
  }
}
