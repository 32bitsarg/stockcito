import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/ui/ventas/ventas_state_service.dart';
import '../../../services/ui/ventas/ventas_logic_service.dart';
import '../../../services/ui/ventas/ventas_navigation_service.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../utility/lazy_list_widget.dart';
import '../../../screens/ventas_screen/widgets/ventas_filters_widget.dart';
import '../../../screens/ventas_screen/functions/ventas_functions.dart';
import 'ventas_stats_cards.dart';

/// Widget que contiene el contenido principal de la pantalla de ventas
class VentasContentWidget extends StatelessWidget {
  final VoidCallback? onNuevaVenta;

  const VentasContentWidget({
    super.key,
    this.onNuevaVenta,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<VentasLogicService>(context, listen: false);
        final navigationService = Provider.of<VentasNavigationService>(context, listen: false);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas principales
              const VentasStatsCards(),
              
              const SizedBox(height: 24),
              
              // Filtros
              VentasFiltersWidget(
                filtroEstado: stateService.filtroEstado,
                filtroCliente: stateService.filtroCliente,
                filtroMetodoPago: stateService.filtroMetodoPago,
                clientes: stateService.clientes.cast<Cliente>(),
                estados: stateService.estados,
                metodosPago: stateService.metodosPago,
                onEstadoChanged: (estado) {
                  stateService.updateFiltroEstado(estado);
                },
                onClienteChanged: (cliente) {
                  stateService.updateFiltroCliente(cliente);
                },
                onMetodoPagoChanged: (metodoPago) {
                  stateService.updateFiltroMetodoPago(metodoPago);
                },
              ),
              
              const SizedBox(height: 24),
              
              // Lista de ventas con lazy loading
              _buildVentasList(context, stateService, logicService, navigationService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVentasList(
    BuildContext context,
    VentasStateService stateService,
    VentasLogicService logicService,
    VentasNavigationService navigationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                const Text(
                  'Ventas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista lazy loading
          SizedBox(
            height: 400, // Altura fija para la lista
            child: LazyListWidget<Venta>(
              entityKey: 'ventas',
              itemBuilder: (venta, index) => _buildVentaCard(
                context,
                venta,
                index,
                navigationService,
              ),
              dataLoader: (page, limit) => logicService.getVentasLazy(
                page: page,
                limit: limit,
                filters: stateService.getCurrentFilters(),
              ),
              emptyWidget: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'No hay ventas registradas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              loadingWidget: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(
    BuildContext context,
    Venta venta,
    int index,
    VentasNavigationService navigationService,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigationService.showVentaDetails(context, venta),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de estado
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getEstadoColor(venta.estado).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getEstadoIcon(venta.estado),
                    color: _getEstadoColor(venta.estado),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Información de la venta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Venta #${venta.id}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        venta.cliente,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Total y fecha
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      VentasFunctions.formatPrecio(venta.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFecha(venta.fecha),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Botón de acciones
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, value, venta, navigationService),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ver',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Ver detalles'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return const Color(0xFF10B981);
      case 'pendiente':
        return const Color(0xFFF59E0B);
      case 'cancelada':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return FontAwesomeIcons.circleCheck;
      case 'pendiente':
        return FontAwesomeIcons.clock;
      case 'cancelada':
        return FontAwesomeIcons.circleXmark;
      default:
        return FontAwesomeIcons.circleQuestion;
    }
  }

  String _formatFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha).inDays;
    
    if (diferencia == 0) {
      return 'Hoy';
    } else if (diferencia == 1) {
      return 'Ayer';
    } else if (diferencia < 7) {
      return 'Hace $diferencia días';
    } else {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
  }

  void _handleAction(
    BuildContext context,
    String action,
    Venta venta,
    VentasNavigationService navigationService,
  ) {
    switch (action) {
      case 'ver':
        navigationService.showVentaDetails(context, venta);
        break;
      case 'editar':
        navigationService.showVentaEdit(context, venta);
        break;
      case 'eliminar':
        _confirmDelete(context, venta, navigationService);
        break;
    }
  }

  void _confirmDelete(
    BuildContext context,
    Venta venta,
    VentasNavigationService navigationService,
  ) async {
    final confirmado = await navigationService.showConfirmDelete(
      context,
      'Venta #${venta.id} - ${venta.cliente} - ${VentasFunctions.formatPrecio(venta.total)}',
    );
    
    if (confirmado) {
      final logicService = Provider.of<VentasLogicService>(context, listen: false);
      final eliminado = await logicService.eliminarVenta(venta.id ?? 0);
      
      if (context.mounted) {
        if (eliminado) {
          navigationService.showSuccessMessage(context, 'Venta eliminada correctamente');
        } else {
          navigationService.showErrorMessage(context, 'Error al eliminar la venta');
        }
      }
    }
  }
}
