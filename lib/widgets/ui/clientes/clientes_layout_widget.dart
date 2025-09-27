import 'package:flutter/material.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';
import '../../../services/ui/clientes/clientes_logic_service.dart';
import '../../../services/ui/clientes/clientes_navigation_service.dart';
import '../../../services/ui/clientes/clientes_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import '../modals/client_form_modal.dart';
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
          onNuevoCliente: () => _showClientModal(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClientModal(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Cliente'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Mostrar modal de cliente
  void _showClientModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ClientFormModal(
        onClientCreated: (cliente) async {
          try {
            await dataService.saveCliente(cliente);
            // Recargar datos
            await logicService.loadClientes();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear cliente: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onClientUpdated: (cliente) async {
          try {
            await dataService.saveCliente(cliente);
            // Recargar datos
            await logicService.loadClientes();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cliente actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar cliente: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

}
