import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import '../../config/sentry_config.dart';

/// Servicio centralizado para manejo de Sentry
class SentryService {
  static final SentryService _instance = SentryService._internal();
  factory SentryService() => _instance;
  SentryService._internal();

  bool _isInitialized = false;

  /// Inicializa Sentry
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await SentryConfig.load();
      
      await SentryFlutter.init(
        (options) {
      // Configuración básica
      options.dsn = SentryConfig.sentryDsn;
          options.environment = SentryConfig.environment;
          options.release = SentryConfig.release;
          
          // Configuración de muestreo
          options.tracesSampleRate = SentryConfig.tracesSampleRate;
          options.profilesSampleRate = SentryConfig.profilesSampleRate;
          
          // Configuración de sesiones
          options.enableAutoSessionTracking = SentryConfig.enableAutoSessionTracking;
          
          // Configuración de crashes (removido en versión 7.x)
          // options.enableCrashHandling = SentryConfig.enableCrashHandling;
          
          // Configuración de debug
          if (SentryConfig.enableDebugLogging) {
            options.debug = true;
          }
          
          // Configuración específica para Flutter
          options.attachScreenshot = true;
          options.attachViewHierarchy = true;
          options.sendDefaultPii = true; // Incluir información del usuario
          
          // Configuración de contexto
          options.beforeSend = _beforeSend;
          options.beforeSendTransaction = _beforeSendTransaction;
        },
      );

      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Sentry inicializado correctamente');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando Sentry: $e');
      }
    }
  }

  /// Filtro para eventos antes de enviar
  SentryEvent? _beforeSend(SentryEvent event, {Hint? hint}) {
    // Filtrar eventos en modo debug si es necesario
    if (kDebugMode && event.level == SentryLevel.debug) {
      return null; // No enviar logs de debug en desarrollo
    }
    
    // Agregar contexto adicional
    event = event.copyWith(
      tags: {
        ...event.tags ?? {},
        'platform': 'flutter',
        'app_version': SentryConfig.release,
      },
    );
    
    return event;
  }

  /// Filtro para transacciones antes de enviar
  SentryTransaction? _beforeSendTransaction(SentryTransaction transaction, {Hint? hint}) {
    // En v7.x, aceptamos todas las transacciones
    return transaction;
  }

  /// Captura un error manualmente
  static Future<void> captureError(
    dynamic error, {
    dynamic stackTrace,
    String? hint,
    Map<String, dynamic>? extra,
    Map<String, String>? tags,
  }) async {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: hint != null ? Hint.withMap({'message': hint}) : null,
      withScope: (scope) {
        if (extra != null) {
          scope.setExtra('extra_data', extra);
        }
        if (tags != null) {
          tags.forEach((key, value) => scope.setTag(key, value));
        }
      },
    );
  }

  /// Captura un mensaje
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
    Map<String, String>? tags,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level,
      withScope: (scope) {
        if (extra != null) {
          scope.setExtra('extra_data', extra);
        }
        if (tags != null) {
          tags.forEach((key, value) => scope.setTag(key, value));
        }
      },
    );
  }

  /// Inicia una transacción
  static ISentrySpan startTransaction(
    String name,
    String operation, {
    Map<String, dynamic>? data,
  }) {
    return Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
  }

  /// Agrega breadcrumb
  static void addBreadcrumb(
    String message, {
    String? category,
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? data,
  }) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        level: level,
        data: data,
      ),
    );
  }

  /// Configura contexto de usuario
  static void setUserContext({
    String? id,
    String? email,
    String? username,
    Map<String, dynamic>? extra,
  }) {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
        data: extra,
      ));
    });
  }

  /// Configura contexto de tags
  static void setTags(Map<String, String> tags) {
    Sentry.configureScope((scope) {
      tags.forEach((key, value) => scope.setTag(key, value));
    });
  }

  /// Configura contexto de extra
  static void setExtra(String key, dynamic value) {
    Sentry.configureScope((scope) {
      scope.setExtra(key, value);
    });
  }

  /// Cierra Sentry
  static Future<void> close() async {
    await Sentry.close();
  }

}
