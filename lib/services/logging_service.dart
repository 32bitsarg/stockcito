import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  static const String _appName = 'Stockcito';

  /// Log de debug (solo en modo debug)
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Log de información
  static void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  /// Log de advertencia
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log de error
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Método interno para logging
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final levelString = level.name.toUpperCase();
    final tagString = tag != null ? '[$tag]' : '';
    final logMessage = '[$timestamp] $levelString $tagString $message';

    // Log en consola para debugging
    if (kDebugMode) {
      switch (level) {
        case LogLevel.debug:
          developer.log(logMessage, name: _appName);
          break;
        case LogLevel.info:
          developer.log(logMessage, name: _appName);
          break;
        case LogLevel.warning:
          developer.log(logMessage, name: _appName, level: 900);
          break;
        case LogLevel.error:
          developer.log(
            logMessage,
            name: _appName,
            level: 1000,
            error: error,
            stackTrace: stackTrace,
          );
          break;
      }
    }

    // En producción, podrías enviar logs a un servicio externo
    if (kReleaseMode && level.index >= LogLevel.warning.index) {
      _sendToExternalService(level, message, tag: tag, error: error, stackTrace: stackTrace);
    }
  }

  /// Envía logs críticos a un servicio externo (implementar según necesidades)
  static void _sendToExternalService(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Aquí podrías implementar el envío a servicios como:
    // - Firebase Crashlytics
    // - Sentry
    // - Custom API endpoint
    // Por ahora solo lo dejamos como placeholder
  }

  /// Log específico para operaciones de base de datos
  static void database(String operation, {String? table, Object? error}) {
    final message = 'DB Operation: $operation${table != null ? ' on $table' : ''}';
    if (error != null) {
      LoggingService.error(message, tag: 'DATABASE', error: error);
    } else {
      LoggingService.info(message, tag: 'DATABASE');
    }
  }

  /// Log específico para operaciones de UI
  static void ui(String action, {String? screen, Object? error}) {
    final message = 'UI Action: $action${screen != null ? ' on $screen' : ''}';
    if (error != null) {
      LoggingService.error(message, tag: 'UI', error: error);
    } else {
      LoggingService.debug(message, tag: 'UI');
    }
  }

  /// Log específico para operaciones de red
  static void network(String operation, {String? endpoint, Object? error}) {
    final message = 'Network: $operation${endpoint != null ? ' to $endpoint' : ''}';
    if (error != null) {
      LoggingService.error(message, tag: 'NETWORK', error: error);
    } else {
      LoggingService.info(message, tag: 'NETWORK');
    }
  }

  /// Log específico para operaciones de negocio
  static void business(String operation, {String? entity, Object? error}) {
    final message = 'Business: $operation${entity != null ? ' for $entity' : ''}';
    if (error != null) {
      LoggingService.error(message, tag: 'BUSINESS', error: error);
    } else {
      LoggingService.info(message, tag: 'BUSINESS');
    }
  }
}
