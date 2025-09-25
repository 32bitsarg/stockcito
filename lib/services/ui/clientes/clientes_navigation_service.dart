import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../models/cliente.dart';
import '../../../screens/clientes_screen/widgets/clientes_formulario.dart';
import '../../../screens/clientes_screen/widgets/clientes_confirmacion_eliminar.dart';
import '../../../screens/clientes_screen/functions/clientes_functions.dart';

/// Servicio que maneja la navegación de los clientes
class ClientesNavigationService {
  ClientesNavigationService();

  /// Mostrar modal de formulario de cliente
  void showFormularioCliente(BuildContext context, {
    required Function({
      required bool isEditing,
      Cliente? cliente,
      required String nombre,
      required String telefono,
      required String email,
      required String direccion,
      required String notas,
    }) onGuardar,
    Cliente? cliente,
  }) {
    try {
      final isEditing = cliente != null;
      LoggingService.info('📝 Mostrando formulario de cliente: ${isEditing ? 'edición' : 'creación'}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            height: MediaQuery.of(context).size.height * 0.8,
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
              child: ClientesFormulario(
                isEditing: isEditing,
                cliente: cliente,
                onGuardar: onGuardar,
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando formulario de cliente: $e');
    }
  }

  /// Mostrar diálogo de confirmación de eliminación
  Future<bool> showConfirmDelete(BuildContext context, dynamic cliente) async {
    try {
      LoggingService.info('🗑️ Mostrando confirmación de eliminación: ${cliente.nombre}');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => ClientesConfirmacionEliminar(
          cliente: cliente,
          onConfirmar: (cliente) => Navigator.of(context).pop(true),
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
      ClientesFunctions.showSuccessSnackBar(context, message);
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de éxito: $e');
    }
  }

  /// Mostrar mensaje de error
  void showErrorMessage(BuildContext context, String message) {
    try {
      ClientesFunctions.showErrorSnackBar(context, message);
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
