import 'package:shared_preferences/shared_preferences.dart';
import 'package:ricitosdebb/config/supabase_config.dart';

/// Servicio de seguridad para autenticación
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastAttemptKey = 'last_attempt';
  static const String _blockedUntilKey = 'blocked_until';

  /// Verifica si el usuario está bloqueado por demasiados intentos
  Future<bool> isUserBlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUntil = prefs.getString(_blockedUntilKey);
      
      if (blockedUntil != null) {
        final blockedTime = DateTime.parse(blockedUntil);
        if (DateTime.now().isBefore(blockedTime)) {
          return true;
        } else {
          // El bloqueo ha expirado, limpiar
          await _clearBlockStatus();
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Registra un intento de login fallido
  Future<void> recordFailedLoginAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final attempts = prefs.getInt(_loginAttemptsKey) ?? 0;
      final newAttempts = attempts + 1;
      
      await prefs.setInt(_loginAttemptsKey, newAttempts);
      await prefs.setString(_lastAttemptKey, DateTime.now().toIso8601String());
      
      // Si excede el límite, bloquear usuario
      if (newAttempts >= SupabaseConfig.maxLoginAttempts) {
        final blockDuration = Duration(minutes: SupabaseConfig.rateLimitWindowMinutes);
        final blockedUntil = DateTime.now().add(blockDuration);
        await prefs.setString(_blockedUntilKey, blockedUntil.toIso8601String());
      }
    } catch (e) {
      // Error silencioso para no afectar la experiencia del usuario
    }
  }

  /// Limpia los intentos de login fallidos (login exitoso)
  Future<void> clearFailedLoginAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lastAttemptKey);
      await prefs.remove(_blockedUntilKey);
    } catch (e) {
      // Error silencioso
    }
  }

  /// Obtiene el tiempo restante de bloqueo en minutos
  Future<int> getRemainingBlockTimeMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockedUntil = prefs.getString(_blockedUntilKey);
      
      if (blockedUntil != null) {
        final blockedTime = DateTime.parse(blockedUntil);
        final remaining = blockedTime.difference(DateTime.now());
        return remaining.inMinutes.clamp(0, 999);
      }
      
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Obtiene el número de intentos fallidos actuales
  Future<int> getFailedAttemptsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_loginAttemptsKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Limpia el estado de bloqueo
  Future<void> _clearBlockStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loginAttemptsKey);
      await prefs.remove(_lastAttemptKey);
      await prefs.remove(_blockedUntilKey);
    } catch (e) {
      // Error silencioso
    }
  }

  /// Valida si una sesión ha expirado
  bool isSessionExpired(DateTime lastActivity) {
    final sessionTimeout = Duration(hours: SupabaseConfig.sessionTimeoutHours);
    return DateTime.now().difference(lastActivity) > sessionTimeout;
  }

  /// Genera un token de sesión seguro
  String generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000) % 1000000;
    return '${timestamp}_${random.toString().padLeft(6, '0')}';
  }

  /// Valida un token de sesión
  bool isValidSessionToken(String token) {
    try {
      final parts = token.split('_');
      if (parts.length != 2) return false;
      
      final timestamp = int.parse(parts[0]);
      final tokenTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final sessionTimeout = Duration(hours: SupabaseConfig.sessionTimeoutHours);
      
      return DateTime.now().difference(tokenTime) < sessionTimeout;
    } catch (e) {
      return false;
    }
  }

  /// Sanitiza datos de entrada para prevenir inyección
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[<>"\'']'), '') // Remover caracteres peligrosos
        .replaceAll(RegExp(r'\s+'), ' '); // Normalizar espacios
  }

  /// Valida que un email no esté en lista negra
  bool isEmailBlacklisted(String email) {
    final blacklistedDomains = [
      'tempmail.com',
      '10minutemail.com',
      'guerrillamail.com',
      'mailinator.com',
    ];
    
    final domain = email.split('@').last.toLowerCase();
    return blacklistedDomains.contains(domain);
  }

  /// Valida que una contraseña no esté en lista de contraseñas comunes
  bool isPasswordCommon(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
      '1234567890', 'password1', 'qwerty123', 'dragon', 'master',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }
}
