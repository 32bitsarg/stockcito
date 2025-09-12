import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../supabase_auth_service.dart';
import '../logging_service.dart';

/// Servicio de sincronización robusta con manejo de errores y reintentos
class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  
  // Configuración de reintentos
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  
  // Cola de sincronización persistente
  final List<SyncOperation> _syncQueue = [];
  bool _isProcessingQueue = false;
  
  // Estado de sincronización
  bool _isOnline = true;
  DateTime? _lastSyncTime;

  /// Inicializa el servicio de sincronización
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando SyncService...');
      
      // Cargar cola persistente
      await _loadPersistentQueue();
      
      // Verificar conectividad
      await _checkConnectivity();
      
      // Procesar cola si hay conexión
      if (_isOnline) {
        await _processSyncQueue();
      }
      
      LoggingService.info('SyncService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando SyncService: $e');
    }
  }

  /// Verifica la conectividad
  Future<void> _checkConnectivity() async {
    try {
      // Intentar una operación simple para verificar conectividad
      await Supabase.instance.client
          .from('productos')
          .select('id')
          .limit(1);
      
      _isOnline = true;
      LoggingService.info('Conexión a Supabase verificada');
    } catch (e) {
      _isOnline = false;
      LoggingService.warning('Sin conexión a Supabase: $e');
    }
  }

  /// Agrega una operación a la cola de sincronización
  Future<void> addSyncOperation(SyncOperation operation) async {
    _syncQueue.add(operation);
    await _savePersistentQueue();
    
    // Intentar procesar inmediatamente si hay conexión
    if (_isOnline) {
      await _processSyncQueue();
    }
  }

  /// Procesa la cola de sincronización
  Future<void> _processSyncQueue() async {
    if (_isProcessingQueue || _syncQueue.isEmpty || !_isOnline) return;
    
    _isProcessingQueue = true;
    
    try {
      LoggingService.info('Procesando cola de sincronización: ${_syncQueue.length} operaciones');
      
      while (_syncQueue.isNotEmpty) {
        final operation = _syncQueue.removeAt(0);
        final success = await _executeSyncOperationWithRetry(operation);
        
        if (!success) {
          // Reagregar al inicio de la cola para reintento posterior
          _syncQueue.insert(0, operation);
          break;
        }
      }
      
      await _savePersistentQueue();
      _lastSyncTime = DateTime.now();
      
      LoggingService.info('Cola de sincronización procesada');
    } catch (e) {
      LoggingService.error('Error procesando cola de sincronización: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Ejecuta una operación de sincronización con reintentos
  Future<bool> _executeSyncOperationWithRetry(SyncOperation operation) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _executeSyncOperation(operation);
        LoggingService.info('Operación sincronizada exitosamente: ${operation.type} en ${operation.table}');
        return true;
      } catch (e) {
        LoggingService.warning('Intento $attempt fallido para operación ${operation.type} en ${operation.table}: $e');
        
        if (attempt < _maxRetries) {
          // Esperar antes del siguiente intento
          await Future.delayed(_retryDelay * attempt);
        } else {
          LoggingService.error('Operación fallida después de $_maxRetries intentos: ${operation.type} en ${operation.table}');
          return false;
        }
      }
    }
    return false;
  }

  /// Ejecuta una operación de sincronización específica
  Future<void> _executeSyncOperation(SyncOperation operation) async {
    final userId = _authService.currentUserId;
    if (userId == null) throw Exception('Usuario no autenticado');

    // Agregar user_id a los datos
    final data = Map<String, dynamic>.from(operation.data);
    data['user_id'] = userId;

    switch (operation.type) {
      case SyncType.create:
        await Supabase.instance.client
            .from(operation.table)
            .insert(data);
        break;
      case SyncType.update:
        await Supabase.instance.client
            .from(operation.table)
            .update(data)
            .eq('id', data['id'])
            .eq('user_id', userId);
        break;
      case SyncType.delete:
        await Supabase.instance.client
            .from(operation.table)
            .delete()
            .eq('id', data['id'])
            .eq('user_id', userId);
        break;
    }
  }

  /// Guarda la cola de sincronización persistentemente
  Future<void> _savePersistentQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _syncQueue.map((op) => op.toJson()).toList();
      await prefs.setString('sync_queue', jsonEncode(queueJson));
    } catch (e) {
      LoggingService.error('Error guardando cola de sincronización: $e');
    }
  }

  /// Carga la cola de sincronización persistente
  Future<void> _loadPersistentQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString('sync_queue');
      if (queueString != null) {
        final queueJson = jsonDecode(queueString) as List;
        _syncQueue.clear();
        _syncQueue.addAll(
          queueJson.map((json) => SyncOperation.fromJson(json))
        );
        LoggingService.info('Cola de sincronización cargada: ${_syncQueue.length} operaciones');
      }
    } catch (e) {
      LoggingService.error('Error cargando cola de sincronización: $e');
    }
  }

  /// Fuerza la sincronización de todos los datos pendientes
  Future<void> forceSync() async {
    await _checkConnectivity();
    if (_isOnline) {
      await _processSyncQueue();
    }
  }

  /// Limpia la cola de sincronización
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    await _savePersistentQueue();
    LoggingService.info('Cola de sincronización limpiada');
  }

  // ==================== GETTERS ====================

  /// Verifica si está sincronizando
  bool get isSyncing => _isProcessingQueue;
  
  /// Verifica si está en línea
  bool get isOnline => _isOnline;
  
  /// Obtiene el número de operaciones pendientes
  int get pendingOperations => _syncQueue.length;
  
  /// Obtiene la última vez que se sincronizó
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Obtiene el estado de sincronización
  SyncStatus get syncStatus {
    if (!_isOnline) return SyncStatus.offline;
    if (_isProcessingQueue) return SyncStatus.syncing;
    if (_syncQueue.isNotEmpty) return SyncStatus.pending;
    return SyncStatus.synced;
  }
}

/// Estados de sincronización
enum SyncStatus {
  synced,
  syncing,
  pending,
  offline,
}

/// Operación de sincronización mejorada
class SyncOperation {
  final String id;
  final SyncType type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncOperation({
    required this.type,
    required this.table,
    required this.data,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = DateTime.now(),
       retryCount = 0;

  SyncOperation._({
    required this.id,
    required this.type,
    required this.table,
    required this.data,
    required this.timestamp,
    required this.retryCount,
  });

  /// Convierte a JSON para persistencia
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'table': table,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  /// Crea desde JSON
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation._(
      id: json['id'],
      type: SyncType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SyncType.create,
      ),
      table: json['table'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  /// Crea una copia con contador de reintentos incrementado
  SyncOperation incrementRetry() {
    return SyncOperation._(
      id: id,
      type: type,
      table: table,
      data: data,
      timestamp: timestamp,
      retryCount: retryCount + 1,
    );
  }
}

/// Tipos de operaciones de sincronización
enum SyncType { create, update, delete }
