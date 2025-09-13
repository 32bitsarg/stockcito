import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/venta.dart';
import '../../../../models/cliente.dart';
import '../../../../models/producto.dart';
import '../../../../services/datos/datos.dart';
import '../../../../services/datos/dashboard_service.dart';
import '../../../../services/system/error_handler_service.dart';
import '../../../../services/system/logging_service.dart';
import '../../../../services/notifications/notification_service.dart';

// Importar widgets refactorizados
import 'nueva_venta_header.dart';
import 'nueva_venta_cliente_section.dart';
import 'nueva_venta_productos_section.dart';
import 'nueva_venta_items_section.dart';
import 'nueva_venta_resumen_section.dart';

// Importar funciones
import '../../functions/nueva_venta_functions.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final DatosService _datosService = DatosService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores del formulario
  final _clienteController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _notasController = TextEditingController();
  
  // Variables de estado
  String _metodoPago = 'Efectivo';
  String _estado = 'Pendiente';
  List<VentaItem> _itemsVenta = [];
  List<Producto> _productos = [];
  List<Cliente> _clientes = [];
  Cliente? _clienteSeleccionado;
  bool _isLoading = true;
  double _totalVenta = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final productos = await _datosService.getAllProductos();
      final clientes = await _datosService.getAllClientes();
      
      setState(() {
        _productos = productos;
        _clientes = clientes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        NuevaVentaFunctions.showErrorSnackBar(
          context, 
          NuevaVentaFunctions.getCargaDatosErrorText(e.toString())
        );
      }
    }
  }

  void _calcularTotal() {
    setState(() {
      _totalVenta = NuevaVentaFunctions.calcularTotalVenta(_itemsVenta);
    });
  }

  void _agregarProducto(Producto producto) {
    if (!NuevaVentaFunctions.tieneStockDisponible(producto)) {
      NuevaVentaFunctions.showWarningSnackBar(
        context, 
        NuevaVentaFunctions.getStockNoDisponibleText(producto.nombre)
      );
      return;
    }

    // Verificar si el producto ya está en la venta
    final existingIndex = NuevaVentaFunctions.buscarItemExistente(_itemsVenta, producto.id!);
    
    if (existingIndex != -1) {
      // Incrementar cantidad si ya existe
      _incrementarCantidad(existingIndex);
    } else {
      // Agregar nuevo item
      final nuevoItem = NuevaVentaFunctions.crearItemVenta(producto);
      
      setState(() {
        _itemsVenta.add(nuevoItem);
        _calcularTotal();
      });
    }
  }

  void _incrementarCantidad(int index) {
    final item = _itemsVenta[index];
    final producto = _productos.firstWhere((p) => p.id == item.productoId);
    
    if (NuevaVentaFunctions.puedeIncrementarCantidad(item, producto)) {
      setState(() {
        _itemsVenta[index] = NuevaVentaFunctions.incrementarCantidadItem(item);
        _calcularTotal();
      });
    } else {
      NuevaVentaFunctions.showWarningSnackBar(
        context, 
        NuevaVentaFunctions.getStockInsuficienteText(item.nombreProducto)
      );
    }
  }

  void _decrementarCantidad(int index) {
    if (NuevaVentaFunctions.puedeDecrementarCantidad(_itemsVenta[index])) {
      setState(() {
        _itemsVenta[index] = NuevaVentaFunctions.decrementarCantidadItem(_itemsVenta[index]);
        _calcularTotal();
      });
    } else {
      _eliminarItem(index);
    }
  }

  void _eliminarItem(int index) {
    setState(() {
      _itemsVenta.removeAt(index);
      _calcularTotal();
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _clienteSeleccionado = null;
      NuevaVentaFunctions.limpiarDatosCliente(
        clienteController: _clienteController,
        telefonoController: _telefonoController,
        emailController: _emailController,
        direccionController: _direccionController,
      );
      _notasController.clear();
      _metodoPago = 'Efectivo';
      _estado = 'Pendiente';
      _itemsVenta.clear();
      _totalVenta = 0.0;
    });
  }

  Future<void> _guardarVenta() async {
    if (!NuevaVentaFunctions.validarFormulario(_formKey, _itemsVenta)) {
      LoggingService.ui('Validación de formulario falló', screen: 'NuevaVenta');
      return;
    }

    if (_itemsVenta.isEmpty) {
      ErrorHandlerService.handleError(
        context,
        NuevaVentaFunctions.getItemsVaciosText(),
        customMessage: NuevaVentaFunctions.getItemsVaciosText(),
      );
      return;
    }

    // Mostrar indicador de carga
    ErrorHandlerService.showLoadingDialog(context, 'Guardando venta...');

    try {
      LoggingService.business('Iniciando guardado de venta', entity: 'Venta');
      
      final venta = NuevaVentaFunctions.crearVenta(
        cliente: _clienteController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        total: _totalVenta,
        metodoPago: _metodoPago,
        estado: _estado,
        notas: _notasController.text,
        items: _itemsVenta,
      );

      await _datosService.insertVenta(venta);
      LoggingService.business('Venta guardada exitosamente', entity: 'Venta');
      
      // Actualizar dashboard
      if (mounted) {
        context.read<DashboardService>().actualizarDatos();
      }

      // Mostrar notificación de venta
      await NotificationService().showSaleAlert(
        venta.cliente,
        venta.total,
      );

      // Cerrar diálogo de carga
      ErrorHandlerService.hideLoadingDialog(context);

      if (mounted) {
        NuevaVentaFunctions.showSuccessSnackBar(
          context, 
          NuevaVentaFunctions.getVentaGuardadaSuccessText()
        );
        
        // Cerrar el modal y limpiar formulario
        Navigator.of(context).pop();
        _limpiarFormulario();
      }
    } catch (e, stackTrace) {
      // Cerrar diálogo de carga
      if (mounted) {
        ErrorHandlerService.hideLoadingDialog(context);
      }
      
      LoggingService.error(
        'Error al guardar venta',
        tag: 'VENTA',
        error: e,
        stackTrace: stackTrace,
      );
      
      ErrorHandlerService.handleError(
        context,
        e,
        customMessage: NuevaVentaFunctions.getVentaGuardadaErrorText(),
        onRetry: _guardarVenta,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con botón cerrar
                NuevaVentaHeader(onCerrar: () => Navigator.of(context).pop()),
                // Contenido principal con layout horizontal
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Columna izquierda - Cliente y Productos
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Información del cliente (compacta)
                                  NuevaVentaClienteSection(
                                    clienteSeleccionado: _clienteSeleccionado,
                                    clientes: _clientes,
                                    clienteController: _clienteController,
                                    telefonoController: _telefonoController,
                                    emailController: _emailController,
                                    direccionController: _direccionController,
                                    onClienteChanged: (cliente) {
                                      setState(() {
                                        _clienteSeleccionado = cliente;
                                        if (cliente != null) {
                                          NuevaVentaFunctions.cargarDatosCliente(
                                            cliente: cliente,
                                            clienteController: _clienteController,
                                            telefonoController: _telefonoController,
                                            emailController: _emailController,
                                            direccionController: _direccionController,
                                          );
                                        } else {
                                          NuevaVentaFunctions.limpiarDatosCliente(
                                            clienteController: _clienteController,
                                            telefonoController: _telefonoController,
                                            emailController: _emailController,
                                            direccionController: _direccionController,
                                          );
                                        }
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // Productos disponibles (compacta)
                                  NuevaVentaProductosSection(
                                    productos: _productos,
                                    onAgregarProducto: _agregarProducto,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Columna derecha - Items de venta y resumen
                          Expanded(
                            flex: 2,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // Items de la venta
                                  NuevaVentaItemsSection(
                                    itemsVenta: _itemsVenta,
                                    onIncrementarCantidad: _incrementarCantidad,
                                    onDecrementarCantidad: _decrementarCantidad,
                                    onEliminarItem: _eliminarItem,
                                  ),
                                  const SizedBox(height: 16),
                                  // Resumen y total
                                  NuevaVentaResumenSection(
                                    metodoPago: _metodoPago,
                                    estado: _estado,
                                    notasController: _notasController,
                                    totalVenta: _totalVenta,
                                    onMetodoPagoChanged: (metodo) => setState(() => _metodoPago = metodo),
                                    onEstadoChanged: (estado) => setState(() => _estado = estado),
                                    onLimpiarFormulario: _limpiarFormulario,
                                    onGuardarVenta: _guardarVenta,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
