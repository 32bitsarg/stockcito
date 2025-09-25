import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';
import '../../../services/ui/clientes/clientes_logic_service.dart';
import '../../../services/ui/clientes/clientes_navigation_service.dart';
import '../../../models/cliente.dart';
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
                if (onNuevoCliente != null)
                  ElevatedButton.icon(
                    onPressed: onNuevoCliente,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo Cliente'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
              onEditarCliente: (cliente) => _editarCliente(context, cliente, logicService, navigationService),
              onEliminarCliente: (cliente) => _eliminarCliente(context, cliente, logicService, navigationService),
            ),
        ],
      ),
    );
  }

  void _editarCliente(
    BuildContext context,
    Cliente cliente,
    ClientesLogicService logicService,
    ClientesNavigationService navigationService,
  ) {
    navigationService.showFormularioCliente(
      context,
      cliente: cliente,
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
        
        // Actualizar cliente
        final exitoso = await logicService.actualizarCliente(
          cliente: cliente!,
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
            ClientesFunctions.getActualizacionSuccessText(),
          );
        } else {
          navigationService.showErrorMessage(
            context,
            ClientesFunctions.getGuardadoErrorText('Error desconocido'),
          );
        }
      },
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
