import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:stockcito/services/auth/supabase_auth_service.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/connectivity_enums.dart';
import 'package:http/http.dart' as http; // Chequeo simple de internet

/// Servicio de sincronización mejorado con integración de conectividad inteligente
class EnhancedSyncService {
  static final EnhancedSyncService _instance = EnhancedSyncService._internal();
  factory EnhancedSyncService() => _instance;
  EnhancedSyncService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  
  // Configuración de sincronización
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const Duration _batchSize = Duration(milliseconds: 500);
  static const int _maxBatchSize = 10;
  
  // Cola de sincronización con prioridades
  final List<SyncOperation> _syncQueue = [];
  final Map<String, SyncOperation> _pendingOperations = {};
  bool _isProcessingQueue = false;
  
  // Estado de sincronización
  DateTime? _lastSyncTime;
  Timer? _periodicSyncTimer;
  bool _lastOnline = true;
  
  // Estadísticas
  int _totalSynced = 0;
  int _totalFailed = 0;
  DateTime? _lastSuccessfulSync;

  /// Inicializa el servicio de sincronización mejorado
  Future<void> initialize() async {
    try {
      LoggingService.info('🔄 Inicializando EnhancedSyncService...');
      
      // Cargar cola persistente
      await _loadPersistentQueue();
      
      // Configurar sincronización periódica
      _setupPeriodicSync();
      
      // Procesar cola inicial si hay conexión
      if (await _hasInternet()) {
        await _processSyncQueue();
      }
      
      LoggingService.info('✅ EnhancedSyncService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando EnhancedSyncService: $e');
      rethrow;
    }
  }


  /// Configura la sincronización periódica
  void _setupPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (_syncQueue.isNotEmpty && await _hasInternet()) {
        LoggingService.info('⏰ Sincronización periódica iniciada');
        await _processSyncQueue();
      }
    });
  }

  /// Agrega una operación a la cola de sincronización con prioridad
  Future<void> addSyncOperation(SyncOperation operation) async {
    try {
      // Verificar si ya existe una operación similar pendiente
      final existingKey = _getOperationKey(operation);
      if (_pendingOperations.containsKey(existingKey)) {
        LoggingService.info('🔄 Actualizando operación existente: $existingKey');
        _pendingOperations[existingKey] = operation;
      } else {
        _pendingOperations[existingKey] = operation;
      }

      // Agregar a la cola si no está ya procesándose
      if (!_syncQueue.any((op) => _getOperationKey(op) == existingKey)) {
        _syncQueue.add(operation);
        await _savePersistentQueue();
        
        LoggingService.info('📝 Operación agregada a cola: ${operation.type} en ${operation.table}');
      }

      // Intentar procesar inmediatamente si hay conexión
      if (await _hasInternet()) {
        await _processSyncQueue();
      }
    } catch (e) {
      LoggingService.error('❌ Error agregando operación de sincronización: $e');
    }
  }

  /// Procesa la cola de sincronización con batching inteligente
  Future<void> _processSyncQueue() async {
    if (_isProcessingQueue || _syncQueue.isEmpty || !(await _hasInternet())) {
      return;
    }

    _isProcessingQueue = true;

    try {
      LoggingService.info('🔄 Procesando cola de sincronización: ${_syncQueue.length} operaciones');

      // Procesar en lotes para optimizar rendimiento
      final batches = _createBatches(_syncQueue);
      
      for (final batch in batches) {
        if (!(await _hasInternet())) {
          LoggingService.warning('⚠️ Conectividad perdida durante procesamiento');
          break;
        }

        await _processBatch(batch);
        
        // Pequeña pausa entre lotes para no sobrecargar el servidor
        await Future.delayed(_batchSize);
      }

      await _savePersistentQueue();
      _lastSyncTime = DateTime.now();
      _lastSuccessfulSync = DateTime.now();

      LoggingService.info('✅ Cola de sincronización procesada exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error procesando cola de sincronización: $e');
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Crea lotes de operaciones para procesamiento optimizado
  List<List<SyncOperation>> _createBatches(List<SyncOperation> operations) {
    final batches = <List<SyncOperation>>[];
    
    // Agrupar por tabla para optimizar operaciones
    final groupedOperations = <String, List<SyncOperation>>{};
    for (final operation in operations) {
      groupedOperations.putIfAbsent(operation.table, () => []).add(operation);
    }

    // Crear lotes por tabla
    for (final tableOperations in groupedOperations.values) {
      for (int i = 0; i < tableOperations.length; i += _maxBatchSize) {
        final batch = tableOperations.skip(i).take(_maxBatchSize).toList();
        batches.add(batch);
      }
    }

    return batches;
  }

  /// Procesa un lote de operaciones
  Future<void> _processBatch(List<SyncOperation> batch) async {
    try {
      LoggingService.info('📦 Procesando lote de ${batch.length} operaciones');

      for (final operation in batch) {
        final success = await _executeSyncOperationWithRetry(operation);
        
        if (success) {
          _totalSynced++;
          _syncQueue.remove(operation);
          _pendingOperations.remove(_getOperationKey(operation));
          LoggingService.info('✅ Operación sincronizada: ${operation.type} en ${operation.table}');
        } else {
          _totalFailed++;
          LoggingService.warning('⚠️ Operación fallida: ${operation.type} en ${operation.table}');
          
          // Reagregar al final de la cola para reintento posterior
          final retryOperation = operation.incrementRetry();
          if (retryOperation.retryCount < _maxRetries) {
            _syncQueue.add(retryOperation);
          } else {
            LoggingService.error('❌ Operación descartada después de $_maxRetries intentos');
            _pendingOperations.remove(_getOperationKey(operation));
          }
        }
      }
    } catch (e) {
      LoggingService.error('❌ Error procesando lote: $e');
    }
  }

  /// Ejecuta una operación de sincronización con reintentos
  Future<bool> _executeSyncOperationWithRetry(SyncOperation operation) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        await _executeSyncOperation(operation);
        return true;
      } catch (e) {
        LoggingService.warning('⚠️ Intento $attempt fallido para ${operation.type} en ${operation.table}: $e');
        
        if (attempt < _maxRetries) {
          // Esperar antes del siguiente intento con backoff exponencial
          await Future.delayed(_retryDelay * attempt);
        } else {
          LoggingService.error('❌ Operación fallida después de $_maxRetries intentos');
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

    // Agregar user_id y timestamps a los datos
    final data = Map<String, dynamic>.from(operation.data);
    data['user_id'] = userId;
    data['updated_at'] = DateTime.now().toIso8601String();

    switch (operation.type) {
      case SyncType.create:
        data['created_at'] = DateTime.now().toIso8601String();
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

  /// Genera una clave única para una operación
  String _getOperationKey(SyncOperation operation) {
    return '${operation.type}_${operation.table}_${operation.data['id'] ?? 'new'}';
  }

  /// Guarda la cola de sincronización persistentemente
  Future<void> _savePersistentQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = _syncQueue.map((op) => op.toJson()).toList();
      await prefs.setString('enhanced_sync_queue', jsonEncode(queueJson));
      
      // Guardar estadísticas
      await prefs.setString('sync_stats', jsonEncode({
        'totalSynced': _totalSynced,
        'totalFailed': _totalFailed,
        'lastSuccessfulSync': _lastSuccessfulSync?.toIso8601String(),
      }));
    } catch (e) {
      LoggingService.error('❌ Error guardando cola de sincronización: $e');
    }
  }

  /// Carga la cola de sincronización persistente
  Future<void> _loadPersistentQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cargar cola
      final queueString = prefs.getString('enhanced_sync_queue');
      if (queueString != null) {
        final queueJson = jsonDecode(queueString) as List;
        _syncQueue.clear();
        _syncQueue.addAll(
          queueJson.map((json) => SyncOperation.fromJson(json))
        );
        LoggingService.info('📥 Cola de sincronización cargada: ${_syncQueue.length} operaciones');
      }

      // Cargar estadísticas
      final statsString = prefs.getString('sync_stats');
      if (statsString != null) {
        final stats = jsonDecode(statsString) as Map<String, dynamic>;
        _totalSynced = stats['totalSynced'] ?? 0;
        _totalFailed = stats['totalFailed'] ?? 0;
        _lastSuccessfulSync = stats['lastSuccessfulSync'] != null 
            ? DateTime.parse(stats['lastSuccessfulSync']) 
            : null;
      }
    } catch (e) {
      LoggingService.error('❌ Error cargando cola de sincronización: $e');
    }
  }

  /// Fuerza la sincronización de todos los datos pendientes
  Future<void> forceSync() async {
    if (await _hasInternet()) {
      LoggingService.info('🔄 Sincronización forzada iniciada');
      await _processSyncQueue();
    } else {
      LoggingService.warning('⚠️ No se puede sincronizar - Sin conexión a internet');
    }
  }

  /// Limpia la cola de sincronización
  Future<void> clearSyncQueue() async {
    _syncQueue.clear();
    _pendingOperations.clear();
    await _savePersistentQueue();
    LoggingService.info('🗑️ Cola de sincronización limpiada');
  }

  /// Obtiene estadísticas de sincronización
  Map<String, dynamic> getSyncStats() {
    return {
      'pendingOperations': _syncQueue.length,
      'totalSynced': _totalSynced,
      'totalFailed': _totalFailed,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'lastSuccessfulSync': _lastSuccessfulSync?.toIso8601String(),
      'isOnline': _lastOnline,
      'isProcessing': _isProcessingQueue,
      'connectivityInfo': {'online': _lastOnline},
    };
  }

  // ==================== GETTERS ====================

  /// Verifica si está sincronizando
  bool get isSyncing => _isProcessingQueue;
  
  /// Verifica si está en línea
  bool get isOnline => _lastOnline;
  
  /// Obtiene el número de operaciones pendientes
  int get pendingOperations => _syncQueue.length;
  
  /// Obtiene la última vez que se sincronizó
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Obtiene el estado de sincronización
  SyncStatus get syncStatus {
    if (!isOnline) return SyncStatus.offline;
    if (_isProcessingQueue) return SyncStatus.syncing;
    if (_syncQueue.isNotEmpty) return SyncStatus.pending;
    return SyncStatus.synced;
  }

  /// Libera recursos del servicio
  Future<void> dispose() async {
    try {
      LoggingService.info('🔄 Liberando recursos de EnhancedSyncService...');
      
      _periodicSyncTimer?.cancel();
      // No subscriptions activas
      
      await _savePersistentQueue();
      
      LoggingService.info('✅ EnhancedSyncService liberado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error liberando EnhancedSyncService: $e');
    }
  }
}

// Los enums SyncStatus ahora están en connectivity_enums.dart

/// Operación de sincronización mejorada con prioridades
class SyncOperation {
  final String id;
  final SyncType type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final SyncPriority priority;

  SyncOperation({
    required this.type,
    required this.table,
    required this.data,
    String? id,
    this.priority = SyncPriority.normal,
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
    required this.priority,
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
      'priority': priority.toString(),
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
      priority: SyncPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => SyncPriority.normal,
      ),
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
      priority: priority,
    );
  }
}

/// Tipos de operaciones de sincronización
// Los enums SyncType y SyncPriority ahora están en connectivity_enums.dart

// ==================== UTILIDADES INTERNAS ====================

/// Chequeo simple de internet sin depender del ConnectivityService
Future<bool> _hasInternet() async {
  try {
    final response = await http
        .head(Uri.parse('https://www.google.com'))
        .timeout(const Duration(seconds: 5));
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}
