import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/datos/datos.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../screens/ventas_screen/widgets/nueva_venta/nueva_venta_screen.dart';
import '../../widgets/lazy_list_widget.dart';
import 'widgets/ventas_header_widget.dart';
import 'widgets/ventas_filters_widget.dart';
import 'widgets/ventas_metrics_widget.dart';
import 'widgets/ventas_detail_modal.dart';
import 'widgets/ventas_edit_modal.dart';
import 'functions/ventas_functions.dart';

class ModernVentasScreen extends StatefulWidget {
  const ModernVentasScreen({super.key});

  @override
  State<ModernVentasScreen> createState() => _ModernVentasScreenState();
}

class _ModernVentasScreenState extends State<ModernVentasScreen> {
  final DatosService _datosService = DatosService();
  
  List<Venta> _ventas = []; // Mantenido para métricas
  List<Cliente> _clientes = [];
  
  // Filtros
  String _filtroEstado = 'Todas';
  String _filtroCliente = 'Todos';
  String _filtroMetodoPago = 'Todos';
  
  // Listas para filtros
  final List<String> _estados = ['Todas', 'Pendiente', 'Completada', 'Cancelada'];
  final List<String> _metodosPago = ['Todos', 'Efectivo', 'Tarjeta', 'Transferencia'];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Cargar solo datos necesarios para métricas y filtros
      final ventas = await _datosService.getVentas();
      final clientes = await _datosService.getClientes();
      
      setState(() {
        _ventas = ventas;
        _clientes = clientes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// Obtiene los filtros actuales para el lazy loading
  Map<String, dynamic> _getCurrentFilters() {
    return {
      'estado': _filtroEstado,
      'cliente': _filtroCliente,
      'metodoPago': _filtroMetodoPago,
    };
  }

  /// Construye la tarjeta de venta para el lazy loading
  Widget _buildVentaCard(Venta venta, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _verDetalleVenta(venta),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de estado
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    VentasFunctions.getEstadoIcon(venta.estado),
                    color: VentasFunctions.getEstadoColor(venta.estado),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Información de la venta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cliente y fecha
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              venta.cliente,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            VentasFunctions.formatFecha(venta.fecha),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Estado y método de pago
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: VentasFunctions.getEstadoColor(venta.estado).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              venta.estado,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: VentasFunctions.getEstadoColor(venta.estado),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            venta.metodoPago,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Total y productos
                      Row(
                        children: [
                          Text(
                            VentasFunctions.formatPrecio(venta.total),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${venta.items.length} producto${venta.items.length != 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      context,
                      Icons.visibility_outlined,
                      AppTheme.infoColor,
                      () => _verDetalleVenta(venta),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.edit_outlined,
                      AppTheme.primaryColor,
                      () => _editarVenta(venta),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.delete_outline,
                      AppTheme.errorColor,
                      () => _eliminarVenta(venta),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye botón de acción
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la pantalla
          VentasHeaderWidget(
            onNuevaVenta: _nuevaVenta,
          ),
          const SizedBox(height: 24),
          
          // Filtros
          VentasFiltersWidget(
            estados: _estados,
            metodosPago: _metodosPago,
            clientes: _clientes,
            filtroEstado: _filtroEstado,
            filtroCliente: _filtroCliente,
            filtroMetodoPago: _filtroMetodoPago,
            onEstadoChanged: (estado) => setState(() => _filtroEstado = estado),
            onClienteChanged: (cliente) => setState(() => _filtroCliente = cliente),
            onMetodoPagoChanged: (metodo) => setState(() => _filtroMetodoPago = metodo),
          ),
          const SizedBox(height: 24),
          
          // Métricas
          VentasMetricsWidget(
            ventas: _ventas,
            ventasFiltradas: _getVentasFiltradas(),
          ),
          const SizedBox(height: 24),
          
          // Lista de ventas con lazy loading
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LazyListWidget<Venta>(
              entityKey: 'ventas_ventas',
              pageSize: 20,
              dataLoader: (page, pageSize) => _datosService.getVentasLazy(
                page: page,
                limit: pageSize,
                filters: _getCurrentFilters(),
              ),
              itemBuilder: (venta, index) => _buildVentaCard(venta, index),
              padding: const EdgeInsets.all(16),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              filters: _getCurrentFilters(),
              onRefresh: () {
                // Recargar datos de métricas
                _loadData();
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Venta> _getVentasFiltradas() {
    return VentasFunctions.filterVentas(
      _ventas,
      estado: _filtroEstado,
      cliente: _filtroCliente,
      metodoPago: _filtroMetodoPago,
    );
  }

  void _nuevaVenta() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
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
            child: NuevaVentaScreen(),
          ),
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese de la nueva venta
      _loadData();
    });
  }


  void _verDetalleVenta(Venta venta) {
    VentasDetailModal.show(context, venta, onEditar: _editarVenta);
  }

  void _editarVenta(Venta venta) {
    VentasEditModal.show(context, venta).then((_) {
      // Recargar datos cuando regrese de editar venta
      _loadData();
    });
  }

  void _eliminarVenta(Venta venta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: Text('¿Estás seguro de que quieres eliminar la venta #${venta.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _datosService.deleteVenta(venta.id!);
                Navigator.of(context).pop();
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Venta eliminada exitosamente'),
                      backgroundColor: AppTheme.successColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error eliminando venta: $e'),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
