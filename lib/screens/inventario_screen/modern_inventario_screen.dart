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
            
            // Lista de productos
            InventarioListWidget(
              productos: _productosFiltrados,
              cargando: _cargando,
              onEditarProducto: _editarProducto,
              onEliminarProducto: _eliminarProducto,
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
