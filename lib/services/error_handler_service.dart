import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/app_theme.dart';

class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// Maneja errores de manera centralizada
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    // Log del error para debugging
    if (kDebugMode) {
      print('❌ Error: $error');
      if (error is Exception) {
        print('❌ Stack trace: ${StackTrace.current}');
      }
    }

    // Determinar el tipo de error y mensaje apropiado
    String message = _getErrorMessage(error, customMessage);
    
    if (showSnackBar) {
      _showErrorSnackBar(context, message, onRetry);
    }
  }

  /// Obtiene el mensaje de error apropiado
  static String _getErrorMessage(dynamic error, String? customMessage) {
    if (customMessage != null) return customMessage;

    if (error is Exception) {
      final errorString = error.toString().toLowerCase();
      
      if (errorString.contains('database') || errorString.contains('sqlite')) {
        return 'Error de base de datos. Verifica la conexión.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        return 'Error de conexión. Verifica tu internet.';
      } else if (errorString.contains('permission')) {
        return 'Error de permisos. Verifica los permisos de la aplicación.';
      } else if (errorString.contains('not found')) {
        return 'Recurso no encontrado.';
      } else if (errorString.contains('validation')) {
        return 'Error de validación. Verifica los datos ingresados.';
      }
    }

    return 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
  }

  /// Muestra un SnackBar de error con opción de reintentar
  static void _showErrorSnackBar(
    BuildContext context,
    String message,
    VoidCallback? onRetry,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Muestra un diálogo de error más detallado
  static void showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (onCancel != null)
            TextButton(
              onPressed: onCancel,
              child: const Text('Cancelar'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          if (onRetry == null && onCancel == null)
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
        ],
      ),
    );
  }

  /// Muestra un indicador de carga con mensaje
  static void showLoadingDialog(
    BuildContext context,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Cierra el diálogo de carga
  static void hideLoadingDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Valida campos de entrada
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Valida números
  static String? validateNumber(String? value, String fieldName) {
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

  /// Valida emails
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email es requerido';
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
      return 'Teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^[\+]?[0-9\s\-\(\)]{8,}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Teléfono debe tener un formato válido';
    }
    return null;
  }
}
