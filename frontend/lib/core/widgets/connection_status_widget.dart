import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Widget que muestra un banner cuando no hay conexión
class ConnectionBanner extends ConsumerWidget {
  final Widget child;
  final bool showWhenConnected;

  const ConnectionBanner({
    super.key,
    required this.child,
    this.showWhenConnected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);

    return Column(
      children: [
        // Banner de conexión
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: connectionState.isConnected && !showWhenConnected ? 0 : null,
          child: connectionState.isConnected && !showWhenConnected
              ? const SizedBox.shrink()
              : _ConnectionStatusBar(state: connectionState),
        ),
        // Contenido principal
        Expanded(child: child),
      ],
    );
  }
}

class _ConnectionStatusBar extends ConsumerWidget {
  final ConnectionState state;

  const _ConnectionStatusBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (color, icon, text) = switch (state.status) {
      ConnectionStatus.connected => (
          Colors.green,
          Icons.wifi,
          'Conectado',
        ),
      ConnectionStatus.noBackend => (
          Colors.orange,
          Icons.cloud_off,
          state.message,
        ),
      ConnectionStatus.noInternet => (
          Colors.red,
          Icons.signal_wifi_off,
          state.message,
        ),
      ConnectionStatus.checking => (
          Colors.blue,
          Icons.sync,
          'Verificando conexión...',
        ),
    };

    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (state.status != ConnectionStatus.checking)
                TextButton(
                  onPressed: () =>
                      ref.read(connectionStateProvider.notifier).refresh(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar el estado de conexión en un AppBar o similar
class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);

    final (color, icon) = switch (connectionState.status) {
      ConnectionStatus.connected => (Colors.green, Icons.wifi),
      ConnectionStatus.noBackend => (Colors.orange, Icons.cloud_off),
      ConnectionStatus.noInternet => (Colors.red, Icons.signal_wifi_off),
      ConnectionStatus.checking => (Colors.blue, Icons.sync),
    };

    return Tooltip(
      message: connectionState.message,
      child: InkWell(
        onTap: () => ref.read(connectionStateProvider.notifier).refresh(),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Widget de overlay para cuando no hay conexión
class NoConnectionOverlay extends ConsumerWidget {
  final Widget child;

  const NoConnectionOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);

    return Stack(
      children: [
        child,
        if (connectionState.isOffline)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.signal_wifi_off,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sin conexión',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          connectionState.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => ref
                              .read(connectionStateProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Wrapper que muestra SnackBar cuando cambia el estado de conexión
class ConnectionSnackBarWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectionSnackBarWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectionSnackBarWrapper> createState() =>
      _ConnectionSnackBarWrapperState();
}

class _ConnectionSnackBarWrapperState
    extends ConsumerState<ConnectionSnackBarWrapper> {
  ConnectionStatus? _lastStatus;

  @override
  Widget build(BuildContext context) {
    ref.listen<ConnectionState>(connectionStateProvider, (previous, next) {
      // Solo mostrar snackbar en cambios de estado significativos
      if (_lastStatus != next.status) {
        _lastStatus = next.status;

        if (next.status == ConnectionStatus.connected &&
            previous?.status != ConnectionStatus.connected) {
          _showSnackBar(
            context,
            'Conexión restaurada',
            Colors.green,
            Icons.wifi,
          );
        } else if (next.status == ConnectionStatus.noInternet) {
          _showSnackBar(
            context,
            'Sin conexión a internet',
            Colors.red,
            Icons.signal_wifi_off,
          );
        } else if (next.status == ConnectionStatus.noBackend) {
          _showSnackBar(
            context,
            'No se puede conectar al servidor',
            Colors.orange,
            Icons.cloud_off,
          );
        }
      }
    });

    return widget.child;
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
