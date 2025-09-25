import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../screens/ventas_screen/widgets/nueva_venta/nueva_venta_screen.dart';

/// Servicio que maneja la navegación de las ventas
class VentasNavigationService {
  VentasNavigationService();
  
  /// Mostrar modal de nueva venta
  void navigateToNuevaVenta(BuildContext context) {
    try {
      LoggingService.info('➕ Mostrando modal de nueva venta');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            height: MediaQuery.of(context).size.height * 0.95,
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
              child: const NuevaVentaScreen(),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando modal de nueva venta: $e');
    }
  }

  /// Mostrar modal de detalles de venta
  void showVentaDetails(BuildContext context, dynamic venta) {
    try {
      LoggingService.info('👁️ Mostrando detalles de venta: ${venta.id}');
      
      showDialog(
        context: context,
        builder: (context) => _buildVentaDetailsModal(venta),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando detalles de venta: $e');
    }
  }

  /// Construir modal de detalles de venta
  Widget _buildVentaDetailsModal(dynamic venta) {
    return Builder(
      builder: (context) => AlertDialog(
        title: Text('Detalles de Venta #${venta.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${venta.cliente}'),
            Text('Total: \$${venta.total.toStringAsFixed(2)}'),
            Text('Estado: ${venta.estado}'),
            Text('Fecha: ${venta.fecha.toString()}'),
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

  /// Mostrar modal de edición de venta
  void showVentaEdit(BuildContext context, dynamic venta) {
    try {
      LoggingService.info('✏️ Mostrando edición de venta: ${venta.id}');
      
      showDialog(
        context: context,
        builder: (context) => _buildVentaEditModal(venta),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando edición de venta: $e');
    }
  }

  /// Construir modal de edición de venta
  Widget _buildVentaEditModal(dynamic venta) {
    return Builder(
      builder: (context) => AlertDialog(
        title: Text('Editar Venta #${venta.id}'),
        content: const Text('Modal de edición de venta (placeholder)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  /// Mostrar diálogo de confirmación de eliminación
  Future<bool> showConfirmDelete(BuildContext context, String ventaInfo) async {
    try {
      LoggingService.info('🗑️ Mostrando confirmación de eliminación: $ventaInfo');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Venta'),
          content: Text('¿Estás seguro de que quieres eliminar esta venta?\n\n$ventaInfo'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      LoggingService.error('❌ Error mostrando confirmación: $e');
      return false;
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
}
