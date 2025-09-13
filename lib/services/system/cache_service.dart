import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_service.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cachePrefix = 'ricitos_cache_';
  static const Duration _defaultExpiry = Duration(hours: 1);

  /// Obtiene un valor del caché
  static Future<T?> get<T>(String key, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) {
        LoggingService.debug('Cache miss: $key');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(cachedData);
      final expiry = DateTime.parse(data['expiry']);
      
      if (DateTime.now().isAfter(expiry)) {
        LoggingService.debug('Cache expired: $key');
        await _remove(key);
        return null;
      }

      LoggingService.debug('Cache hit: $key');
      return fromJson(data['value']);
    } catch (e) {
      LoggingService.error('Error reading cache: $key', error: e);
      return null;
    }
  }

  /// Guarda un valor en el caché
  static Future<void> set<T>(
    String key,
    T value,
    T Function(T) toJson, {
    Duration? expiry,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      final expiryTime = DateTime.now().add(expiry ?? _defaultExpiry);
      
      final cacheData = {
        'value': toJson(value),
        'expiry': expiryTime.toIso8601String(),
        'created': DateTime.now().toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      LoggingService.debug('Cache set: $key (expires: $expiryTime)');
    } catch (e) {
      LoggingService.error('Error setting cache: $key', error: e);
    }
  }

  /// Elimina un valor del caché
  static Future<void> _remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      await prefs.remove(cacheKey);
      LoggingService.debug('Cache removed: $key');
    } catch (e) {
      LoggingService.error('Error removing cache: $key', error: e);
    }
  }

  /// Elimina un valor del caché (método público)
  static Future<void> remove(String key) async {
    await _remove(key);
  }

  /// Limpia todo el caché
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      LoggingService.info('Cache cleared: ${keys.length} items removed');
    } catch (e) {
      LoggingService.error('Error clearing cache', error: e);
    }
  }

  /// Obtiene el tamaño del caché
  static Future<int> getSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      return keys.length;
    } catch (e) {
      LoggingService.error('Error getting cache size', error: e);
      return 0;
    }
  }

  /// Limpia elementos expirados del caché
  static Future<void> cleanExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      final now = DateTime.now();
      int removedCount = 0;

      for (final key in keys) {
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(cachedData);
            final expiry = DateTime.parse(data['expiry']);
            
            if (now.isAfter(expiry)) {
              await prefs.remove(key);
              removedCount++;
            }
          } catch (e) {
            // Si hay error al parsear, eliminar el elemento corrupto
            await prefs.remove(key);
            removedCount++;
          }
        }
      }

      if (removedCount > 0) {
        LoggingService.info('Cleaned $removedCount expired cache items');
      }
    } catch (e) {
      LoggingService.error('Error cleaning expired cache', error: e);
    }
  }

  /// Verifica si una clave existe en el caché
  static Future<bool> exists(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix$key';
      return prefs.containsKey(cacheKey);
    } catch (e) {
      LoggingService.error('Error checking cache existence: $key', error: e);
      return false;
    }
  }

  /// Obtiene información sobre el caché
  static Future<Map<String, dynamic>> getInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cachePrefix));
      final now = DateTime.now();
      int totalItems = 0;
      int expiredItems = 0;
      int validItems = 0;

      for (final key in keys) {
        totalItems++;
        final cachedData = prefs.getString(key);
        if (cachedData != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(cachedData);
            final expiry = DateTime.parse(data['expiry']);
            
            if (now.isAfter(expiry)) {
              expiredItems++;
            } else {
              validItems++;
            }
          } catch (e) {
            expiredItems++; // Considerar corruptos como expirados
          }
        }
      }

      return {
        'totalItems': totalItems,
        'validItems': validItems,
        'expiredItems': expiredItems,
        'lastCleanup': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('Error getting cache info', error: e);
      return {
        'totalItems': 0,
        'validItems': 0,
        'expiredItems': 0,
        'lastCleanup': DateTime.now().toIso8601String(),
      };
    }
  }
}
