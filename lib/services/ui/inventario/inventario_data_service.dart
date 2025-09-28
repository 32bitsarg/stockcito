import '../../../models/producto.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/system/connectivity_service.dart';

/// Servicio que maneja la carga y gestión de datos del inventario
class InventarioDataService {
  final DatosService _datosService = DatosService();

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando InventarioDataService...');
      await _datosService.initialize();
      LoggingService.info('✅ InventarioDataService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando InventarioDataService: $e');
      rethrow;
    }
  }

  /// Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    try {
      LoggingService.info('📦 Obteniendo productos...');
      final productos = await _datosService.getProductos();
      LoggingService.info('✅ Productos obtenidos: ${productos.length}');
      return productos;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo productos: $e');
      rethrow;
    }
  }

  /// Obtener productos con lazy loading
  Future<List<Producto>> getProductosLazy({
    required int page,
    required int limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      LoggingService.info('📦 Obteniendo productos lazy (página $page, límite $limit)...');
      final productos = await _datosService.getProductosLazy(
        page: page,
        limit: limit,
        filters: filters,
      );
      LoggingService.info('✅ Productos lazy obtenidos: ${productos.length}');
      return productos;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo productos lazy: $e');
      rethrow;
    }
  }

  /// Obtener todas las categorías
  Future<List<Categoria>> getCategorias() async {
    try {
      LoggingService.info('🏷️ Obteniendo categorías...');
      final categorias = await _datosService.getCategorias();
      LoggingService.info('✅ Categorías obtenidas: ${categorias.length}');
      return categorias;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo categorías: $e');
      rethrow;
    }
  }

  /// Obtener todas las tallas
  Future<List<Talla>> getTallas() async {
    try {
      LoggingService.info('📏 Obteniendo tallas...');
      final tallas = await _datosService.getTallas();
      LoggingService.info('✅ Tallas obtenidas: ${tallas.length}');
      return tallas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo tallas: $e');
      rethrow;
    }
  }

  /// Eliminar producto
  Future<void> deleteProducto(int productoId) async {
    try {
      LoggingService.info('🗑️ Eliminando producto: $productoId');
      await _datosService.deleteProducto(productoId);
      LoggingService.info('✅ Producto eliminado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando producto: $e');
      rethrow;
    }
  }

  /// Crear producto
  Future<Producto> createProducto(Producto producto) async {
    try {
      LoggingService.info('➕ Creando producto: ${producto.nombre}');
      
      // Guardar en base de datos usando el método correcto
      final success = await _datosService.saveProducto(producto);
      
      if (!success) {
        throw Exception('Failed to save product');
      }
      
      // Retornar el producto con el ID asignado
      final productoCreado = producto;
      
      LoggingService.info('✅ Producto creado correctamente: ${producto.id}');
      return productoCreado;
    } catch (e) {
      LoggingService.error('❌ Error creando producto: $e');
      rethrow;
    }
  }

  /// Actualizar producto
  Future<Producto> updateProducto(Producto producto) async {
    try {
      LoggingService.info('✏️ Actualizando producto: ${producto.nombre}');
      
      // Actualizar en base de datos
      final success = await _datosService.saveProducto(producto);
      
      if (!success) {
        throw Exception('Failed to update product');
      }
      
      LoggingService.info('✅ Producto actualizado correctamente: ${producto.id}');
      return producto;
    } catch (e) {
      LoggingService.error('❌ Error actualizando producto: $e');
      rethrow;
    }
  }

  /// Crear categoría
  Future<Categoria> createCategoria(Categoria categoria) async {
    try {
      LoggingService.info('➕ Creando categoría: ${categoria.nombre}');
      
      final categoriaCreada = await _datosService.saveCategoria(categoria);
      
      LoggingService.info('✅ Categoría creada correctamente: ${categoriaCreada.id}');
      return categoriaCreada;
    } catch (e) {
      LoggingService.error('❌ Error creando categoría: $e');
      rethrow;
    }
  }

  /// Actualizar categoría
  Future<Categoria> updateCategoria(Categoria categoria) async {
    try {
      LoggingService.info('✏️ Actualizando categoría: ${categoria.nombre}');
      final categoriaActualizada = await _datosService.updateCategoria(categoria);
      LoggingService.info('✅ Categoría actualizada correctamente: ${categoriaActualizada.id}');
      return categoriaActualizada;
    } catch (e) {
      LoggingService.error('❌ Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Eliminar categoría
  Future<void> deleteCategoria(int categoriaId) async {
    try {
      LoggingService.info('🗑️ Eliminando categoría: $categoriaId');
      await _datosService.deleteCategoria(categoriaId);
      LoggingService.info('✅ Categoría eliminada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando categoría: $e');
      rethrow;
    }
  }

  /// Crear talla
  Future<Talla> createTalla(Talla talla) async {
    try {
      LoggingService.info('➕ Creando talla: ${talla.nombre}');
      
      final tallaCreada = await _datosService.saveTalla(talla);
      
      LoggingService.info('✅ Talla creada correctamente: ${tallaCreada.id}');
      return tallaCreada;
    } catch (e) {
      LoggingService.error('❌ Error creando talla: $e');
      rethrow;
    }
  }

  /// Actualizar talla
  Future<Talla> updateTalla(Talla talla) async {
    try {
      LoggingService.info('✏️ Actualizando talla: ${talla.nombre}');
      final tallaActualizada = await _datosService.updateTalla(talla);
      LoggingService.info('✅ Talla actualizada correctamente: ${tallaActualizada.id}');
      return tallaActualizada;
    } catch (e) {
      LoggingService.error('❌ Error actualizando talla: $e');
      rethrow;
    }
  }

  /// Eliminar talla
  Future<void> deleteTalla(int tallaId) async {
    try {
      LoggingService.info('🗑️ Eliminando talla: $tallaId');
      await _datosService.deleteTalla(tallaId);
      LoggingService.info('✅ Talla eliminada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando talla: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas del inventario
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      LoggingService.info('📊 Obteniendo estadísticas del inventario...');
      
      final productos = await getProductos();
      final categorias = await getCategorias();
      final tallas = await getTallas();
      
      final totalProductos = productos.length;
      final stockBajo = productos.where((p) => p.stock < 10).length;
      final valorTotal = productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
      final totalCategorias = categorias.length;
      final totalTallas = tallas.length;
      
      final estadisticas = {
        'totalProductos': totalProductos,
        'stockBajo': stockBajo,
        'valorTotal': valorTotal,
        'totalCategorias': totalCategorias,
        'totalTallas': totalTallas,
        'productosConStock': productos.where((p) => p.stock > 0).length,
        'productosSinStock': productos.where((p) => p.stock == 0).length,
      };
      
      LoggingService.info('✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Sincronizar datos
  Future<void> syncData() async {
    try {
      LoggingService.info('🔄 Sincronizando datos del inventario...');
      await _datosService.forceSync(); // Usar método existente de DatosService
      LoggingService.info('✅ Datos sincronizados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando datos: $e');
      rethrow;
    }
  }

  /// Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      final connectivityService = ConnectivityService();
      final connectivityInfo = await connectivityService.checkConnectivity();
      return connectivityInfo.hasInternet; // Usar servicio de conectividad existente
    } catch (e) {
      LoggingService.error('❌ Error verificando conectividad: $e');
      return false;
    }
  }
}
