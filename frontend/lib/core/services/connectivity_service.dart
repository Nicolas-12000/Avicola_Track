import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../constants/api_constants.dart';

/// Estado de conectividad detallado
enum ConnectionStatus {
  /// Conectado a internet y al backend
  connected,

  /// Conectado a internet pero sin acceso al backend
  noBackend,

  /// Sin conexión a internet
  noInternet,

  /// Verificando estado de conexión
  checking,
}

/// Información detallada del estado de conexión
class ConnectionState {
  final ConnectionStatus status;
  final String message;
  final DateTime lastChecked;
  final List<ConnectivityResult> connectivityTypes;

  ConnectionState({
    required this.status,
    required this.message,
    required this.lastChecked,
    this.connectivityTypes = const [],
  });

  factory ConnectionState.initial() => ConnectionState(
        status: ConnectionStatus.checking,
        message: 'Verificando conexión...',
        lastChecked: DateTime.now(),
      );

  ConnectionState copyWith({
    ConnectionStatus? status,
    String? message,
    DateTime? lastChecked,
    List<ConnectivityResult>? connectivityTypes,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      message: message ?? this.message,
      lastChecked: lastChecked ?? this.lastChecked,
      connectivityTypes: connectivityTypes ?? this.connectivityTypes,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get hasInternet =>
      status == ConnectionStatus.connected ||
      status == ConnectionStatus.noBackend;
  bool get isOffline => status == ConnectionStatus.noInternet;
}

/// Servicio para gestionar la conectividad
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 10),
    customCheckOptions: [
      InternetCheckOption(uri: Uri.parse('https://cloudflare.com')),
      InternetCheckOption(uri: Uri.parse('https://google.com')),
    ],
  );

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;

  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();

  Stream<ConnectionState> get onStateChange => _stateController.stream;

  ConnectionState _currentState = ConnectionState.initial();
  ConnectionState get currentState => _currentState;

  /// Inicializar el servicio
  Future<void> initialize() async {
    // Verificar estado inicial
    await checkConnection();

    // Escuchar cambios de conectividad
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        await _handleConnectivityChange(results);
      },
    );

    // Escuchar cambios de acceso a internet
    _internetSubscription = _internetChecker.onStatusChange.listen(
      (status) async {
        if (status == InternetStatus.connected) {
          // Verificar si el backend está accesible
          await checkConnection();
        } else {
          _updateState(ConnectionState(
            status: ConnectionStatus.noInternet,
            message: 'Sin conexión a internet',
            lastChecked: DateTime.now(),
            connectivityTypes: _currentState.connectivityTypes,
          ));
        }
      },
    );
  }

  /// Verificar conexión completa (internet + backend)
  Future<ConnectionState> checkConnection() async {
    _updateState(_currentState.copyWith(
      status: ConnectionStatus.checking,
      message: 'Verificando conexión...',
    ));

    try {
      // 1. Verificar conectividad local
      final connectivityResult = await _connectivity.checkConnectivity();
      final hasNetwork = connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      if (!hasNetwork) {
        return _updateState(ConnectionState(
          status: ConnectionStatus.noInternet,
          message: 'Sin conexión a internet. Activa WiFi o datos móviles.',
          lastChecked: DateTime.now(),
          connectivityTypes: connectivityResult,
        ));
      }

      // 2. Verificar acceso a internet real
      final hasInternet = await _internetChecker.hasInternetAccess;
      if (!hasInternet) {
        return _updateState(ConnectionState(
          status: ConnectionStatus.noInternet,
          message: 'Red disponible pero sin acceso a internet.',
          lastChecked: DateTime.now(),
          connectivityTypes: connectivityResult,
        ));
      }

      // 3. Verificar acceso al backend
      final backendReachable = await _checkBackendReachable();
      if (!backendReachable) {
        return _updateState(ConnectionState(
          status: ConnectionStatus.noBackend,
          message: 'Internet OK pero no se puede conectar al servidor.',
          lastChecked: DateTime.now(),
          connectivityTypes: connectivityResult,
        ));
      }

      // Todo OK
      return _updateState(ConnectionState(
        status: ConnectionStatus.connected,
        message: 'Conectado',
        lastChecked: DateTime.now(),
        connectivityTypes: connectivityResult,
      ));
    } catch (e) {
      return _updateState(ConnectionState(
        status: ConnectionStatus.noInternet,
        message: 'Error verificando conexión: $e',
        lastChecked: DateTime.now(),
      ));
    }
  }

  /// Verificar si el backend está accesible
  Future<bool> _checkBackendReachable() async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl);
      final socket = await Socket.connect(
        uri.host,
        uri.port,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Marcar explícitamente que el backend respondió correctamente
  /// Útil para limpiar banners de desconexión después de una respuesta exitosa
  void markBackendReachable() {
    _updateState(
      ConnectionState(
        status: ConnectionStatus.connected,
        message: 'Conectado',
        lastChecked: DateTime.now(),
        connectivityTypes: _currentState.connectivityTypes,
      ),
    );
  }

  /// Manejar cambios de conectividad
  Future<void> _handleConnectivityChange(
    List<ConnectivityResult> results,
  ) async {
    final hasNetwork =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (hasNetwork) {
      // Podríamos tener conexión, verificar completa
      await checkConnection();
    } else {
      _updateState(ConnectionState(
        status: ConnectionStatus.noInternet,
        message: 'Conexión perdida',
        lastChecked: DateTime.now(),
        connectivityTypes: results,
      ));
    }
  }

  /// Actualizar estado y notificar
  ConnectionState _updateState(ConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
    return newState;
  }

  /// Obtener descripción del tipo de conexión
  String getConnectionTypeDescription() {
    final types = _currentState.connectivityTypes;
    if (types.isEmpty) return 'Desconocido';

    final descriptions = types.map((type) {
      switch (type) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Datos móviles';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.other:
          return 'Otro';
        case ConnectivityResult.none:
          return 'Sin conexión';
      }
    }).toList();

    return descriptions.join(', ');
  }

  /// Liberar recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
    _stateController.close();
  }
}

/// Provider del servicio de conectividad
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider del estado de conexión
final connectionStateProvider =
    StateNotifierProvider<ConnectionStateNotifier, ConnectionState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return ConnectionStateNotifier(service);
});

/// Notifier para gestionar el estado de conexión
class ConnectionStateNotifier extends StateNotifier<ConnectionState> {
  final ConnectivityService _service;
  StreamSubscription<ConnectionState>? _subscription;

  ConnectionStateNotifier(this._service) : super(ConnectionState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    await _service.initialize();
    state = _service.currentState;

    _subscription = _service.onStateChange.listen((newState) {
      state = newState;
    });
  }

  Future<void> refresh() async {
    await _service.checkConnection();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
