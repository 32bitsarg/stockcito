import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'logging_service.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<Duration>> _performanceHistory = {};
  static final int _maxHistorySize = 100;

  /// Inicia un timer de rendimiento
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
    LoggingService.debug('Timer started: $operation');
  }

  /// Detiene un timer y registra el tiempo
  static Duration? stopTimer(String operation) {
    final timer = _timers.remove(operation);
    if (timer == null) {
      LoggingService.warning('Timer not found: $operation');
      return null;
    }

    timer.stop();
    final duration = timer.elapsed;
    
    // Registrar en el historial
    _performanceHistory.putIfAbsent(operation, () => []);
    final history = _performanceHistory[operation]!;
    history.add(duration);
    
    // Mantener solo los últimos N registros
    if (history.length > _maxHistorySize) {
      history.removeAt(0);
    }

    LoggingService.debug('Timer stopped: $operation (${duration.inMilliseconds}ms)');
    return duration;
  }

  /// Mide el tiempo de ejecución de una función
  static Future<T> measureAsync<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    startTimer(operation);
    try {
      final result = await function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }

  /// Mide el tiempo de ejecución de una función síncrona
  static T measureSync<T>(
    String operation,
    T Function() function,
  ) {
    startTimer(operation);
    try {
      final result = function();
      stopTimer(operation);
      return result;
    } catch (e) {
      stopTimer(operation);
      rethrow;
    }
  }

  /// Obtiene estadísticas de rendimiento para una operación
  static Map<String, dynamic> getPerformanceStats(String operation) {
    final history = _performanceHistory[operation] ?? [];
    if (history.isEmpty) {
      return {
        'operation': operation,
        'count': 0,
        'averageMs': 0,
        'minMs': 0,
        'maxMs': 0,
        'totalMs': 0,
      };
    }

    final totalMs = history.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final averageMs = totalMs / history.length;
    final minMs = history.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final maxMs = history.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);

    return {
      'operation': operation,
      'count': history.length,
      'averageMs': averageMs.round(),
      'minMs': minMs,
      'maxMs': maxMs,
      'totalMs': totalMs,
    };
  }

  /// Obtiene todas las estadísticas de rendimiento
  static Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final operation in _performanceHistory.keys) {
      stats[operation] = getPerformanceStats(operation);
    }
    return stats;
  }

  /// Limpia el historial de rendimiento
  static void clearHistory() {
    _performanceHistory.clear();
    _timers.clear();
    LoggingService.info('Performance history cleared');
  }

  /// Obtiene información del sistema
  static Map<String, dynamic> getSystemInfo() {
    return {
      'platform': Platform.operatingSystem,
      'isDebug': kDebugMode,
      'isRelease': kReleaseMode,
      'isProfile': kProfileMode,
      'numberOfProcessors': Platform.numberOfProcessors,
      'version': Platform.version,
    };
  }

  /// Monitorea el uso de memoria (aproximado)
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      // En modo debug, podemos usar ProcessInfo
      try {
        final info = ProcessInfo.currentRss;
        LoggingService.debug('Memory usage at $context: ${info ~/ 1024} KB');
      } catch (e) {
        LoggingService.debug('Could not get memory usage: $e');
      }
    }
  }

  /// Optimiza las operaciones de base de datos
  static Future<List<T>> optimizeDatabaseQuery<T>(
    String operation,
    Future<List<T>> Function() query,
    {Duration? cacheExpiry}
  ) async {
    return measureAsync(operation, query);
  }

  /// Debounce para evitar llamadas excesivas
  static Timer? _debounceTimer;
  static void debounce(
    String operation,
    Duration delay,
    VoidCallback callback,
  ) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      LoggingService.debug('Debounced operation: $operation');
      callback();
    });
  }

  /// Throttle para limitar la frecuencia de ejecución
  static DateTime? _lastThrottleTime;
  static bool throttle(
    String operation,
    Duration interval,
    VoidCallback callback,
  ) {
    final now = DateTime.now();
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      LoggingService.debug('Throttled operation: $operation');
      callback();
      return true;
    }
    return false;
  }

  /// Verifica si una operación es lenta
  static bool isSlowOperation(String operation, {int thresholdMs = 1000}) {
    final stats = getPerformanceStats(operation);
    return stats['averageMs'] > thresholdMs;
  }

  /// Obtiene operaciones lentas
  static List<String> getSlowOperations({int thresholdMs = 1000}) {
    final slowOps = <String>[];
    for (final operation in _performanceHistory.keys) {
      if (isSlowOperation(operation, thresholdMs: thresholdMs)) {
        slowOps.add(operation);
      }
    }
    return slowOps;
  }

  /// Genera un reporte de rendimiento
  static Map<String, dynamic> generatePerformanceReport() {
    final stats = getAllPerformanceStats();
    final systemInfo = getSystemInfo();
    final slowOps = getSlowOperations();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'systemInfo': systemInfo,
      'operations': stats,
      'slowOperations': slowOps,
      'totalOperations': stats.length,
      'averagePerformance': _calculateAveragePerformance(stats),
    };
  }

  /// Calcula el rendimiento promedio
  static double _calculateAveragePerformance(Map<String, Map<String, dynamic>> stats) {
    if (stats.isEmpty) return 0.0;
    
    final totalAverage = stats.values
        .map((s) => s['averageMs'] as int)
        .reduce((a, b) => a + b);
    
    return totalAverage / stats.length;
  }

  /// Limpia recursos
  static void dispose() {
    _debounceTimer?.cancel();
    _timers.clear();
    _performanceHistory.clear();
  }
}
