import 'package:stockcito/config/supabase_config.dart';

/// Servicio de validación robusta de contraseñas
class PasswordValidationService {
  /// Valida la fortaleza de una contraseña
  static PasswordValidationResult validatePassword(String password) {
    final errors = <String>[];
    final suggestions = <String>[];
    
    // Longitud mínima
    if (password.length < SupabaseConfig.minPasswordLength) {
      errors.add('La contraseña debe tener al menos ${SupabaseConfig.minPasswordLength} caracteres');
    }
    
    // Longitud máxima (seguridad)
    if (password.length > 128) {
      errors.add('La contraseña no puede tener más de 128 caracteres');
    }
    
    // Letras mayúsculas
    if (SupabaseConfig.requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('La contraseña debe contener al menos una letra mayúscula');
      suggestions.add('Incluye al menos una letra mayúscula (A-Z)');
    }
    
    // Letras minúsculas
    if (SupabaseConfig.requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('La contraseña debe contener al menos una letra minúscula');
      suggestions.add('Incluye al menos una letra minúscula (a-z)');
    }
    
    // Números
    if (SupabaseConfig.requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('La contraseña debe contener al menos un número');
      suggestions.add('Incluye al menos un número (0-9)');
    }
    
    // Símbolos especiales
    if (SupabaseConfig.requireSymbols && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('La contraseña debe contener al menos un símbolo especial');
      suggestions.add('Incluye al menos un símbolo especial (!@#\$%^&*...)');
    }
    
    // Verificar patrones comunes inseguros
    if (_hasCommonPatterns(password)) {
      errors.add('La contraseña contiene patrones inseguros');
      suggestions.add('Evita secuencias como "123", "abc", "qwerty"');
    }
    
    // Verificar repetición excesiva
    if (_hasExcessiveRepetition(password)) {
      errors.add('La contraseña tiene demasiada repetición de caracteres');
      suggestions.add('Evita repetir el mismo carácter muchas veces');
    }
    
    // Calcular puntuación de seguridad
    final securityScore = _calculateSecurityScore(password);
    
    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      suggestions: suggestions,
      securityScore: securityScore,
      strengthLevel: _getStrengthLevel(securityScore),
    );
  }
  
  /// Verifica si la contraseña tiene patrones comunes inseguros
  static bool _hasCommonPatterns(String password) {
    final commonPatterns = [
      '123', 'abc', 'qwerty', 'password', 'admin', 'login',
      'asdf', 'zxcv', '111', '000', 'aaa', 'zzz'
    ];
    
    final lowerPassword = password.toLowerCase();
    return commonPatterns.any((pattern) => lowerPassword.contains(pattern));
  }
  
  /// Verifica si hay repetición excesiva de caracteres
  static bool _hasExcessiveRepetition(String password) {
    if (password.length < 4) return false;
    
    for (int i = 0; i < password.length - 2; i++) {
      final char = password[i];
      int count = 1;
      
      for (int j = i + 1; j < password.length; j++) {
        if (password[j] == char) {
          count++;
        } else {
          break;
        }
      }
      
      if (count >= 3) return true;
    }
    
    return false;
  }
  
  /// Calcula la puntuación de seguridad (0-100)
  static int _calculateSecurityScore(String password) {
    int score = 0;
    
    // Longitud (máximo 30 puntos)
    if (password.length >= 8) score += 10;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    
    // Complejidad (máximo 40 puntos)
    if (password.contains(RegExp(r'[a-z]'))) score += 8;
    if (password.contains(RegExp(r'[A-Z]'))) score += 8;
    if (password.contains(RegExp(r'[0-9]'))) score += 8;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 8;
    if (password.contains(RegExp(r'[^a-zA-Z0-9!@#$%^&*(),.?":{}|<>]'))) score += 8;
    
    // Variedad de caracteres (máximo 20 puntos)
    final uniqueChars = password.split('').toSet().length;
    if (uniqueChars >= password.length * 0.6) score += 20;
    else if (uniqueChars >= password.length * 0.4) score += 15;
    else if (uniqueChars >= password.length * 0.2) score += 10;
    
    // Penalizaciones (máximo -20 puntos)
    if (_hasCommonPatterns(password)) score -= 10;
    if (_hasExcessiveRepetition(password)) score -= 10;
    
    return score.clamp(0, 100);
  }
  
  /// Obtiene el nivel de fortaleza basado en la puntuación
  static PasswordStrengthLevel _getStrengthLevel(int score) {
    if (score >= 80) return PasswordStrengthLevel.veryStrong;
    if (score >= 60) return PasswordStrengthLevel.strong;
    if (score >= 40) return PasswordStrengthLevel.medium;
    if (score >= 20) return PasswordStrengthLevel.weak;
    return PasswordStrengthLevel.veryWeak;
  }
  
  /// Valida que las contraseñas coincidan
  static String? validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
}

/// Resultado de la validación de contraseña
class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> suggestions;
  final int securityScore;
  final PasswordStrengthLevel strengthLevel;
  
  const PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.suggestions,
    required this.securityScore,
    required this.strengthLevel,
  });
  
  String get strengthText {
    switch (strengthLevel) {
      case PasswordStrengthLevel.veryWeak:
        return 'Muy débil';
      case PasswordStrengthLevel.weak:
        return 'Débil';
      case PasswordStrengthLevel.medium:
        return 'Media';
      case PasswordStrengthLevel.strong:
        return 'Fuerte';
      case PasswordStrengthLevel.veryStrong:
        return 'Muy fuerte';
    }
  }
  
  String get strengthDescription {
    switch (strengthLevel) {
      case PasswordStrengthLevel.veryWeak:
        return 'Fácil de adivinar';
      case PasswordStrengthLevel.weak:
        return 'Puede ser vulnerable';
      case PasswordStrengthLevel.medium:
        case PasswordStrengthLevel.strong:
        return 'Nivel de seguridad aceptable';
      case PasswordStrengthLevel.veryStrong:
        return 'Excelente nivel de seguridad';
    }
  }
}

/// Niveles de fortaleza de contraseña
enum PasswordStrengthLevel {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}
