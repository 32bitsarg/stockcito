import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Cargar variables desde .env - SIN FALLBACKS POR SEGURIDAD
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL no está configurada en el archivo .env');
    }
    return url;
  }
  
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY no está configurada en el archivo .env');
    }
    return key;
  }
  
  
  
  // Configuración de seguridad
  static int get sessionTimeoutHours => int.tryParse(dotenv.env['SESSION_TIMEOUT_HOURS'] ?? '24') ?? 24;
  static int get maxLoginAttempts => int.tryParse(dotenv.env['MAX_LOGIN_ATTEMPTS'] ?? '5') ?? 5;
  static int get rateLimitWindowMinutes => int.tryParse(dotenv.env['RATE_LIMIT_WINDOW_MINUTES'] ?? '15') ?? 15;
  
  // Configuración de validación de contraseñas
  static int get minPasswordLength => int.tryParse(dotenv.env['MIN_PASSWORD_LENGTH'] ?? '8') ?? 8;
  static bool get requireUppercase => dotenv.env['REQUIRE_UPPERCASE']?.toLowerCase() == 'true';
  static bool get requireLowercase => dotenv.env['REQUIRE_LOWERCASE']?.toLowerCase() == 'true';
  static bool get requireNumbers => dotenv.env['REQUIRE_NUMBERS']?.toLowerCase() == 'true';
  static bool get requireSymbols => dotenv.env['REQUIRE_SYMBOLS']?.toLowerCase() == 'true';
  
  // Inicializar dotenv
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
