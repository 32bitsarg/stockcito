import 'package:flutter_dotenv/flutter_dotenv.dart';

class SentryConfig {
  // Cargar DSN desde .env - SIN FALLBACK POR SEGURIDAD
  static String get sentryDsn {
    final dsn = dotenv.env['SENTRY_DSN'];
    if (dsn == null || dsn.isEmpty) {
      throw Exception('SENTRY_DSN no está configurada en el archivo .env');
    }
    return dsn;
  }
  
  // Configuración de Sentry
  static double get tracesSampleRate => double.tryParse(dotenv.env['SENTRY_TRACES_SAMPLE_RATE'] ?? '1.0') ?? 1.0;
  static double get profilesSampleRate => double.tryParse(dotenv.env['SENTRY_PROFILES_SAMPLE_RATE'] ?? '1.0') ?? 1.0;
  static bool get enableAutoSessionTracking => dotenv.env['SENTRY_AUTO_SESSION_TRACKING']?.toLowerCase() != 'false';
  static bool get enableCrashHandling => dotenv.env['SENTRY_CRASH_HANDLING']?.toLowerCase() != 'false';
  
  // Configuración de entorno
  static String get environment => dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';
  static String get release => dotenv.env['SENTRY_RELEASE'] ?? '1.1.0-alpha.1';
  
  // Configuración de logging
  static bool get enableDebugLogging => dotenv.env['SENTRY_DEBUG_LOGGING']?.toLowerCase() == 'true';
  
  // Inicializar dotenv (ya debería estar inicializado, pero por seguridad)
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
