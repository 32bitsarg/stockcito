import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/datos/datos.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../screens/ventas_screen/widgets/nueva_venta/nueva_venta_screen.dart';
import 'widgets/ventas_header_widget.dart';
import 'widgets/ventas_filters_widget.dart';
import 'widgets/ventas_metrics_widget.dart';
import 'widgets/ventas_list_widget.dart';
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
  
  List<Venta> _ventas = [];
  List<Cliente> _clientes = [];
  bool _isLoading = true;
  
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
    setState(() {
      _isLoading = true;
    });

    try {
      final ventas = await _datosService.getVentas();
      final clientes = await _datosService.getClientes();
      
      setState(() {
        _ventas = ventas;
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
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
          
          // Lista de ventas
          VentasListWidget(
            ventas: _getVentasFiltradas(),
            onVerVenta: _verVenta,
            onEditarVenta: _editarVenta,
            onEliminarVenta: _eliminarVenta,
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

  void _verVenta(Venta venta) {
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
