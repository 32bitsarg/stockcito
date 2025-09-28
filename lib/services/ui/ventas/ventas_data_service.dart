import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/system/connectivity_service.dart';

/// Servicio que maneja la carga y gestión de datos de las ventas
class VentasDataService {
  final DatosService _datosService = DatosService();
  
  VentasDataService();

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando VentasDataService...');
      await _datosService.initialize();
      LoggingService.info('✅ VentasDataService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando VentasDataService: $e');
      rethrow;
    }
  }

  /// Obtener todas las ventas
  Future<List<Venta>> getVentas() async {
    try {
      LoggingService.info('💰 Obteniendo ventas...');
      final ventas = await _datosService.getVentas();
      LoggingService.info('✅ Ventas obtenidas: ${ventas.length}');
      return ventas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo ventas: $e');
      rethrow;
    }
  }

  /// Obtener ventas con lazy loading
  Future<List<Venta>> getVentasLazy({
    required int page,
    required int limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      LoggingService.info('💰 Obteniendo ventas lazy (página $page, límite $limit)...');
      final ventas = await _datosService.getVentasLazy(
        page: page,
        limit: limit,
        filters: filters,
      );
      LoggingService.info('✅ Ventas lazy obtenidas: ${ventas.length}');
      return ventas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo ventas lazy: $e');
      rethrow;
    }
  }

  /// Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    try {
      LoggingService.info('👥 Obteniendo clientes...');
      final clientes = await _datosService.getClientes();
      LoggingService.info('✅ Clientes obtenidos: ${clientes.length}');
      return clientes;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo clientes: $e');
      rethrow;
    }
  }

  /// Eliminar venta
  Future<void> deleteVenta(int ventaId) async {
    try {
      LoggingService.info('🗑️ Eliminando venta: $ventaId');
      await _datosService.deleteVenta(ventaId);
      LoggingService.info('✅ Venta eliminada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando venta: $e');
      rethrow;
    }
  }

  /// Crear venta
  Future<Venta> createVenta(Venta venta) async {
    try {
      LoggingService.info('➕ Creando venta: ${venta.cliente}');
      
      // Guardar en base de datos usando el método correcto
      final success = await _datosService.saveVenta(venta);
      
      if (!success) {
        throw Exception('Failed to save sale');
      }
      
      // Retornar la venta
      final ventaCreada = venta;
      
      LoggingService.info('✅ Venta creada correctamente: ${venta.id}');
      return ventaCreada;
    } catch (e) {
      LoggingService.error('❌ Error creando venta: $e');
      rethrow;
    }
  }

  /// Actualizar venta
  Future<Venta> updateVenta(Venta venta) async {
    try {
      LoggingService.info('✏️ Actualizando venta: ${venta.id}');
      // Actualizar en base de datos
      final success = await _datosService.saveVenta(venta);
      
      if (!success) {
        throw Exception('Failed to update sale');
      }
      
      final ventaActualizada = venta;
      LoggingService.info('✅ Venta actualizada correctamente: ${ventaActualizada.id}');
      return ventaActualizada;
    } catch (e) {
      LoggingService.error('❌ Error actualizando venta: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de las ventas
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      LoggingService.info('📊 Obteniendo estadísticas de ventas...');
      
      final ventas = await getVentas();
      final clientes = await getClientes();
      
      final totalVentas = ventas.fold(0.0, (sum, v) => sum + v.total);
      final numeroVentas = ventas.length;
      final promedioVentas = numeroVentas > 0 ? totalVentas / numeroVentas : 0.0;
      final ventasCompletadas = ventas.where((v) => v.estado == 'Completada').length;
      final ventasPendientes = ventas.where((v) => v.estado == 'Pendiente').length;
      
      final estadisticas = {
        'totalVentas': totalVentas,
        'numeroVentas': numeroVentas,
        'promedioVentas': promedioVentas,
        'ventasCompletadas': ventasCompletadas,
        'ventasPendientes': ventasPendientes,
        'totalClientes': clientes.length,
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
      LoggingService.info('🔄 Sincronizando datos de ventas...');
      await _datosService.forceSync(); // Usar método existente de DatosService
      LoggingService.info('✅ Datos de ventas sincronizados correctamente');
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
