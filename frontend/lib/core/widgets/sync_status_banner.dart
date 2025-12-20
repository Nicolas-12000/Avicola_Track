import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../providers/offline_provider.dart';

/// Widget que muestra el estado de sincronización
/// Se muestra en la parte superior de la pantalla cuando hay items pendientes
class SyncStatusBanner extends ConsumerWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineProvider);
    final isOffline = ref.watch(isOfflineModeProvider);

    // No mostrar nada si no hay items pendientes y hay conexión
    if (!offlineState.hasPendingItems &&
        !isOffline &&
        !offlineState.isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(offlineState, isOffline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _getIcon(offlineState, isOffline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTitle(offlineState, isOffline),
                  style: AppTextStyles.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_getSubtitle(offlineState) != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getSubtitle(offlineState)!,
                    style: AppTextStyles.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (offlineState.hasPendingItems && !offlineState.isSyncing) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => ref.read(offlineProvider.notifier).syncNow(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('Sincronizar'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor(OfflineState state, bool isOffline) {
    if (state.isSyncing) {
      return AppColors.info; // Azul para sincronizando
    } else if (isOffline) {
      return AppColors.error; // Rojo para sin conexión
    } else if (state.hasPendingItems) {
      return AppColors.warning; // Amarillo para pendientes
    } else {
      return AppColors.success; // Verde para sincronizado
    }
  }

  Widget _getIcon(OfflineState state, bool isOffline) {
    if (state.isSyncing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (isOffline) {
      return const Icon(Icons.cloud_off, color: Colors.white, size: 20);
    } else if (state.hasPendingItems) {
      return const Icon(Icons.cloud_upload, color: Colors.white, size: 20);
    } else {
      return const Icon(Icons.cloud_done, color: Colors.white, size: 20);
    }
  }

  String _getTitle(OfflineState state, bool isOffline) {
    if (state.isSyncing) {
      return 'Sincronizando...';
    } else if (isOffline) {
      return 'Sin conexión';
    } else if (state.hasPendingItems) {
      return '${state.pendingCount} ${state.pendingCount == 1 ? 'acción pendiente' : 'acciones pendientes'}';
    } else {
      return 'Sincronizado';
    }
  }

  String? _getSubtitle(OfflineState state) {
    if (state.isSyncing) {
      return 'Subiendo cambios al servidor...';
    } else if (state.hasPendingItems && state.lastSyncTime != null) {
      final minutes = DateTime.now().difference(state.lastSyncTime!).inMinutes;
      return 'Último intento: hace $minutes min';
    }
    return null;
  }
}

/// Widget compacto para mostrar en AppBar
class CompactSyncIndicator extends ConsumerWidget {
  const CompactSyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineState = ref.watch(offlineProvider);
    final isOffline = ref.watch(isOfflineModeProvider);

    if (!offlineState.hasPendingItems &&
        !isOffline &&
        !offlineState.isSyncing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getColor(offlineState, isOffline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (offlineState.isSyncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Icon(
              _getIcon(offlineState, isOffline),
              color: Colors.white,
              size: 14,
            ),
          if (offlineState.hasPendingItems) ...[
            const SizedBox(width: 4),
            Text(
              '${offlineState.pendingCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getColor(OfflineState state, bool isOffline) {
    if (state.isSyncing) {
      return AppColors.info;
    } else if (isOffline) {
      return AppColors.error;
    } else if (state.hasPendingItems) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  IconData _getIcon(OfflineState state, bool isOffline) {
    if (isOffline) {
      return Icons.cloud_off;
    } else if (state.hasPendingItems) {
      return Icons.cloud_upload;
    } else {
      return Icons.cloud_done;
    }
  }
}
