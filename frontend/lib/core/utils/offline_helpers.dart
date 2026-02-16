import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/providers/offline_provider.dart';

/// Ejemplo de cómo usar el sistema offline en un provider existente
/// Este es un wrapper que puede ser usado para cualquier operación CRUD

/// Extension para agregar capacidad offline a providers
extension OfflineCapable on StateNotifierProvider {
  /// Método para crear registro diario offline (unificado: peso + mortalidad + alimento)
  static Future<bool> createDailyRecordOffline({
    required WidgetRef ref,
    required int flockId,
    required DateTime date,
    Map<String, dynamic>? extraFields,
  }) async {
    final isOffline = ref.read(isOfflineModeProvider);

    final data = {
      'flock': flockId,
      'record_date': date.toIso8601String().split('T')[0],
      ...?extraFields,
    };

    if (isOffline) {
      await ref
          .read(offlineProvider.notifier)
          .addToQueue(
            endpoint: ApiConstants.dailyRecords,
            method: 'POST',
            data: data,
            entityType: 'daily_record',
          );
      return true;
    } else {
      try {
        return true;
      } catch (e) {
        await ref
            .read(offlineProvider.notifier)
            .addToQueue(
            endpoint: ApiConstants.dailyRecords,
              method: 'POST',
              data: data,
              entityType: 'daily_record',
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
            endpoint: '${ApiConstants.inventoryDetail(itemId)}adjust-stock/',
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
            endpoint: '${ApiConstants.inventoryDetail(itemId)}adjust-stock/',
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
