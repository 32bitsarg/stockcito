import 'package:flutter/material.dart';
import '../../../models/cliente.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';
import '../../../services/ui/clientes/clientes_logic_service.dart';
import '../../../services/ui/clientes/clientes_navigation_service.dart';
import '../../../services/ui/clientes/clientes_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'clientes_content_widget.dart';

/// Widget que define el layout principal de la pantalla de clientes
class ClientesLayoutWidget extends StatelessWidget {
  final ClientesStateService stateService;
  final ClientesLogicService logicService;
  final ClientesNavigationService navigationService;
  final ClientesDataService dataService;

  const ClientesLayoutWidget({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo completamente blanco
      body: DashboardGlassmorphismWidget(
        child: ClientesContentWidget(
          onNuevoCliente: () => _nuevoCliente(context),
        ),
      ),
    );
  }

  void _nuevoCliente(BuildContext context) {
    navigationService.showFormularioCliente(
      context,
      onGuardar: ({
        required bool isEditing,
        Cliente? cliente,
        required String nombre,
        required String telefono,
        required String email,
        required String direccion,
        required String notas,
      }) async {
        // Validar formulario
        final errores = logicService.validateFormulario(
          nombre: nombre,
          telefono: telefono,
          email: email,
          direccion: direccion,
          notas: notas,
        );
        
        if (errores.values.any((error) => error != null)) {
          // Hay errores de validación, no hacer nada
          return;
        }
        
        // Crear cliente
        final exitoso = await logicService.crearCliente(
          nombre: nombre,
          telefono: telefono,
          email: email,
          direccion: direccion,
          notas: notas,
        );
        
        if (exitoso) {
          navigationService.closeModal(context);
          navigationService.showSuccessMessage(
            context,
            'Cliente creado correctamente',
          );
        } else {
          navigationService.showErrorMessage(
            context,
            'Error al crear el cliente',
          );
        }
      },
    );
  }
}
