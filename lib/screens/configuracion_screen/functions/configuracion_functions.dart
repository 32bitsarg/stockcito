import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/app_theme.dart';
import '../../../services/datos/smart_alerts_service.dart';
import '../../../services/ml/ml_consent_service.dart';
import '../../../services/system/export_service.dart';

class ConfiguracionFunctions {
  /// Carga la configuración desde SharedPreferences
  static Future<Map<String, dynamic>> loadConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentService = MLConsentService();
      final hasConsent = await consentService.hasUserGivenConsent();
      
      return {
        'stockMinimo': prefs.getInt('min_stock_level') ?? 5,
        'notificacionesStock': prefs.getBool('notificaciones_stock') ?? true,
        'notificacionesVentas': prefs.getBool('notificaciones_ventas') ?? false,
        'margenDefecto': prefs.getDouble('margen_defecto') ?? 50.0,
        'iva': prefs.getDouble('iva') ?? 21.0,
        'moneda': prefs.getString('moneda') ?? 'USD',
        'exportarAutomatico': prefs.getBool('exportar_automatico') ?? false,
        'respaldoAutomatico': prefs.getBool('respaldo_automatico') ?? true,
        'mlConsentimiento': hasConsent,
      };
    } catch (e) {
      print('Error cargando configuración: $e');
      return _getDefaultConfiguracion();
    }
  }

  /// Guarda la configuración en SharedPreferences
  static Future<bool> saveConfiguracion(Map<String, dynamic> config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setInt('min_stock_level', config['stockMinimo']);
      await prefs.setBool('notificaciones_stock', config['notificacionesStock']);
      await prefs.setBool('notificaciones_ventas', config['notificacionesVentas']);
      await prefs.setDouble('margen_defecto', config['margenDefecto']);
      await prefs.setDouble('iva', config['iva']);
      await prefs.setString('moneda', config['moneda']);
      await prefs.setBool('exportar_automatico', config['exportarAutomatico']);
      await prefs.setBool('respaldo_automatico', config['respaldoAutomatico']);
      
      // Actualizar el servicio de alertas con la nueva configuración
      final alertsService = SmartAlertsService();
      await alertsService.updateMinStockLevel(config['stockMinimo']);
      
      return true;
    } catch (e) {
      print('Error guardando configuración: $e');
      return false;
    }
  }

  /// Procesa el consentimiento de ML
  static Future<bool> toggleMLConsentimiento(bool value) async {
    try {
      final consentService = MLConsentService();
      await consentService.processUserConsent(value);
      return true;
    } catch (e) {
      print('Error actualizando consentimiento ML: $e');
      return false;
    }
  }

  /// Obtiene la configuración por defecto
  static Map<String, dynamic> _getDefaultConfiguracion() {
    return {
      'stockMinimo': 5,
      'notificacionesStock': true,
      'notificacionesVentas': false,
      'margenDefecto': 50.0,
      'iva': 21.0,
      'moneda': 'USD',
      'exportarAutomatico': false,
      'respaldoAutomatico': true,
      'mlConsentimiento': false,
    };
  }

  /// Obtiene la configuración por defecto para restaurar
  static Map<String, dynamic> getDefaultConfiguracion() {
    return _getDefaultConfiguracion();
  }

  /// Obtiene las monedas disponibles
  static List<String> getMonedas() {
    return ['USD', 'EUR', 'ARS', 'MXN', 'COP', 'BRL', 'CLP'];
  }

  /// Obtiene los temas disponibles
  static List<String> getTemas() {
    return ['Claro', 'Oscuro', 'Automático'];
  }

  /// Muestra un SnackBar de éxito
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Muestra un SnackBar de error
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Valida un valor numérico dentro de un rango
  static bool isValidRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  /// Valida un valor entero dentro de un rango
  static bool isValidIntRange(int value, int min, int max) {
    return value >= min && value <= max;
  }

  /// Formatea un valor numérico con decimales
  static String formatNumber(double value, {int decimals = 1}) {
    return value.toStringAsFixed(decimals);
  }

  /// Obtiene el icono para un tema
  static IconData getTemaIcon(String tema) {
    switch (tema) {
      case 'Claro':
        return Icons.light_mode;
      case 'Oscuro':
        return Icons.dark_mode;
      case 'Automático':
        return Icons.auto_mode;
      default:
        return Icons.auto_mode;
    }
  }

  /// Obtiene el color para un tema
  static Color getTemaColor(String tema, bool isSelected) {
    if (isSelected) {
      return AppTheme.primaryColor;
    }
    return AppTheme.textSecondary;
  }

  /// Exporta la configuración a JSON
  static Future<String> exportarConfiguracion(Map<String, dynamic> config) async {
    try {
      final exportService = ExportService();
      return await exportService.exportConfiguracionToJSON(config);
    } catch (e) {
      throw Exception('Error exportando configuración: $e');
    }
  }

  /// Importa la configuración desde JSON
  static Future<Map<String, dynamic>> importarConfiguracion(String filePath) async {
    try {
      final exportService = ExportService();
      return await exportService.importConfiguracionFromJSON(filePath);
    } catch (e) {
      throw Exception('Error importando configuración: $e');
    }
  }

  /// Muestra diálogo de exportación exitosa
  static void showExportSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Exportada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('La configuración se ha exportado correctamente:'),
            const SizedBox(height: 8),
            Text(
              filePath.split('/').last,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El archivo se encuentra en la carpeta de documentos de la aplicación.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo de importación exitosa
  static void showImportSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración Importada'),
        content: const Text('La configuración se ha importado correctamente. Reinicia la aplicación para aplicar todos los cambios.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
