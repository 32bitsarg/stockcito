import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import 'inventario_state_service.dart';
import '../../../screens/inventario_screen/functions/inventario_functions.dart';

/// Servicio que maneja la lógica de negocio del inventario
class InventarioLogicService {
  final DatosService _datosService = DatosService();
  final InventarioStateService _stateService = InventarioStateService(); // Usa singleton

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando InventarioLogicService...');
      await _datosService.initialize();
      LoggingService.info('✅ InventarioLogicService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando InventarioLogicService: $e');
      _stateService.updateError('Error inicializando servicio: $e');
    }
  }

  /// Cargar productos
  Future<void> loadProductos() async {
    try {
      _stateService.updateCargando(true);
      _stateService.clearError();
      
      LoggingService.info('📦 Cargando productos...');
      final productos = await _datosService.getProductos();
      
      _stateService.updateProductos(productos);
      _stateService.updateCargando(false);
      
      LoggingService.info('✅ Productos cargados: ${productos.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando productos: $e');
      _stateService.updateError('Error cargando productos: $e');
      _stateService.updateCargando(false);
    }
  }

  /// Cargar categorías
  Future<void> loadCategorias() async {
    try {
      LoggingService.info('🏷️ Cargando categorías...');
      final categorias = await _datosService.getCategorias();
      
      _stateService.updateCategorias(categorias);
      
      LoggingService.info('✅ Categorías cargadas: ${categorias.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando categorías: $e');
      _stateService.updateError('Error cargando categorías: $e');
    }
  }

  /// Cargar tallas
  Future<void> loadTallas() async {
    try {
      LoggingService.info('📏 Cargando tallas...');
      final tallas = await _datosService.getTallas();
      
      _stateService.updateTallas(tallas);
      
      LoggingService.info('✅ Tallas cargadas: ${tallas.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando tallas: $e');
      _stateService.updateError('Error cargando tallas: $e');
    }
  }

  /// Cargar todos los datos
  Future<void> loadAllData() async {
    try {
      LoggingService.info('📊 Cargando todos los datos del inventario...');
      
      await Future.wait([
        loadProductos(),
        loadCategorias(),
        loadTallas(),
      ]);
      
      LoggingService.info('✅ Todos los datos cargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando datos: $e');
      _stateService.updateError('Error cargando datos: $e');
    }
  }

  /// Filtrar productos
  List<Producto> getProductosFiltrados() {
    return InventarioFunctions.filterProductos(
      _stateService.productos.cast<Producto>(),
      categoria: _stateService.filtroCategoria,
      talla: _stateService.filtroTalla,
      busqueda: _stateService.busqueda,
      mostrarSoloStockBajo: _stateService.mostrarSoloStockBajo,
    );
  }

  /// Eliminar producto
  Future<bool> eliminarProducto(int productoId) async {
    try {
      LoggingService.info('🗑️ Eliminando producto: $productoId');
      
      await _datosService.deleteProducto(productoId);
      
      // Recargar productos después de eliminar
      await loadProductos();
      
      LoggingService.info('✅ Producto eliminado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando producto: $e');
      _stateService.updateError('Error eliminando producto: $e');
      return false;
    }
  }

  /// Obtener estadísticas del inventario
  Map<String, dynamic> getEstadisticas() {
    final productosFiltrados = getProductosFiltrados();
    
    return {
      'totalProductos': InventarioFunctions.calcularTotalProductos(productosFiltrados),
      'stockBajo': InventarioFunctions.calcularStockBajo(productosFiltrados),
      'valorTotal': InventarioFunctions.calcularValorTotal(productosFiltrados),
      'productosFiltrados': productosFiltrados.length,
    };
  }

  /// Obtener datos para lazy loading
  Future<List<Producto>> getProductosLazy({
    required int page,
    required int limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      return await _datosService.getProductosLazy(
        page: page,
        limit: limit,
        filters: filters ?? _stateService.getCurrentFilters(),
      );
    } catch (e) {
      LoggingService.error('❌ Error en lazy loading: $e');
      return [];
    }
  }

  /// Recargar datos
  Future<void> refreshData() async {
    try {
      LoggingService.info('🔄 Recargando datos del inventario...');
      await loadAllData();
      LoggingService.info('✅ Datos recargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error recargando datos: $e');
      _stateService.updateError('Error recargando datos: $e');
    }
  }

  /// Actualizar categorías después de gestión
  void updateCategorias(List<dynamic> nuevasCategorias) {
    try {
      LoggingService.info('🏷️ Actualizando categorías: ${nuevasCategorias.length}');
      _stateService.updateCategorias(nuevasCategorias.cast());
      LoggingService.info('✅ Categorías actualizadas correctamente');
    } catch (e) {
      LoggingService.error('❌ Error actualizando categorías: $e');
      _stateService.updateError('Error actualizando categorías: $e');
    }
  }

  /// Actualizar tallas después de gestión
  void updateTallas(List<dynamic> nuevasTallas) {
    try {
      LoggingService.info('📏 Actualizando tallas: ${nuevasTallas.length}');
      _stateService.updateTallas(nuevasTallas.cast());
      LoggingService.info('✅ Tallas actualizadas correctamente');
    } catch (e) {
      LoggingService.error('❌ Error actualizando tallas: $e');
      _stateService.updateError('Error actualizando tallas: $e');
    }
  }

  /// Obtener categorías para gestión
  List<dynamic> getCategoriasParaGestion() {
    return _stateService.categorias.cast<dynamic>();
  }

  /// Obtener tallas para gestión
  List<dynamic> getTallasParaGestion() {
    return _stateService.tallas.cast<dynamic>();
  }

  /// Obtener productos para gestión
  List<dynamic> getProductosParaGestion() {
    return _stateService.productos.cast<dynamic>();
  }

  /// Eliminar categoría de la base de datos
  Future<bool> eliminarCategoria(int categoriaId) async {
    try {
      LoggingService.info('🗑️ Eliminando categoría: $categoriaId');
      
      await _datosService.deleteCategoria(categoriaId);
      
      // Recargar categorías después de eliminar
      await loadCategorias();
      
      LoggingService.info('✅ Categoría eliminada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando categoría: $e');
      _stateService.updateError('Error eliminando categoría: $e');
      return false;
    }
  }

  /// Eliminar talla de la base de datos
  Future<bool> eliminarTalla(int tallaId) async {
    try {
      LoggingService.info('🗑️ Eliminando talla: $tallaId');
      
      await _datosService.deleteTalla(tallaId);
      
      // Recargar tallas después de eliminar
      await loadTallas();
      
      LoggingService.info('✅ Talla eliminada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando talla: $e');
      _stateService.updateError('Error eliminando talla: $e');
      return false;
    }
  }

  /// Verificar si se puede eliminar una categoría
  Future<bool> puedeEliminarCategoria(int categoriaId, String nombreCategoria) async {
    try {
      final productos = _stateService.productos.cast<Producto>();
      final productosConCategoria = productos.where((p) => p.categoria == nombreCategoria).toList();
      
      if (productosConCategoria.isNotEmpty) {
        LoggingService.warning('⚠️ No se puede eliminar categoría "$nombreCategoria": tiene ${productosConCategoria.length} productos asociados');
        return false;
      }
      
      return true;
    } catch (e) {
      LoggingService.error('❌ Error verificando eliminación de categoría: $e');
      return false;
    }
  }

  /// Verificar si se puede eliminar una talla
  Future<bool> puedeEliminarTalla(int tallaId, String nombreTalla) async {
    try {
      final productos = _stateService.productos.cast<Producto>();
      final productosConTalla = productos.where((p) => p.talla == nombreTalla).toList();
      
      if (productosConTalla.isNotEmpty) {
        LoggingService.warning('⚠️ No se puede eliminar talla "$nombreTalla": tiene ${productosConTalla.length} productos asociados');
        return false;
      }
      
      return true;
    } catch (e) {
      LoggingService.error('❌ Error verificando eliminación de talla: $e');
      return false;
    }
  }
}
