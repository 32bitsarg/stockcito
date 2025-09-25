import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio de caché inteligente con múltiples capas y estrategias avanzadas
class IntelligentCacheService {
  static final IntelligentCacheService _instance = IntelligentCacheService._internal();
  factory IntelligentCacheService() => _instance;
  IntelligentCacheService._internal();

  // Configuración de caché por capas
  static const Duration _memoryCacheExpiry = Duration(minutes: 2);
  static const Duration _diskCacheExpiry = Duration(hours: 1);
  
  // Límites de caché
  static const int _maxMemoryItems = 100;
  static const int _maxDiskItems = 1000;

  // Caché en memoria (L1 - Más rápido)
  final Map<String, _CacheItem> _memoryCache = {};
  
  // Caché en disco (L2 - Persistente)
  Directory? _cacheDirectory;
  
  // Estadísticas de caché
  int _memoryHits = 0;
  int _diskHits = 0;
  int _networkHits = 0;
  int _cacheMisses = 0;

  /// Inicializa el servicio de caché
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando IntelligentCacheService...');
      
      // Crear directorio de caché
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${appDir.path}/cache');
      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }
      
      // Limpiar caché expirado al iniciar
      await _cleanupExpiredCache();
      
      LoggingService.info('IntelligentCacheService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando IntelligentCacheService: $e');
    }
  }

  /// Obtiene datos del caché con estrategia multi-capa
  Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final cacheKey = _generateCacheKey(key);
      
      // 1. Verificar caché en memoria (L1)
      if (_memoryCache.containsKey(cacheKey)) {
        final item = _memoryCache[cacheKey]!;
        if (!_isExpired(item.timestamp, _memoryCacheExpiry)) {
          _memoryHits++;
          LoggingService.debug('Cache hit (memory): $key');
          return fromJson(item.data);
        } else {
          _memoryCache.remove(cacheKey);
        }
      }
      
      // 2. Verificar caché en disco (L2)
      final diskData = await _getFromDisk(cacheKey);
      if (diskData != null) {
        _diskHits++;
        LoggingService.debug('Cache hit (disk): $key');
        
        // Promover a caché en memoria
        _memoryCache[cacheKey] = _CacheItem(
          data: diskData,
          timestamp: DateTime.now(),
          size: _calculateSize(diskData),
        );
        
        return fromJson(diskData);
      }
      
      // 3. Cache miss
      _cacheMisses++;
      LoggingService.debug('Cache miss: $key');
      return null;
      
    } catch (e) {
      LoggingService.error('Error obteniendo del caché: $e');
      return null;
    }
  }

  /// Guarda datos en el caché con estrategia multi-capa
  Future<void> set<T>(String key, T data, Map<String, dynamic> Function(T) toJson, {Duration? customExpiry}) async {
    try {
      final cacheKey = _generateCacheKey(key);
      final jsonData = toJson(data);
      final timestamp = DateTime.now();
      final size = _calculateSize(jsonData);
      
      // 1. Guardar en caché en memoria (L1)
      _memoryCache[cacheKey] = _CacheItem(
        data: jsonData,
        timestamp: timestamp,
        size: size,
      );
      
      // 2. Guardar en caché en disco (L2) - Solo si es importante
      if (_shouldPersistToDisk(key, size)) {
        await _saveToDisk(cacheKey, jsonData, timestamp);
      }
      
      // 3. Limpiar caché si es necesario
      await _cleanupIfNeeded();
      
      LoggingService.debug('Datos guardados en caché: $key');
      
    } catch (e) {
      LoggingService.error('Error guardando en caché: $e');
    }
  }

  /// Invalida caché específico
  Future<void> invalidate(String key) async {
    try {
      final cacheKey = _generateCacheKey(key);
      
      // Remover de memoria
      _memoryCache.remove(cacheKey);
      
      // Remover de disco
      await _removeFromDisk(cacheKey);
      
      LoggingService.debug('Caché invalidado: $key');
      
    } catch (e) {
      LoggingService.error('Error invalidando caché: $e');
    }
  }

  /// Invalida caché por patrón
  Future<void> invalidatePattern(String pattern) async {
    try {
      final keysToRemove = <String>[];
      
      // Buscar en memoria
      for (final key in _memoryCache.keys) {
        if (key.contains(pattern)) {
          keysToRemove.add(key);
        }
      }
      
      // Remover de memoria
      for (final key in keysToRemove) {
        _memoryCache.remove(key);
      }
      
      // Remover de disco
      await _removeFromDiskPattern(pattern);
      
      LoggingService.debug('Caché invalidado por patrón: $pattern');
      
    } catch (e) {
      LoggingService.error('Error invalidando caché por patrón: $e');
    }
  }

  /// Limpia todo el caché
  Future<void> clear() async {
    try {
      _memoryCache.clear();
      await _clearDiskCache();
      LoggingService.info('Caché limpiado completamente');
    } catch (e) {
      LoggingService.error('Error limpiando caché: $e');
    }
  }

  /// Alias para clear() - Limpia todo el caché
  Future<void> clearAllCache() async {
    await clear();
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getStats() {
    final totalHits = _memoryHits + _diskHits + _networkHits;
    final totalRequests = totalHits + _cacheMisses;
    
    return {
      'memory_hits': _memoryHits,
      'disk_hits': _diskHits,
      'network_hits': _networkHits,
      'cache_misses': _cacheMisses,
      'hit_rate': totalRequests > 0 ? (totalHits / totalRequests) : 0.0,
      'memory_items': _memoryCache.length,
      'memory_size': _memoryCache.values.fold(0, (sum, item) => sum + item.size),
    };
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Genera clave de caché única
  String _generateCacheKey(String key) {
    final bytes = utf8.encode(key);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Verifica si un timestamp está expirado
  bool _isExpired(DateTime timestamp, Duration expiry) {
    return DateTime.now().difference(timestamp) > expiry;
  }

  /// Calcula el tamaño aproximado de los datos
  int _calculateSize(Map<String, dynamic> data) {
    return utf8.encode(jsonEncode(data)).length;
  }

  /// Determina si los datos deben persistirse en disco
  bool _shouldPersistToDisk(String key, int size) {
    // Persistir datos importantes y de tamaño moderado
    return key.contains('productos') || 
           key.contains('ventas') || 
           key.contains('clientes') ||
           (size < 1024 * 1024); // Menos de 1MB
  }

  /// Obtiene datos del disco
  Future<Map<String, dynamic>?> _getFromDisk(String cacheKey) async {
    try {
      if (_cacheDirectory == null) return null;
      
      final file = File('${_cacheDirectory!.path}/$cacheKey.json');
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      // Verificar si está expirado
      final timestamp = DateTime.parse(data['timestamp']);
      if (_isExpired(timestamp, _diskCacheExpiry)) {
        await file.delete();
        return null;
      }
      
      return data['data'] as Map<String, dynamic>;
      
    } catch (e) {
      LoggingService.error('Error leyendo del disco: $e');
      return null;
    }
  }

  /// Guarda datos en disco
  Future<void> _saveToDisk(String cacheKey, Map<String, dynamic> data, DateTime timestamp) async {
    try {
      if (_cacheDirectory == null) return;
      
      final file = File('${_cacheDirectory!.path}/$cacheKey.json');
      final cacheData = {
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
      
      await file.writeAsString(jsonEncode(cacheData));
      
    } catch (e) {
      LoggingService.error('Error guardando en disco: $e');
    }
  }

  /// Remueve datos del disco
  Future<void> _removeFromDisk(String cacheKey) async {
    try {
      if (_cacheDirectory == null) return;
      
      final file = File('${_cacheDirectory!.path}/$cacheKey.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      LoggingService.error('Error removiendo del disco: $e');
    }
  }

  /// Remueve datos del disco por patrón
  Future<void> _removeFromDiskPattern(String pattern) async {
    try {
      if (_cacheDirectory == null) return;
      
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        if (file.path.contains(pattern)) {
          await file.delete();
        }
      }
    } catch (e) {
      LoggingService.error('Error removiendo patrón del disco: $e');
    }
  }

  /// Limpia caché expirado
  Future<void> _cleanupExpiredCache() async {
    try {
      // Limpiar memoria
      final expiredKeys = <String>[];
      for (final entry in _memoryCache.entries) {
        if (_isExpired(entry.value.timestamp, _memoryCacheExpiry)) {
          expiredKeys.add(entry.key);
        }
      }
      for (final key in expiredKeys) {
        _memoryCache.remove(key);
      }
      
      // Limpiar disco
      if (_cacheDirectory != null) {
        final files = await _cacheDirectory!.list().toList();
        for (final file in files) {
          try {
            if (file is File) {
              final content = await file.readAsString();
              final data = jsonDecode(content) as Map<String, dynamic>;
              final timestamp = DateTime.parse(data['timestamp']);
              if (_isExpired(timestamp, _diskCacheExpiry)) {
                await file.delete();
              }
            }
          } catch (e) {
            // Si no se puede leer, eliminar
            if (file is File) {
              await file.delete();
            }
          }
        }
      }
      
      LoggingService.debug('Caché expirado limpiado');
      
    } catch (e) {
      LoggingService.error('Error limpiando caché expirado: $e');
    }
  }

  /// Limpia caché si es necesario
  Future<void> _cleanupIfNeeded() async {
    // Limpiar memoria si excede límite
    if (_memoryCache.length > _maxMemoryItems) {
      final sortedEntries = _memoryCache.entries.toList()
        ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final toRemove = sortedEntries.take(_memoryCache.length - _maxMemoryItems);
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
    
    // Limpiar disco si excede límite
    await _cleanupDiskIfNeeded();
  }

  /// Limpia disco si excede límite
  Future<void> _cleanupDiskIfNeeded() async {
    try {
      if (_cacheDirectory == null) return;
      
      final files = await _cacheDirectory!.list().toList();
      if (files.length > _maxDiskItems) {
        // Ordenar por fecha de modificación y eliminar los más antiguos
        final sortedFiles = files.toList()
          ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        
        final toRemove = sortedFiles.take(files.length - _maxDiskItems);
        for (final file in toRemove) {
          await file.delete();
        }
      }
    } catch (e) {
      LoggingService.error('Error limpiando disco: $e');
    }
  }

  /// Limpia todo el caché en disco
  Future<void> _clearDiskCache() async {
    try {
      if (_cacheDirectory == null) return;
      
      final files = await _cacheDirectory!.list().toList();
      for (final file in files) {
        await file.delete();
      }
    } catch (e) {
      LoggingService.error('Error limpiando caché en disco: $e');
    }
  }
}

/// Item de caché interno
class _CacheItem {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int size;

  _CacheItem({
    required this.data,
    required this.timestamp,
    required this.size,
  });
}
