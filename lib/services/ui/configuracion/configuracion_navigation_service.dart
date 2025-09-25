import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../screens/configuracion_screen/functions/configuracion_functions.dart';

/// Servicio que maneja la navegación de la configuración
class ConfiguracionNavigationService {
  ConfiguracionNavigationService();

  /// Mostrar mensaje de éxito
  void showSuccessMessage(BuildContext context, String message) {
    try {
      ConfiguracionFunctions.showSuccessSnackBar(context, message);
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de éxito: $e');
    }
  }

  /// Mostrar mensaje de error
  void showErrorMessage(BuildContext context, String message) {
    try {
      ConfiguracionFunctions.showErrorSnackBar(context, message);
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de error: $e');
    }
  }

  /// Mostrar diálogo de confirmación
  Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    try {
      LoggingService.info('❓ Mostrando diálogo de confirmación: $title');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de confirmación: $e');
      return false;
    }
  }

  /// Mostrar diálogo de importación de configuración
  Future<Map<String, dynamic>?> showImportDialog(BuildContext context) async {
    try {
      LoggingService.info('📥 Mostrando diálogo de importación');
      
      // Simular selección de archivo
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importar Configuración'),
          content: const Text('¿Deseas importar la configuración desde un archivo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Simular configuración importada
                Navigator.of(context).pop({
                  'margenDefecto': 45.0,
                  'iva': 19.0,
                  'moneda': 'EUR',
                  'notificacionesStock': true,
                  'notificacionesVentas': true,
                  'exportarAutomatico': true,
                  'respaldoAutomatico': true,
                  'mlConsentimiento': true,
                  'stockMinimo': 10,
                });
              },
              child: const Text('Importar'),
            ),
          ],
        ),
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de importación: $e');
      return null;
    }
  }

  /// Mostrar diálogo de exportación de configuración
  Future<bool> showExportDialog(BuildContext context) async {
    try {
      LoggingService.info('📤 Mostrando diálogo de exportación');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exportar Configuración'),
          content: const Text('¿Deseas exportar la configuración actual a un archivo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exportar'),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de exportación: $e');
      return false;
    }
  }

  /// Mostrar diálogo de resetear configuración
  Future<bool> showResetDialog(BuildContext context) async {
    try {
      LoggingService.info('🔄 Mostrando diálogo de reset');
      
      final result = await showConfirmationDialog(
        context,
        'Resetear Configuración',
        '¿Estás seguro de que deseas resetear toda la configuración a los valores por defecto? Esta acción no se puede deshacer.',
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de reset: $e');
      return false;
    }
  }

  /// Mostrar diálogo de consentimiento ML
  Future<bool> showMLConsentDialog(BuildContext context) async {
    try {
      LoggingService.info('🤖 Mostrando diálogo de consentimiento ML');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Consentimiento para Machine Learning'),
          content: const Text(
            '¿Deseas otorgar consentimiento para el uso de Machine Learning? '
            'Esto nos permitirá mejorar las recomendaciones y análisis automáticos.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí'),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de consentimiento ML: $e');
      return false;
    }
  }

  /// Navegar a configuración avanzada
  void navigateToAdvancedSettings(BuildContext context) {
    try {
      LoggingService.info('⚙️ Navegando a configuración avanzada');
      // Implementar navegación si es necesario
    } catch (e) {
      LoggingService.error('❌ Error navegando a configuración avanzada: $e');
    }
  }

  /// Navegar a configuración de backup
  void navigateToBackupSettings(BuildContext context) {
    try {
      LoggingService.info('💾 Navegando a configuración de backup');
      // Implementar navegación si es necesario
    } catch (e) {
      LoggingService.error('❌ Error navegando a configuración de backup: $e');
    }
  }
}
