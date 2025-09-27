import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';
import '../../../services/ui/clientes/clientes_logic_service.dart';
import '../../../services/ui/clientes/clientes_navigation_service.dart';
import '../../../services/ui/clientes/clientes_data_service.dart';
import '../../../models/cliente.dart';
import '../modals/client_form_modal.dart';
import '../../../screens/clientes_screen/widgets/clientes_busqueda.dart';
import '../../../screens/clientes_screen/widgets/clientes_lista.dart';
import '../../../screens/clientes_screen/functions/clientes_functions.dart';
import 'clientes_stats_cards.dart';

/// Widget que contiene el contenido principal de la pantalla de clientes
class ClientesContentWidget extends StatelessWidget {
  final VoidCallback? onNuevoCliente;

  const ClientesContentWidget({
    super.key,
    this.onNuevoCliente,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<ClientesLogicService>(context, listen: false);
        final navigationService = Provider.of<ClientesNavigationService>(context, listen: false);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas principales
              const ClientesStatsCards(),
              
              const SizedBox(height: 24),
              
              // Búsqueda
              ClientesBusqueda(
                filtroBusqueda: stateService.filtroBusqueda,
                onBusquedaChanged: (value) {
                  stateService.updateFiltroBusqueda(value);
                },
                onLimpiarBusqueda: () {
                  stateService.clearFiltroBusqueda();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Lista de clientes
              _buildClientesList(context, stateService, logicService, navigationService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClientesList(
    BuildContext context,
    ClientesStateService stateService,
    ClientesLogicService logicService,
    ClientesNavigationService navigationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la lista
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clientes (${stateService.getClientesFiltrados().length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          
          // Contenido de la lista
          if (stateService.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (stateService.clientes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Text(
                  'No hay clientes registrados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            ClientesLista(
              clientes: stateService.getClientesFiltrados().cast<Cliente>(),
              onEditarCliente: (cliente) => _showClientModal(context, cliente),
              onEliminarCliente: (cliente) => _eliminarCliente(context, cliente, logicService, navigationService),
            ),
        ],
      ),
    );
  }

  /// Mostrar modal de edición de cliente
  void _showClientModal(BuildContext context, Cliente? cliente) {
    showDialog(
      context: context,
      builder: (context) => ClientFormModal(
        client: cliente,
        onClientCreated: (nuevoCliente) async {
          try {
            final logicService = Provider.of<ClientesLogicService>(context, listen: false);
            final dataService = Provider.of<ClientesDataService>(context, listen: false);
            
            await dataService.saveCliente(nuevoCliente);
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
        onClientUpdated: (clienteActualizado) async {
          try {
            final logicService = Provider.of<ClientesLogicService>(context, listen: false);
            final dataService = Provider.of<ClientesDataService>(context, listen: false);
            
            await dataService.saveCliente(clienteActualizado);
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

  void _eliminarCliente(
    BuildContext context,
    Cliente cliente,
    ClientesLogicService logicService,
    ClientesNavigationService navigationService,
  ) async {
    final confirmado = await navigationService.showConfirmDelete(context, cliente);
    
    if (confirmado) {
      final exitoso = await logicService.eliminarCliente(cliente.id!);
      
      if (exitoso) {
        navigationService.showSuccessMessage(
          context,
          ClientesFunctions.getEliminacionSuccessText(cliente.nombre),
        );
      } else {
        navigationService.showErrorMessage(
          context,
          ClientesFunctions.getEliminacionErrorText(cliente.nombre),
        );
      }
    }
  }
}


