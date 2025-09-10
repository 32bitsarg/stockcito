import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../config/app_theme.dart';
import '../widgets/advanced_search_widget.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/ai_recommendations_widget.dart';
import 'modern_calculo_precio_screen.dart';
import 'editar_producto_screen.dart';

class ModernInventarioScreen extends StatefulWidget {
  const ModernInventarioScreen({super.key});

  @override
  State<ModernInventarioScreen> createState() => _ModernInventarioScreenState();
}

class _ModernInventarioScreenState extends State<ModernInventarioScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Producto> _productos = [];
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';
  String _busqueda = '';
  bool _mostrarSoloStockBajo = false;
  

  final List<String> _categorias = [
    'Todas',
    'Bodies',
    'Conjuntos',
    'Vestidos',
    'Pijamas',
    'Gorros',
    'Accesorios',
  ];

  final List<String> _tallas = [
    'Todas',
    '0-3 meses',
    '3-6 meses',
    '6-12 meses',
    '12-18 meses',
    '18-24 meses',
  ];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    final productos = await _databaseService.getAllProductos();
    setState(() {
      _productos = productos;
    });
  }

  List<Producto> get _productosFiltrados {
    var productos = _productos;

    // Filtrar por categoría
    if (_filtroCategoria != 'Todas') {
      productos = productos.where((p) => p.categoria == _filtroCategoria).toList();
    }

    // Filtrar por talla
    if (_filtroTalla != 'Todas') {
      productos = productos.where((p) => p.talla == _filtroTalla).toList();
    }

    // Filtrar por búsqueda
    if (_busqueda.isNotEmpty) {
      productos = productos.where((p) => 
        p.nombre.toLowerCase().contains(_busqueda.toLowerCase()) ||
        p.categoria.toLowerCase().contains(_busqueda.toLowerCase())
      ).toList();
    }

    // Filtrar por stock bajo
    if (_mostrarSoloStockBajo) {
      productos = productos.where((p) => p.stock < 10).toList();
    }

    return productos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estadísticas
            _buildHeader(),
            const SizedBox(height: 24),
            // Filtros
            _buildFiltros(),
            const SizedBox(height: 24),
            // Recomendaciones de IA
            const AIRecommendationsWidget(),
            const SizedBox(height: 24),
            // Lista de productos
            _buildListaProductos(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final productosFiltrados = _productosFiltrados;
    final totalProductos = productosFiltrados.length;
    final stockBajo = productosFiltrados.where((p) => p.stock < 10).length;
    final valorTotal = productosFiltrados.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));

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
                      FontAwesomeIcons.boxesStacked,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Inventario',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestiona tu stock de productos de manera eficiente',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Estadísticas rápidas y botón agregar
          Row(
            children: [
              _buildStatCard('Productos', '$totalProductos', FontAwesomeIcons.boxesStacked),
              const SizedBox(width: 16),
              _buildStatCard('Stock Bajo', '$stockBajo', FontAwesomeIcons.triangleExclamation),
              const SizedBox(width: 16),
              _buildStatCard('Valor Total', '\$${valorTotal.toStringAsFixed(0)}', FontAwesomeIcons.dollarSign),
              const SizedBox(width: 24),
              // Botón agregar producto
              AnimatedButton(
                text: 'Agregar Producto',
                type: ButtonType.primary,
                onPressed: _nuevoProducto,
                icon: FontAwesomeIcons.plus,
                delay: const Duration(milliseconds: 100),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withOpacity(0.8),
            ),
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
                FontAwesomeIcons.filter,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
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
              // Búsqueda avanzada
              Expanded(
                flex: 3,
                child: AnimatedCard(
                  delay: const Duration(milliseconds: 100),
                  child: AdvancedSearchWidget(
                    searchController: TextEditingController(text: _busqueda),
                    onSearchChanged: (value) {
                      setState(() {
                        _busqueda = value;
                      });
                    },
                    onFiltersChanged: (filters) {
                      setState(() {
                        _filtroCategoria = filters['category'] ?? 'Todas';
                        _filtroTalla = filters['size'] ?? 'Todas';
                        _mostrarSoloStockBajo = filters['showOnlyLowStock'] ?? false;
                      });
                    },
                    categories: _categorias.where((c) => c != 'Todas').toList(),
                    sizes: _tallas.where((t) => t != 'Todas').toList(),
                    showStockFilter: true,
                    showPriceFilter: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Filtro categoría
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroCategoria,
                  items: _categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroCategoria = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Categoría',
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
              // Filtro talla
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroTalla,
                  items: _tallas.map((talla) {
                    return DropdownMenuItem(
                      value: talla,
                      child: Text(talla),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroTalla = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Talla',
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
              // Botón agregar producto
              AnimatedButton(
                text: 'Nuevo Producto',
                icon: FontAwesomeIcons.plus,
                delay: const Duration(milliseconds: 200),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ModernCalculoPrecioScreen(),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filtros adicionales
          Row(
            children: [
              // Checkbox stock bajo
              Row(
                children: [
                  Checkbox(
                    value: _mostrarSoloStockBajo,
                    onChanged: (value) {
                      setState(() {
                        _mostrarSoloStockBajo = value!;
                      });
                    },
                    activeColor: AppTheme.warningColor,
                  ),
                  Text(
                    'Solo stock bajo (< 10)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Botón limpiar filtros
              AnimatedButton(
                text: 'Limpiar Filtros',
                type: ButtonType.secondary,
                onPressed: () {
                  setState(() {
                    _filtroCategoria = 'Todas';
                    _filtroTalla = 'Todas';
                    _busqueda = '';
                    _mostrarSoloStockBajo = false;
                  });
                },
                icon: FontAwesomeIcons.trashCan,
                delay: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    final productos = _productosFiltrados;

    if (productos.isEmpty) {
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
                  FontAwesomeIcons.list,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos (${productos.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de productos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return AnimatedListTile(
                title: producto.nombre,
                subtitle: '${producto.categoria} - ${producto.talla}',
                icon: _getCategoryIcon(producto.categoria),
                delay: Duration(milliseconds: 100 + (index * 100)),
                onTap: () => _editarProducto(producto),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'bodies':
        return FontAwesomeIcons.shirt;
      case 'conjuntos':
        return FontAwesomeIcons.baby;
      case 'vestidos':
        return FontAwesomeIcons.star;
      case 'pantalones':
        return FontAwesomeIcons.shirt;
      case 'accesorios':
        return FontAwesomeIcons.hatCowboy;
      default:
        return FontAwesomeIcons.tag;
    }
  }

  Widget _buildProductoCard(Producto producto) {
    final isStockBajo = producto.stock < 10;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStockBajo ? AppTheme.warningColor.withOpacity(0.3) : AppTheme.borderColor,
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
          // Icono del producto
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCategoriaColor(producto.categoria).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoriaIcon(producto.categoria),
              color: _getCategoriaColor(producto.categoria),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(producto.categoria, FontAwesomeIcons.tag),
                    const SizedBox(width: 8),
                    _buildInfoChip(producto.talla, FontAwesomeIcons.ruler),
                    if (isStockBajo) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip('Stock Bajo', FontAwesomeIcons.triangleExclamation, AppTheme.warningColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Precios y stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${producto.precioVenta.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    FontAwesomeIcons.boxesStacked,
                    size: 16,
                    color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${producto.stock} unidades',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                      fontWeight: isStockBajo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Botones de acción
          Row(
            children: [
              AnimatedButton(
                text: 'Editar',
                type: ButtonType.secondary,
                onPressed: () => _editarProducto(producto),
                icon: FontAwesomeIcons.penToSquare,
                delay: const Duration(milliseconds: 100),
              ),
              const SizedBox(width: 8),
              AnimatedButton(
                text: 'Stock',
                type: ButtonType.primary,
                onPressed: () => _agregarStock(producto),
                icon: FontAwesomeIcons.boxOpen,
                delay: const Duration(milliseconds: 200),
              ),
              const SizedBox(width: 8),
              AnimatedButton(
                text: 'Eliminar',
                type: ButtonType.danger,
                onPressed: () => _eliminarProducto(producto),
                icon: FontAwesomeIcons.trash,
                delay: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryColor,
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
            FontAwesomeIcons.boxesStacked,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer producto para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedButton(
            text: 'Agregar Producto',
            type: ButtonType.primary,
            onPressed: _nuevoProducto,
            icon: FontAwesomeIcons.plus,
            delay: const Duration(milliseconds: 100),
          ),
        ],
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Bodies':
        return AppTheme.primaryColor;
      case 'Conjuntos':
        return AppTheme.secondaryColor;
      case 'Vestidos':
        return AppTheme.accentColor;
      case 'Pijamas':
        return AppTheme.warningColor;
      case 'Gorros':
        return AppTheme.successColor;
      case 'Accesorios':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Bodies':
        return FontAwesomeIcons.baby;
      case 'Conjuntos':
        return FontAwesomeIcons.shirt;
      case 'Vestidos':
        return FontAwesomeIcons.shirt;
      case 'Pijamas':
        return FontAwesomeIcons.moon;
      case 'Gorros':
        return FontAwesomeIcons.hatCowboy;
      case 'Accesorios':
        return FontAwesomeIcons.star;
      default:
        return FontAwesomeIcons.boxesStacked;
    }
  }

  void _editarProducto(Producto producto) {
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
            child: EditarProductoScreen(
              producto: producto,
              showCloseButton: true,
            ),
          ),
        ),
      ),
    ).then((_) {
      // Recargar productos cuando regrese
      _loadProductos();
    });
  }

  void _agregarStock(Producto producto) {
    final cantidadController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              FontAwesomeIcons.boxOpen,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text('Agregar Stock'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Producto: ${producto.nombre}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock actual: ${producto.stock} unidades',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cantidad a agregar',
                hintText: 'Ej: 10',
                prefixIcon: Icon(FontAwesomeIcons.plus, color: AppTheme.primaryColor),
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
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () => Navigator.of(context).pop(),
            icon: FontAwesomeIcons.xmark,
            delay: const Duration(milliseconds: 100),
          ),
          const SizedBox(width: 8),
          AnimatedButton(
            text: 'Agregar',
            type: ButtonType.primary,
            onPressed: () async {
              final cantidad = int.tryParse(cantidadController.text);
              if (cantidad == null || cantidad <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Ingresa una cantidad válida'),
                    backgroundColor: AppTheme.errorColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
                return;
              }
              
              try {
                await _databaseService.updateStockProducto(
                  producto.id!,
                  producto.stock + cantidad,
                );
                
                await _loadProductos();
                context.read<DashboardService>().actualizarDatos();
                
                // Verificar si el stock sigue bajo después de la actualización
                final nuevoStock = producto.stock + cantidad;
                if (nuevoStock < 10) {
                  await NotificationService().showStockLowAlert(
                    producto.nombre,
                    nuevoStock,
                  );
                }
                
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Stock actualizado: +$cantidad unidades'),
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
                      content: Text('Error al actualizar stock: $e'),
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
            icon: FontAwesomeIcons.plus,
          ),
        ],
      ),
    );
  }

  void _nuevoProducto() {
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
            child: const ModernCalculoPrecioScreen(showCloseButton: true),
          ),
        ),
      ),
    ).then((_) {
      // Recargar productos cuando regrese
      _loadProductos();
    });
  }

  void _eliminarProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${producto.nombre}"?'),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () => Navigator.of(context).pop(),
            delay: const Duration(milliseconds: 100),
          ),
          const SizedBox(width: 8),
          AnimatedButton(
            text: 'Eliminar',
            type: ButtonType.danger,
            onPressed: () async {
              await _databaseService.deleteProducto(producto.id!);
              await _loadProductos();
              if (mounted) {
                Navigator.of(context).pop();
                context.read<DashboardService>().actualizarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${producto.nombre} eliminado'),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
