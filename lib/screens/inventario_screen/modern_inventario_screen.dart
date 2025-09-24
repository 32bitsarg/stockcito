import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/categoria.dart';
import '../../models/talla.dart';
import '../../services/datos/datos.dart';
import '../../config/app_theme.dart';
import '../inventario_screen/widgets/editar_producto/editar_producto_screen.dart';
import 'widgets/inventario_header_widget.dart';
import 'widgets/inventario_filters_widget.dart';
import 'widgets/inventario_list_widget.dart';
import 'widgets/gestion_categorias/gestion_categorias_modal.dart';
import 'widgets/gestion_tallas/gestion_tallas_modal.dart';
import 'functions/inventario_functions.dart';
import '../../widgets/connectivity_status_widget.dart';
import '../../widgets/sync_status_widget.dart';
import '../../widgets/lazy_list_widget.dart';

class ModernInventarioScreen extends StatefulWidget {
  const ModernInventarioScreen({super.key});

  @override
  State<ModernInventarioScreen> createState() => _ModernInventarioScreenState();
}

class _ModernInventarioScreenState extends State<ModernInventarioScreen> with WidgetsBindingObserver {
  final DatosService _datosService = DatosService();
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  List<Talla> _tallas = [];
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';
  String _busqueda = '';
  bool _mostrarSoloStockBajo = false;
  bool _cargando = false;


  @override
  void initState() {
    super.initState();
    print('🚀 [MODERN INVENTARIO] initState() llamado');
    try {
      WidgetsBinding.instance.addObserver(this);
      print('✅ [MODERN INVENTARIO] WidgetsBinding observer agregado');
      
      _loadProductos();
      print('✅ [MODERN INVENTARIO] _loadProductos() llamado');
      
      _loadCategorias();
      print('✅ [MODERN INVENTARIO] _loadCategorias() llamado');
      
      _loadTallas();
      print('✅ [MODERN INVENTARIO] _loadTallas() llamado');
      
      _cargarDatosUsuario();
      print('✅ [MODERN INVENTARIO] _cargarDatosUsuario() llamado');
    } catch (e) {
      print('❌ [MODERN INVENTARIO] Error en initState: $e');
      print('❌ [MODERN INVENTARIO] Stack trace: ${StackTrace.current}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar datos cuando la app vuelve a estar activa
      _loadCategorias();
      _loadTallas();
    }
  }

  Future<void> _loadProductos() async {
    setState(() {
      _cargando = true;
    });
    
    try {
      final productos = await _datosService.getProductos();
      setState(() {
        _productos = productos;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      print('Error cargando productos: $e');
    }
  }

  Future<void> _loadCategorias() async {
    try {
      final categorias = await _datosService.getCategorias();
      setState(() {
        _categorias = categorias;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
    }
  }

  Future<void> _loadTallas() async {
    try {
      final tallas = await _datosService.getTallas();
      setState(() {
        _tallas = tallas;
      });
    } catch (e) {
      print('Error cargando tallas: $e');
    }
  }

  /// Carga datos del usuario desde Supabase si está autenticado
  Future<void> _cargarDatosUsuario() async {
    try {
      // DatosService maneja automáticamente la sincronización
      await _datosService.initialize();
    } catch (e) {
      print('Error cargando datos del usuario: $e');
    }
  }

  List<Producto> get _productosFiltrados {
    return InventarioFunctions.filterProductos(
      _productos,
      categoria: _filtroCategoria,
      talla: _filtroTalla,
      busqueda: _busqueda,
      mostrarSoloStockBajo: _mostrarSoloStockBajo,
    );
  }

  /// Obtiene los filtros actuales para el lazy loading
  Map<String, dynamic> _getCurrentFilters() {
    return {
      'categoria': _filtroCategoria,
      'talla': _filtroTalla,
      'busqueda': _busqueda,
      'stockBajo': _mostrarSoloStockBajo,
    };
  }

  /// Construye la tarjeta de producto para el lazy loading
  Widget _buildProductoCard(Producto producto, int index) {
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
          onTap: () => _editarProducto(producto),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de categoría
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.tag,
                    color: InventarioFunctions.getCategoriaColor(producto.categoria),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto
                      Text(
                        producto.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Categoría y talla
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              InventarioFunctions.getCategoriaText(producto.categoria),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: InventarioFunctions.getCategoriaColor(producto.categoria),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Talla: ${InventarioFunctions.getTallaText(producto.talla)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Precio y stock
                      Row(
                        children: [
                          Text(
                            InventarioFunctions.formatPrecio(producto.precioVenta),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: InventarioFunctions.getStockColor(producto.stock).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: InventarioFunctions.getStockColor(producto.stock).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  InventarioFunctions.getStockIcon(producto.stock),
                                  color: InventarioFunctions.getStockColor(producto.stock),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${producto.stock}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: InventarioFunctions.getStockColor(producto.stock),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                      Icons.edit_outlined,
                      AppTheme.primaryColor,
                      () => _editarProducto(producto),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.delete_outline,
                      AppTheme.errorColor,
                      () => _eliminarProducto(producto),
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

  void _abrirGestionCategorias() {
    showDialog(
      context: context,
      builder: (context) => GestionCategoriasModal(
        categorias: _categorias,
        productos: _productos,
        onCategoriasChanged: (nuevasCategorias) {
          setState(() {
            _categorias = nuevasCategorias;
          });
        },
      ),
    );
  }

  void _abrirGestionTallas() {
    showDialog(
      context: context,
      builder: (context) => GestionTallasModal(
        tallas: _tallas,
        productos: _productos,
        onTallasChanged: (nuevasTallas) {
          setState(() {
            _tallas = nuevasTallas;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [MODERN INVENTARIO] build() llamado');
    print('🔍 [MODERN INVENTARIO] _productos.length: ${_productos.length}');
    print('🔍 [MODERN INVENTARIO] _categorias.length: ${_categorias.length}');
    print('🔍 [MODERN INVENTARIO] _tallas.length: ${_tallas.length}');
    print('🔍 [MODERN INVENTARIO] _cargando: $_cargando');
    
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estadísticas
            InventarioHeaderWidget(
              productos: _productosFiltrados,
            ),
            
            // Banner de estado de conectividad y sincronización
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Estado del Sistema:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const ConnectivityStatusWidget(showDetails: true),
                  const SizedBox(width: 16),
                  const SyncStatusWidget(showDetails: true),
                ],
              ),
            ),
            
            // Debug buttons (ocultos - disponibles para debug futuro)
            // Container(
            //   margin: const EdgeInsets.symmetric(vertical: 8),
            //   child: Row(
            //     children: [
            //       ElevatedButton(
            //         onPressed: () async {
            //           print('🔄 Forzando recarga de categorías y tallas...');
            //           await _loadCategorias();
            //           await _loadTallas();
            //         },
            //         child: const Text('🔄 Recargar'),
            //       ),
            //       const SizedBox(width: 8),
            //       ElevatedButton(
            //         onPressed: () async {
            //           print('🗑️ Reseteando base de datos...');
            //           await DebugResetDatabase.resetAndReloadDefaults();
            //           await _loadCategorias();
            //           await _loadTallas();
            //         },
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.red,
            //           foregroundColor: Colors.white,
            //         ),
            //         child: const Text('🗑️ Reset DB'),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 24),
            
            // Filtros
            InventarioFiltersWidget(
              categorias: _categorias,
              tallas: _tallas,
              filtroCategoria: _filtroCategoria,
              filtroTalla: _filtroTalla,
              busqueda: _busqueda,
              mostrarSoloStockBajo: _mostrarSoloStockBajo,
              onCategoriaChanged: (categoria) => setState(() => _filtroCategoria = categoria),
              onTallaChanged: (talla) => setState(() => _filtroTalla = talla),
              onBusquedaChanged: (busqueda) => setState(() => _busqueda = busqueda),
              onStockBajoChanged: (mostrar) => setState(() => _mostrarSoloStockBajo = mostrar),
              onGestionCategorias: _abrirGestionCategorias,
              onGestionTallas: _abrirGestionTallas,
            ),
            const SizedBox(height: 24),
            
            // Lista de productos con lazy loading
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
              child: LazyListWidget<Producto>(
                entityKey: 'productos_inventario',
                pageSize: 20,
                dataLoader: (page, pageSize) => _datosService.getProductosLazy(
                  page: page,
                  limit: pageSize,
                  filters: _getCurrentFilters(),
                ),
                itemBuilder: (producto, index) => _buildProductoCard(producto, index),
                padding: const EdgeInsets.all(16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                filters: _getCurrentFilters(),
                onRefresh: () {
                  // Recargar categorías y tallas también
                  _loadCategorias();
                  _loadTallas();
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  void _eliminarProducto(Producto producto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _datosService.deleteProducto(producto.id!);
                Navigator.of(context).pop();
                _loadProductos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Producto eliminado exitosamente'),
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
                      content: Text('Error eliminando producto: $e'),
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
