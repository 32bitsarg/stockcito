import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/venta.dart';
import '../models/cliente.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../services/dashboard_service.dart';
import '../services/error_handler_service.dart';
import '../services/logging_service.dart';
import '../services/notification_service.dart';
import '../config/app_theme.dart';
import '../widgets/windows_button.dart';

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final DatabaseService _databaseService = DatabaseService();
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
  
  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];
  final List<String> _estados = ['Pendiente', 'Completada', 'Cancelada'];

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
      final productos = await _databaseService.getAllProductos();
      final clientes = await _databaseService.getAllClientes();
      
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
          : Column(
              children: [
                // Header con botón cerrar
                _buildHeaderWithClose(),
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
                                  _buildClienteSectionCompact(),
                                  const SizedBox(height: 16),
                                  // Productos disponibles (compacta)
                                  _buildProductosSectionCompact(),
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
                                  _buildItemsVentaSection(),
                                  const SizedBox(height: 16),
                                  // Resumen y total
                                  _buildResumenSection(),
                                  const SizedBox(height: 16),
                                  // Botones de acción
                                  _buildBotonesAccion(),
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

  Widget _buildHeaderWithClose() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.cartPlus,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nueva Venta',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra una nueva venta en tu sistema',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botón cerrar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                FontAwesomeIcons.xmark,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método _buildHeader removido - ahora usamos _buildHeaderWithClose

  Widget _buildClienteSectionCompact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.user,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cliente (Opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Selector de cliente compacto
          DropdownButtonFormField<Cliente?>(
            value: _clienteSeleccionado,
            items: [
              const DropdownMenuItem<Cliente?>(
                value: null,
                child: Text('Cliente existente'),
              ),
              ..._clientes.map((cliente) {
                return DropdownMenuItem<Cliente?>(
                  value: cliente,
                  child: Text('${cliente.nombre} - ${cliente.telefono}'),
                );
              }).toList(),
            ],
            onChanged: (cliente) {
              setState(() {
                _clienteSeleccionado = cliente;
                if (cliente != null) {
                  _clienteController.text = cliente.nombre;
                  _telefonoController.text = cliente.telefono;
                  _emailController.text = cliente.email;
                  _direccionController.text = cliente.direccion;
                } else {
                  _clienteController.clear();
                  _telefonoController.clear();
                  _emailController.clear();
                  _direccionController.clear();
                }
              });
            },
            decoration: InputDecoration(
              labelText: 'Seleccionar cliente',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              prefixIcon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          // Campos compactos en una fila
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _clienteController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    prefixIcon: const FaIcon(FontAwesomeIcons.user, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _telefonoController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    prefixIcon: const FaIcon(FontAwesomeIcons.phone, size: 18),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildProductosSectionCompact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.boxesStacked,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Productos Disponibles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de productos compacta
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final producto = _productos[index];
                return _buildProductoCardCompact(producto);
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildProductoCardCompact(Producto producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Información del producto compacta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildInfoChipCompact(producto.categoria),
                    const SizedBox(width: 4),
                    _buildInfoChipCompact(producto.talla),
                    const SizedBox(width: 4),
                    _buildInfoChipCompact('Stock: ${producto.stock}'),
                  ],
                ),
              ],
            ),
          ),
          // Precio y botón agregar compactos
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${producto.precioVenta.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _agregarProducto(producto),
                  icon: const Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildInfoChipCompact(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }


  Widget _buildItemsVentaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.cartShopping,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Items de la Venta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_itemsVenta.isEmpty)
            _buildEmptyItemsState()
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _itemsVenta.length,
                itemBuilder: (context, index) {
                  final item = _itemsVenta[index];
                  return _buildItemVentaCardCompact(item, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.cartShopping,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos agregados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona productos de la lista superior',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemVentaCardCompact(VentaItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Información del item compacta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombreProducto,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildInfoChipCompact(item.categoria),
                    const SizedBox(width: 4),
                    _buildInfoChipCompact(item.talla),
                  ],
                ),
              ],
            ),
          ),
          // Cantidad y controles compactos
          Row(
            children: [
              // Cantidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${item.cantidad}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Botones de cantidad compactos
              Row(
                children: [
                  IconButton(
                    onPressed: () => _decrementarCantidad(index),
                    icon: const FaIcon(FontAwesomeIcons.minus, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                      foregroundColor: AppTheme.errorColor,
                      minimumSize: const Size(24, 24),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _incrementarCantidad(index),
                    icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.successColor.withOpacity(0.1),
                      foregroundColor: AppTheme.successColor,
                      minimumSize: const Size(24, 24),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // Subtotal
              Text(
                '\$${item.subtotal.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              // Botón eliminar compacto
              IconButton(
                onPressed: () => _eliminarItem(index),
                icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                  foregroundColor: AppTheme.errorColor,
                  minimumSize: const Size(24, 24),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildResumenSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.receipt,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de la Venta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Método de pago
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _metodoPago,
                  items: _metodosPago.map((metodo) {
                    return DropdownMenuItem(
                      value: metodo,
                      child: Text(metodo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _metodoPago = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _estado,
                  items: _estados.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _estado = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${_totalVenta.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: WindowsButton(
            text: 'Limpiar',
            type: ButtonType.secondary,
            onPressed: _limpiarFormulario,
            icon: FontAwesomeIcons.trashCan,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: WindowsButton(
            text: 'Guardar Venta',
            type: ButtonType.primary,
            onPressed: _guardarVenta,
            icon: FontAwesomeIcons.floppyDisk,
          ),
        ),
      ],
    );
  }

  void _agregarProducto(Producto producto) {
    if (producto.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay stock disponible para ${producto.nombre}'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    // Verificar si el producto ya está en la venta
    final existingIndex = _itemsVenta.indexWhere((item) => item.productoId == producto.id);
    
    if (existingIndex != -1) {
      // Incrementar cantidad si ya existe
      _incrementarCantidad(existingIndex);
    } else {
      // Agregar nuevo item
      final nuevoItem = VentaItem(
        ventaId: 0, // Se asignará al guardar
        productoId: producto.id!,
        nombreProducto: producto.nombre,
        categoria: producto.categoria,
        talla: producto.talla,
        cantidad: 1,
        precioUnitario: producto.precioVenta,
        subtotal: producto.precioVenta,
      );
      
      setState(() {
        _itemsVenta.add(nuevoItem);
        _calcularTotal();
      });
    }
  }

  void _incrementarCantidad(int index) {
    final item = _itemsVenta[index];
    final producto = _productos.firstWhere((p) => p.id == item.productoId);
    
    if (item.cantidad < producto.stock) {
      setState(() {
        _itemsVenta[index] = VentaItem(
          id: item.id,
          ventaId: item.ventaId,
          productoId: item.productoId,
          nombreProducto: item.nombreProducto,
          categoria: item.categoria,
          talla: item.talla,
          cantidad: item.cantidad + 1,
          precioUnitario: item.precioUnitario,
          subtotal: (item.cantidad + 1) * item.precioUnitario,
        );
        _calcularTotal();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay suficiente stock para ${item.nombreProducto}'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _decrementarCantidad(int index) {
    if (_itemsVenta[index].cantidad > 1) {
      setState(() {
        final item = _itemsVenta[index];
        _itemsVenta[index] = VentaItem(
          id: item.id,
          ventaId: item.ventaId,
          productoId: item.productoId,
          nombreProducto: item.nombreProducto,
          categoria: item.categoria,
          talla: item.talla,
          cantidad: item.cantidad - 1,
          precioUnitario: item.precioUnitario,
          subtotal: (item.cantidad - 1) * item.precioUnitario,
        );
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

  void _calcularTotal() {
    _totalVenta = _itemsVenta.fold(0.0, (sum, item) => sum + item.subtotal);
  }


  void _limpiarFormulario() {
    setState(() {
      _clienteSeleccionado = null;
      _clienteController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _direccionController.clear();
      _notasController.clear();
      _metodoPago = 'Efectivo';
      _estado = 'Pendiente';
      _itemsVenta.clear();
      _totalVenta = 0.0;
    });
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) {
      LoggingService.ui('Validación de formulario falló', screen: 'NuevaVenta');
      return;
    }

    if (_itemsVenta.isEmpty) {
      ErrorHandlerService.handleError(
        context,
        'Debe agregar al menos un producto a la venta',
        customMessage: 'Debe agregar al menos un producto a la venta',
      );
      return;
    }

    // Mostrar indicador de carga
    ErrorHandlerService.showLoadingDialog(context, 'Guardando venta...');

    try {
      LoggingService.business('Iniciando guardado de venta', entity: 'Venta');
      
      final venta = Venta(
        cliente: _clienteController.text.isNotEmpty ? _clienteController.text : 'Cliente no especificado',
        telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : '',
        email: _emailController.text.isNotEmpty ? _emailController.text : '',
        fecha: DateTime.now(),
        total: _totalVenta,
        metodoPago: _metodoPago,
        estado: _estado,
        notas: _notasController.text.isNotEmpty ? _notasController.text : '',
        items: _itemsVenta,
      );

      await _databaseService.insertVenta(venta);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Venta guardada exitosamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
        customMessage: 'Error al guardar la venta. Inténtalo de nuevo.',
        onRetry: _guardarVenta,
      );
    }
  }
}
