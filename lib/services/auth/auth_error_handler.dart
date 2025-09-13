/// Manejador centralizado de errores de autenticación
/// Proporciona mensajes de error amigables para el usuario
class AuthErrorHandler {
  /// Convierte errores técnicos en mensajes amigables para el usuario
  static String getErrorMessage(String error) {
    // Errores de Firebase (compatibilidad)
    if (error.contains('email-already-in-use')) {
      return 'Ya existe una cuenta con este email. Intenta iniciar sesión.';
    } else if (error.contains('weak-password')) {
      return 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
    } else if (error.contains('invalid-email')) {
      return 'El formato del email no es válido.';
    } else if (error.contains('operation-not-allowed')) {
      return 'Operación no permitida. Contacta al administrador.';
    } else if (error.contains('user-not-found')) {
      return 'No existe una cuenta con este email.';
    } else if (error.contains('wrong-password')) {
      return 'Contraseña incorrecta.';
    } else if (error.contains('too-many-requests')) {
      return 'Demasiados intentos. Espera un momento antes de intentar nuevamente.';
    }
    
    // Errores específicos de Supabase
    if (error.contains('User already registered')) {
      return 'Este email ya está registrado. Intenta iniciar sesión.';
    } else if (error.contains('Password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    } else if (error.contains('Invalid email')) {
      return 'El email no es válido. Verifica el formato.';
    } else if (error.contains('Signup is disabled')) {
      return 'El registro está deshabilitado. Contacta al administrador.';
    } else if (error.contains('Email not confirmed')) {
      return 'Confirma tu email antes de iniciar sesión.';
    } else if (error.contains('Invalid credentials')) {
      return 'Credenciales inválidas. Verifica tu email y contraseña.';
    } else if (error.contains('email_address_invalid')) {
      return 'El email no es válido. Usa un formato correcto como: usuario@ejemplo.com';
    } else if (error.contains('password_too_short')) {
      return 'La contraseña es muy corta. Debe tener al menos 6 caracteres.';
    } else if (error.contains('password_too_weak')) {
      return 'La contraseña es muy débil. Incluye letras, números y símbolos.';
    } else if (error.contains('signup_disabled')) {
      return 'El registro está deshabilitado temporalmente.';
    } else if (error.contains('email_not_confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesión.';
    } else if (error.contains('invalid_credentials')) {
      return 'Email o contraseña incorrectos.';
    } else if (error.contains('too_many_requests')) {
      return 'Demasiados intentos. Espera unos minutos antes de intentar nuevamente.';
    } else if (error.contains('network_error')) {
      return 'Error de conexión. Verifica tu internet e intenta nuevamente.';
    } else if (error.contains('server_error')) {
      return 'Error del servidor. Intenta nuevamente en unos minutos.';
    }
    
    // Errores de validación comunes
    if (error.contains('empty_email')) {
      return 'El email es requerido.';
    } else if (error.contains('empty_password')) {
      return 'La contraseña es requerida.';
    } else if (error.contains('empty_name')) {
      return 'El nombre es requerido.';
    } else if (error.contains('password_mismatch')) {
      return 'Las contraseñas no coinciden.';
    }
    
    // Error genérico si no se encuentra un patrón específico
    return 'Error inesperado. Intenta nuevamente o contacta al soporte.';
  }
  
  /// Valida el formato del email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Valida la fortaleza de la contraseña
  static String? validatePassword(String password) {
    if (password.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (password.length > 72) {
      return 'La contraseña no puede tener más de 72 caracteres';
    }
    return null;
  }
  
  /// Valida que las contraseñas coincidan
  static String? validatePasswordMatch(String password, String confirmPassword) {
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }
  
  /// Valida el nombre completo
  static String? validateName(String name) {
    if (name.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (name.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (name.trim().length > 50) {
      return 'El nombre no puede tener más de 50 caracteres';
    }
    return null;
  }
  
  /// Obtiene sugerencias para mejorar la contraseña
  static List<String> getPasswordSuggestions(String password) {
    List<String> suggestions = [];
    
    if (password.length < 8) {
      suggestions.add('Usa al menos 8 caracteres');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      suggestions.add('Incluye al menos una letra mayúscula');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      suggestions.add('Incluye al menos una letra minúscula');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      suggestions.add('Incluye al menos un número');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      suggestions.add('Incluye al menos un símbolo especial');
    }
    
    return suggestions;
  }
}
