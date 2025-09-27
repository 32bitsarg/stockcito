import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja la carga y gestión de datos de los reportes
class ReportesDataService {
  final DatosService _datosService = DatosService();
  
  ReportesDataService();

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando ReportesDataService...');
      await _datosService.initialize();
      LoggingService.info('✅ ReportesDataService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando ReportesDataService: $e');
      rethrow;
    }
  }

  /// Obtener todos los productos
  Future<List<Producto>> getProductos() async {
    try {
      LoggingService.info('📊 Obteniendo productos...');
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
      LoggingService.info('📊 Obteniendo productos lazy (página $page, límite $limit)...');
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

  /// Obtener estadísticas de los productos
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      LoggingService.info('📈 Obteniendo estadísticas de productos...');
      
      final productos = await getProductos();
      
      final totalProductos = productos.length;
      final stockBajo = productos.where((p) => p.stock < 10).length;
      final stockAlto = productos.where((p) => p.stock >= 50).length;
      final valorTotal = productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
      final precioPromedio = totalProductos > 0 ? valorTotal / totalProductos : 0.0;
      
      final estadisticas = {
        'totalProductos': totalProductos,
        'stockBajo': stockBajo,
        'stockAlto': stockAlto,
        'valorTotal': valorTotal,
        'precioPromedio': precioPromedio,
      };
      
      LoggingService.info('✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Buscar productos
  Future<List<Producto>> searchProductos(String query) async {
    try {
      LoggingService.info('🔍 Buscando productos: $query');
      
      final productos = await getProductos();
      
      if (query.isEmpty) return productos;
      
      final resultados = productos.where((producto) {
        final nombre = producto.nombre.toLowerCase();
        final categoria = producto.categoria.toLowerCase();
        final talla = producto.talla.toLowerCase();
        final busqueda = query.toLowerCase();
        
        return nombre.contains(busqueda) ||
               categoria.contains(busqueda) ||
               talla.contains(busqueda);
      }).toList();
      
      LoggingService.info('✅ Búsqueda completada: ${resultados.length} resultados');
      return resultados;
    } catch (e) {
      LoggingService.error('❌ Error buscando productos: $e');
      rethrow;
    }
  }

  /// Sincronizar datos
  Future<void> syncData() async {
    try {
      LoggingService.info('🔄 Sincronizando datos de reportes...');
      // await _datosService.syncAllData(); // Comentado hasta que se implemente
      LoggingService.info('✅ Datos de reportes sincronizados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando datos: $e');
      rethrow;
    }
  }

  /// Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      // return await _datosService.checkConnectivity(); // Comentado hasta que se implemente
      return true; // Temporal
    } catch (e) {
      LoggingService.error('❌ Error verificando conectividad: $e');
      return false;
    }
  }
}


