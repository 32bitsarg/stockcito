import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  // Cargar variables desde .env
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://lmqrzsxvbaznwhhtfhwu.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get databaseUrl => dotenv.env['DATABASE_URL'] ?? '';
  
  // Inicializar dotenv
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }
}
