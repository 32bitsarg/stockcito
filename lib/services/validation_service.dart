class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  /// Valida que un campo no esté vacío
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida que un campo no esté vacío (opcional)
  static String? validateOptional(String? value) {
    return null; // Los campos opcionales siempre son válidos
  }

  /// Valida números positivos
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    if (number < 0) {
      return '$fieldName debe ser mayor o igual a 0';
    }
    return null;
  }

  /// Valida números enteros positivos
  static String? validatePositiveInteger(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número entero válido';
    }
    if (number < 0) {
      return '$fieldName debe ser mayor o igual a 0';
    }
    return null;
  }

  /// Valida stock (debe ser entero positivo)
  static String? validateStock(String? value) {
    return validatePositiveInteger(value, 'Stock');
  }

  /// Valida precios (debe ser número positivo)
  static String? validatePrice(String? value) {
    return validatePositiveNumber(value, 'Precio');
  }

  /// Valida emails
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Email es opcional
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email debe tener un formato válido';
    }
    return null;
  }

  /// Valida teléfonos
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Teléfono es opcional
    }
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{8,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Teléfono debe tener un formato válido';
    }
    return null;
  }

  /// Valida nombres (solo letras y espacios)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final nameRegex = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return '$fieldName solo puede contener letras y espacios';
    }
    if (value.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Valida códigos de producto
  static String? validateProductCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Código de producto es requerido';
    }
    if (value.trim().length < 3) {
      return 'Código debe tener al menos 3 caracteres';
    }
    return null;
  }

  /// Valida descripciones
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Descripción es requerida';
    }
    if (value.trim().length < 10) {
      return 'Descripción debe tener al menos 10 caracteres';
    }
    return null;
  }

  /// Valida notas (opcional pero con longitud máxima)
  static String? validateNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Las notas son opcionales
    }
    if (value.trim().length > 500) {
      return 'Las notas no pueden exceder 500 caracteres';
    }
    return null;
  }

  /// Valida que una lista no esté vacía
  static String? validateListNotEmpty<T>(List<T>? list, String fieldName) {
    if (list == null || list.isEmpty) {
      return 'Debe agregar al menos un $fieldName';
    }
    return null;
  }

  /// Valida rangos de fechas
  static String? validateDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) {
      return 'Fechas de inicio y fin son requeridas';
    }
    if (start.isAfter(end)) {
      return 'La fecha de inicio debe ser anterior a la fecha de fin';
    }
    return null;
  }

  /// Valida que un valor esté en una lista de opciones
  static String? validateInList<T>(T? value, List<T> options, String fieldName) {
    if (value == null) {
      return '$fieldName es requerido';
    }
    if (!options.contains(value)) {
      return '$fieldName debe ser una de las opciones válidas';
    }
    return null;
  }

  /// Valida porcentajes (0-100)
  static String? validatePercentage(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return '$fieldName debe ser un número válido';
    }
    if (number < 0 || number > 100) {
      return '$fieldName debe estar entre 0 y 100';
    }
    return null;
  }

  /// Valida que un valor sea mayor que otro
  static String? validateGreaterThan(
    double? value,
    double? minValue,
    String fieldName,
    String minFieldName,
  ) {
    if (value == null || minValue == null) {
      return null; // Dejar que otros validadores manejen valores nulos
    }
    if (value <= minValue) {
      return '$fieldName debe ser mayor que $minFieldName';
    }
    return null;
  }

  /// Valida que un valor esté en un rango
  static String? validateRange(
    double? value,
    double min,
    double max,
    String fieldName,
  ) {
    if (value == null) {
      return '$fieldName es requerido';
    }
    if (value < min || value > max) {
      return '$fieldName debe estar entre $min y $max';
    }
    return null;
  }
}
