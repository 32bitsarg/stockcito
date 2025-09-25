import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../screens/calcularprecios_screen/widgets/calculadora_costo_directo_dialog.dart';
import '../../../screens/calcularprecios_screen/widgets/calculadora_costo_indirecto_dialog.dart';

/// Servicio que maneja la navegación de la calculadora de precios
class CalculadoraNavigationService {
  CalculadoraNavigationService();

  /// Mostrar mensaje de éxito
  void showSuccessMessage(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de éxito: $e');
    }
  }

  /// Mostrar mensaje de error
  void showErrorMessage(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
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

  /// Mostrar diálogo de costo directo
  Future<Map<String, dynamic>?> showCostoDirectoDialog(BuildContext context) async {
    try {
      LoggingService.info('💰 Mostrando diálogo de costo directo');
      
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const CalculadoraCostoDirectoDialog(),
            ),
          ),
        ),
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de costo directo: $e');
      return null;
    }
  }

  /// Mostrar diálogo de costo indirecto
  Future<Map<String, dynamic>?> showCostoIndirectoDialog(BuildContext context) async {
    try {
      LoggingService.info('💼 Mostrando diálogo de costo indirecto');
      
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: const CalculadoraCostoIndirectoDialog(),
            ),
          ),
        ),
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de costo indirecto: $e');
      return null;
    }
  }

  /// Mostrar diálogo de resetear calculadora
  Future<bool> showResetDialog(BuildContext context) async {
    try {
      LoggingService.info('🔄 Mostrando diálogo de reset');
      
      final result = await showConfirmationDialog(
        context,
        'Resetear Calculadora',
        '¿Estás seguro de que deseas resetear toda la calculadora? Se perderán todos los datos ingresados.',
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de reset: $e');
      return false;
    }
  }

  /// Mostrar diálogo de guardar producto
  Future<bool> showSaveProductDialog(BuildContext context) async {
    try {
      LoggingService.info('💾 Mostrando diálogo de guardar producto');
      
      final result = await showConfirmationDialog(
        context,
        'Guardar Producto',
        '¿Deseas guardar este producto en el inventario?',
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de guardar producto: $e');
      return false;
    }
  }

  /// Mostrar diálogo de exportar resultado
  Future<bool> showExportDialog(BuildContext context) async {
    try {
      LoggingService.info('📤 Mostrando diálogo de exportar');
      
      final result = await showConfirmationDialog(
        context,
        'Exportar Resultado',
        '¿Deseas exportar el resultado del cálculo a un archivo?',
      );
      
      return result;
    } catch (e) {
      LoggingService.error('❌ Error mostrando diálogo de exportar: $e');
      return false;
    }
  }

  /// Cerrar modal actual
  void closeModal(BuildContext context) {
    try {
      Navigator.of(context).pop();
    } catch (e) {
      LoggingService.error('❌ Error cerrando modal: $e');
    }
  }

  /// Navegar al paso anterior
  void goToPreviousStep(BuildContext context) {
    try {
      LoggingService.info('⬅️ Navegando al paso anterior');
      // La lógica de navegación se maneja en el servicio de estado
    } catch (e) {
      LoggingService.error('❌ Error navegando al paso anterior: $e');
    }
  }

  /// Navegar al siguiente paso
  void goToNextStep(BuildContext context) {
    try {
      LoggingService.info('➡️ Navegando al siguiente paso');
      // La lógica de navegación se maneja en el servicio de estado
    } catch (e) {
      LoggingService.error('❌ Error navegando al siguiente paso: $e');
    }
  }

  /// Navegar a un paso específico
  void goToStep(BuildContext context, int step) {
    try {
      LoggingService.info('🎯 Navegando al paso: $step');
      // La lógica de navegación se maneja en el servicio de estado
    } catch (e) {
      LoggingService.error('❌ Error navegando al paso $step: $e');
    }
  }
}
