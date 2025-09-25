import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../screens/reportes_screen/widgets/producto_detail_modal.dart';
import '../../../screens/inventario_screen/widgets/editar_producto/editar_producto_screen.dart';

/// Servicio que maneja la navegación de los reportes
class ReportesNavigationService {
  ReportesNavigationService();

  /// Mostrar modal de detalles de producto
  void showProductoDetails(BuildContext context, dynamic producto) {
    try {
      LoggingService.info('👁️ Mostrando detalles de producto: ${producto.nombre}');
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
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
              child: ProductoDetailModal(producto: producto),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando detalles de producto: $e');
    }
  }

  /// Mostrar modal de edición de producto
  void showProductoEdit(BuildContext context, dynamic producto) {
    try {
      LoggingService.info('✏️ Mostrando edición de producto: ${producto.nombre}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
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
              child: EditarProductoScreen(producto: producto),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando edición de producto: $e');
    }
  }

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

  /// Cerrar modal actual
  void closeModal(BuildContext context) {
    try {
      Navigator.of(context).pop();
    } catch (e) {
      LoggingService.error('❌ Error cerrando modal: $e');
    }
  }
}

