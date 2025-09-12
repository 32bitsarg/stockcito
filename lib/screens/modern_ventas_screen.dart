import 'package:flutter/material.dart';
import '../models/venta.dart';
import '../models/cliente.dart';
import '../models/producto.dart';
import '../services/datos/datos.dart';
import '../config/app_theme.dart';
import '../widgets/animated_widgets.dart';
import 'nueva_venta_screen.dart';

class ModernVentasScreen extends StatefulWidget {
  const ModernVentasScreen({super.key});

  @override
  State<ModernVentasScreen> createState() => _ModernVentasScreenState();
}

class _ModernVentasScreenState extends State<ModernVentasScreen> {
  final DatosService _datosService = DatosService();
  List<Venta> _ventas = [];
  List<Cliente> _clientes = [];
  List<Producto> _productos = [];
  bool _isLoading = true;
  String _filtroEstado = 'Todas';
  String _filtroCliente = 'Todos';
  String _filtroMetodoPago = 'Todos';

  final List<String> _estados = ['Todas', 'Pendiente', 'Completada', 'Cancelada'];
  final List<String> _metodosPago = ['Todos', 'Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final ventas = await _datosService.getVentas();
      final clientes = await _datosService.getClientes();
      final productos = await _datosService.getProductos();
      
      setState(() {
        _ventas = ventas;
        _clientes = clientes;
        _productos = productos;
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

  List<Venta> get _ventasFiltradas {
    var ventas = _ventas;

    if (_filtroEstado != 'Todas') {
      ventas = ventas.where((v) => v.estado == _filtroEstado).toList();
    }

    if (_filtroCliente != 'Todos') {
      ventas = ventas.where((v) => v.cliente == _filtroCliente).toList();
    }

    if (_filtroMetodoPago != 'Todos') {
      ventas = ventas.where((v) => v.metodoPago == _filtroMetodoPago).toList();
    }

    return ventas;
  }

  double get _totalVentas {
    return _ventasFiltradas.fold(0.0, (sum, venta) => sum + venta.total);
  }

  int get _totalVentasCount {
    return _ventasFiltradas.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // Filtros
                  _buildFiltros(),
                  const SizedBox(height: 24),
                  // Métricas principales
                  _buildMetricasPrincipales(),
                  const SizedBox(height: 24),
                  // Lista de ventas
                  _buildListaVentas(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Gestión de Ventas',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra las ventas y transacciones de tu negocio',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botón nueva venta
          AnimatedButton(
            text: 'Nueva Venta',
            type: ButtonType.primary,
            onPressed: _nuevaVenta,
            icon: Icons.add,
            delay: const Duration(milliseconds: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros de Ventas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Filtro estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado,
                  items: _estados.map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Filtro cliente
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroCliente,
                  items: ['Todos', ..._clientes.map((c) => c.nombre)].map((cliente) {
                    return DropdownMenuItem(
                      value: cliente,
                      child: Text(cliente),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroCliente = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Filtro método de pago
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroMetodoPago,
                  items: _metodosPago.map((metodo) {
                    return DropdownMenuItem(
                      value: metodo,
                      child: Text(metodo),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroMetodoPago = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Método de Pago',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Botón limpiar filtros
              AnimatedButton(
                text: 'Limpiar',
                type: ButtonType.secondary,
                onPressed: () {
                  setState(() {
                    _filtroEstado = 'Todas';
                    _filtroCliente = 'Todos';
                    _filtroMetodoPago = 'Todos';
                  });
                },
                delay: const Duration(milliseconds: 200),
                icon: Icons.clear_all,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasPrincipales() {
    return Row(
      children: [
        Expanded(
          child: AnimatedCard(
            delay: const Duration(milliseconds: 100),
            child: _buildMetricaCard(
              'Total Ventas',
              '$_totalVentasCount',
              Icons.shopping_cart,
              AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedCard(
            delay: const Duration(milliseconds: 200),
            child: _buildMetricaCard(
              'Ingresos Totales',
              '\$${_totalVentas.toStringAsFixed(0)}',
              Icons.attach_money,
              AppTheme.successColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedCard(
            delay: const Duration(milliseconds: 300),
            child: _buildMetricaCard(
              'Clientes',
              '${_clientes.length}',
              Icons.people,
              AppTheme.accentColor,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedCard(
            delay: const Duration(milliseconds: 400),
            child: _buildMetricaCard(
              'Productos',
              '${_productos.length}',
              Icons.inventory,
              AppTheme.warningColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildListaVentas() {
    final ventas = _ventasFiltradas;

    if (ventas.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ventas Registradas (${ventas.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de ventas
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ventas.length,
            itemBuilder: (context, index) {
              final venta = ventas[index];
              return AnimatedCard(
                delay: Duration(milliseconds: 100 * (index + 1)),
                child: _buildVentaCard(venta, index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVentaCard(Venta venta, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEstadoColor(venta.estado).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del estado
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getEstadoColor(venta.estado).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getEstadoIcon(venta.estado),
              color: _getEstadoColor(venta.estado),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información de la venta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venta.cliente,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(venta.estado, _getEstadoIcon(venta.estado), _getEstadoColor(venta.estado)),
                    const SizedBox(width: 8),
                    _buildInfoChip(venta.metodoPago, Icons.payment, AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    _buildInfoChip('${venta.items.length} items', Icons.shopping_bag, AppTheme.textSecondary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${venta.fecha.day}/${venta.fecha.month}/${venta.fecha.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Total y acciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${venta.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  AnimatedButton(
                    text: 'Ver',
                    type: ButtonType.secondary,
                    onPressed: () => _verVenta(venta),
                    icon: Icons.visibility,
                    delay: Duration(milliseconds: 100 * (index + 1)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedButton(
                    text: 'Editar',
                    type: ButtonType.secondary,
                    onPressed: () => _editarVenta(venta),
                    icon: Icons.edit,
                    delay: Duration(milliseconds: 100 * (index + 1) + 50),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
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
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay ventas registradas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comienza registrando tu primera venta',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            text: 'Nueva Venta',
            type: ButtonType.primary,
            onPressed: _nuevaVenta,
            icon: Icons.add,
            delay: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Completada':
        return AppTheme.successColor;
      case 'Pendiente':
        return AppTheme.warningColor;
      case 'Cancelada':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Completada':
        return Icons.check_circle;
      case 'Pendiente':
        return Icons.pending;
      case 'Cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
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
            child: const NuevaVentaScreen(),
          ),
        ),
      ),
    ).then((_) {
      // Recargar datos cuando regrese de la nueva venta
      _loadData();
    });
  }

  void _verVenta(Venta venta) {
    // TODO: Implementar vista de detalle de venta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcionalidad de ver venta en desarrollo'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _editarVenta(Venta venta) {
    // TODO: Implementar edición de venta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcionalidad de editar venta en desarrollo'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
