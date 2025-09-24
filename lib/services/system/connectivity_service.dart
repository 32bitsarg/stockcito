import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/connectivity_enums.dart';

/// Información detallada de conectividad
class ConnectivityInfo {
  final ConnectivityStatus status;
  final NetworkType networkType;
  final DateTime timestamp;
  final bool hasInternet;
  final String? errorMessage;

  const ConnectivityInfo({
    required this.status,
    required this.networkType,
    required this.timestamp,
    required this.hasInternet,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'ConnectivityInfo(status: $status, networkType: $networkType, hasInternet: $hasInternet, timestamp: $timestamp)';
  }
}

/// Servicio de conectividad inteligente con detección automática y manejo de cambios
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Estado actual
  ConnectivityInfo _currentInfo = ConnectivityInfo(
    status: ConnectivityStatus.unknown,
    networkType: NetworkType.none,
    timestamp: DateTime.now(),
    hasInternet: false,
  );

  // Streams para notificar cambios
  final StreamController<ConnectivityInfo> _connectivityController = 
      StreamController<ConnectivityInfo>.broadcast();
  
  // Callbacks para diferentes eventos
  final List<VoidCallback> _onOnlineCallbacks = [];
  final List<VoidCallback> _onOfflineCallbacks = [];
  final List<VoidCallback> _onReconnectCallbacks = [];

  // Configuración
  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _timeoutDuration = Duration(seconds: 10);
  
  Timer? _periodicCheckTimer;
  bool _isInitialized = false;

  /// Stream de cambios de conectividad
  Stream<ConnectivityInfo> get connectivityStream => _connectivityController.stream;

  /// Estado actual de conectividad
  ConnectivityInfo get currentInfo => _currentInfo;

  /// Verifica si está online
  bool get isOnline => _currentInfo.status == ConnectivityStatus.online;

  /// Verifica si está offline
  bool get isOffline => _currentInfo.status == ConnectivityStatus.offline;

  /// Verifica si tiene internet real (no solo conexión de red)
  bool get hasInternet => _currentInfo.hasInternet;

  /// Inicializa el servicio de conectividad
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      LoggingService.info('🔌 Inicializando ConnectivityService...');

      // Verificar estado inicial
      await _checkInitialConnectivity();

      // Configurar listener de cambios de conectividad
      _setupConnectivityListener();

      // Configurar verificación periódica
      _setupPeriodicCheck();

      _isInitialized = true;
      LoggingService.info('✅ ConnectivityService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando ConnectivityService: $e');
      rethrow;
    }
  }

  /// Verifica el estado inicial de conectividad
  Future<void> _checkInitialConnectivity() async {
    try {
      LoggingService.info('🔍 Verificando conectividad inicial...');
      
      final connectivityResults = await _connectivity.checkConnectivity();
      final networkType = _mapConnectivityToNetworkType(connectivityResults);
      
      // Verificar si realmente tiene internet
      final hasInternet = await _testInternetConnection();
      
      final newInfo = ConnectivityInfo(
        status: hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
        networkType: networkType,
        timestamp: DateTime.now(),
        hasInternet: hasInternet,
      );

      await _updateConnectivityInfo(newInfo);
      LoggingService.info('📊 Estado inicial: ${newInfo.status} (${newInfo.networkType})');
    } catch (e) {
      LoggingService.error('❌ Error verificando conectividad inicial: $e');
      final errorInfo = ConnectivityInfo(
        status: ConnectivityStatus.unknown,
        networkType: NetworkType.none,
        timestamp: DateTime.now(),
        hasInternet: false,
        errorMessage: e.toString(),
      );
      await _updateConnectivityInfo(errorInfo);
    }
  }

  /// Configura el listener de cambios de conectividad
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        LoggingService.error('❌ Error en listener de conectividad: $error');
      },
    );
  }

  /// Configura la verificación periódica de conectividad
  void _setupPeriodicCheck() {
    _periodicCheckTimer = Timer.periodic(_checkInterval, (_) async {
      await _performPeriodicCheck();
    });
  }

  /// Maneja cambios en la conectividad de red
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    try {
      LoggingService.info('🔄 Cambio de conectividad detectado: $results');
      
      final networkType = _mapConnectivityToNetworkType(results);
      final hasInternet = await _testInternetConnection();
      
      final newInfo = ConnectivityInfo(
        status: hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
        networkType: networkType,
        timestamp: DateTime.now(),
        hasInternet: hasInternet,
      );

      await _updateConnectivityInfo(newInfo);
    } catch (e) {
      LoggingService.error('❌ Error manejando cambio de conectividad: $e');
    }
  }

  /// Realiza verificación periódica de conectividad
  Future<void> _performPeriodicCheck() async {
    try {
      final hasInternet = await _testInternetConnection();
      
      // Solo actualizar si el estado cambió
      if (hasInternet != _currentInfo.hasInternet) {
        final newInfo = ConnectivityInfo(
          status: hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
          networkType: _currentInfo.networkType,
          timestamp: DateTime.now(),
          hasInternet: hasInternet,
        );

        await _updateConnectivityInfo(newInfo);
        LoggingService.info('🔄 Estado actualizado por verificación periódica: ${newInfo.status}');
      }
    } catch (e) {
      LoggingService.error('❌ Error en verificación periódica: $e');
    }
  }

  /// Actualiza la información de conectividad y notifica cambios
  Future<void> _updateConnectivityInfo(ConnectivityInfo newInfo) async {
    final previousStatus = _currentInfo.status;
    final previousHasInternet = _currentInfo.hasInternet;
    
    _currentInfo = newInfo;
    _connectivityController.add(newInfo);

    // Ejecutar callbacks según el cambio
    if (previousStatus != newInfo.status) {
      if (newInfo.status == ConnectivityStatus.online) {
        _executeCallbacks(_onOnlineCallbacks);
        LoggingService.info('🌐 Conectividad restaurada');
      } else if (newInfo.status == ConnectivityStatus.offline) {
        _executeCallbacks(_onOfflineCallbacks);
        LoggingService.info('📴 Conectividad perdida');
      }
    }

    // Callback especial para reconexión
    if (previousHasInternet == false && newInfo.hasInternet == true) {
      _executeCallbacks(_onReconnectCallbacks);
      LoggingService.info('🔄 Reconexión detectada');
    }
  }

  /// Ejecuta una lista de callbacks
  void _executeCallbacks(List<VoidCallback> callbacks) {
    for (final callback in callbacks) {
      try {
        callback();
      } catch (e) {
        LoggingService.error('❌ Error ejecutando callback de conectividad: $e');
      }
    }
  }

  /// Verifica si realmente tiene conexión a internet
  Future<bool> _testInternetConnection() async {
    try {
      // Usar Supabase como test principal
      await Supabase.instance.client
          .from('productos')
          .select('id')
          .limit(1)
          .timeout(_timeoutDuration);
      
      return true;
    } catch (e) {
      LoggingService.warning('⚠️ Test de internet falló: $e');
      
      // Fallback: intentar con Google
      try {
        final response = await Supabase.instance.client
            .from('productos')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 5));
        
        return response.isNotEmpty;
      } catch (e2) {
        LoggingService.warning('⚠️ Test de fallback también falló: $e2');
        return false;
      }
    }
  }

  /// Mapea resultados de conectividad a tipo de red
  NetworkType _mapConnectivityToNetworkType(List<ConnectivityResult> results) {
    if (results.isEmpty) return NetworkType.none;
    
    final result = results.first;
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.bluetooth:
        return NetworkType.bluetooth;
      case ConnectivityResult.vpn:
        return NetworkType.vpn;
      case ConnectivityResult.other:
        return NetworkType.other;
      case ConnectivityResult.none:
        return NetworkType.none;
    }
  }

  /// Verifica conectividad de forma manual
  Future<ConnectivityInfo> checkConnectivity() async {
    try {
      LoggingService.info('🔍 Verificación manual de conectividad...');
      
      final connectivityResults = await _connectivity.checkConnectivity();
      final networkType = _mapConnectivityToNetworkType(connectivityResults);
      final hasInternet = await _testInternetConnection();
      
      final info = ConnectivityInfo(
        status: hasInternet ? ConnectivityStatus.online : ConnectivityStatus.offline,
        networkType: networkType,
        timestamp: DateTime.now(),
        hasInternet: hasInternet,
      );

      await _updateConnectivityInfo(info);
      return info;
    } catch (e) {
      LoggingService.error('❌ Error en verificación manual: $e');
      final errorInfo = ConnectivityInfo(
        status: ConnectivityStatus.unknown,
        networkType: NetworkType.none,
        timestamp: DateTime.now(),
        hasInternet: false,
        errorMessage: e.toString(),
      );
      await _updateConnectivityInfo(errorInfo);
      return errorInfo;
    }
  }

  /// Registra callback para cuando se conecta
  void onOnline(VoidCallback callback) {
    _onOnlineCallbacks.add(callback);
  }

  /// Registra callback para cuando se desconecta
  void onOffline(VoidCallback callback) {
    _onOfflineCallbacks.add(callback);
  }

  /// Registra callback para cuando se reconecta
  void onReconnect(VoidCallback callback) {
    _onReconnectCallbacks.add(callback);
  }

  /// Elimina todos los callbacks
  void clearCallbacks() {
    _onOnlineCallbacks.clear();
    _onOfflineCallbacks.clear();
    _onReconnectCallbacks.clear();
  }

  /// Obtiene estadísticas de conectividad
  Map<String, dynamic> getConnectivityStats() {
    return {
      'currentStatus': _currentInfo.status.toString(),
      'networkType': _currentInfo.networkType.toString(),
      'hasInternet': _currentInfo.hasInternet,
      'lastCheck': _currentInfo.timestamp.toIso8601String(),
      'isInitialized': _isInitialized,
      'activeCallbacks': {
        'onOnline': _onOnlineCallbacks.length,
        'onOffline': _onOfflineCallbacks.length,
        'onReconnect': _onReconnectCallbacks.length,
      },
    };
  }

  /// Libera recursos del servicio
  Future<void> dispose() async {
    try {
      LoggingService.info('🔄 Liberando recursos de ConnectivityService...');
      
      await _connectivitySubscription?.cancel();
      _periodicCheckTimer?.cancel();
      await _connectivityController.close();
      
      clearCallbacks();
      _isInitialized = false;
      
      LoggingService.info('✅ ConnectivityService liberado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error liberando ConnectivityService: $e');
    }
  }
}
