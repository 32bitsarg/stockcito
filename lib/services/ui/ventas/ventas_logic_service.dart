import '../../../models/venta.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import 'ventas_state_service.dart';
import '../../../screens/ventas_screen/functions/ventas_functions.dart';

/// Servicio que maneja la lógica de negocio de las ventas
class VentasLogicService {
  final DatosService _datosService = DatosService();
  late final VentasStateService _stateService;
  
  VentasLogicService(VentasStateService stateService) : _stateService = stateService;

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando VentasLogicService...');
      await _datosService.initialize();
      LoggingService.info('✅ VentasLogicService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando VentasLogicService: $e');
      _stateService.updateError('Error inicializando servicio: $e');
    }
  }

  /// Cargar ventas
  Future<void> loadVentas() async {
    try {
      _stateService.updateCargando(true);
      _stateService.clearError();
      
      LoggingService.info('💰 Cargando ventas...');
      final ventas = await _datosService.getVentas();
      
      _stateService.updateVentas(ventas);
      _stateService.updateCargando(false);
      
      LoggingService.info('✅ Ventas cargadas: ${ventas.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando ventas: $e');
      _stateService.updateError('Error cargando ventas: $e');
      _stateService.updateCargando(false);
    }
  }

  /// Cargar clientes
  Future<void> loadClientes() async {
    try {
      LoggingService.info('👥 Cargando clientes...');
      final clientes = await _datosService.getClientes();
      
      _stateService.updateClientes(clientes);
      
      LoggingService.info('✅ Clientes cargados: ${clientes.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando clientes: $e');
      _stateService.updateError('Error cargando clientes: $e');
    }
  }

  /// Cargar todos los datos
  Future<void> loadAllData() async {
    try {
      LoggingService.info('📊 Cargando todos los datos de ventas...');
      
      await Future.wait([
        loadVentas(),
        loadClientes(),
      ]);
      
      LoggingService.info('✅ Todos los datos de ventas cargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando datos: $e');
      _stateService.updateError('Error cargando datos: $e');
    }
  }

  /// Filtrar ventas
  List<Venta> getVentasFiltradas() {
    return VentasFunctions.filterVentas(
      _stateService.ventas.cast<Venta>(),
      estado: _stateService.filtroEstado,
      cliente: _stateService.filtroCliente,
      metodoPago: _stateService.filtroMetodoPago,
    );
  }

  /// Eliminar venta
  Future<bool> eliminarVenta(int ventaId) async {
    try {
      LoggingService.info('🗑️ Eliminando venta: $ventaId');
      
      await _datosService.deleteVenta(ventaId);
      
      // Recargar ventas después de eliminar
      await loadVentas();
      
      LoggingService.info('✅ Venta eliminada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando venta: $e');
      _stateService.updateError('Error eliminando venta: $e');
      return false;
    }
  }

  /// Obtener estadísticas de las ventas
  Map<String, dynamic> getEstadisticas() {
    final ventasFiltradas = getVentasFiltradas();
    
    return {
      'totalVentas': VentasFunctions.calcularTotalVentas(ventasFiltradas),
      'numeroVentas': VentasFunctions.calcularNumeroVentas(ventasFiltradas),
      'promedioVentas': VentasFunctions.calcularPromedioVentas(ventasFiltradas),
      'ventasFiltradas': ventasFiltradas.length,
    };
  }

  /// Obtener datos para lazy loading
  Future<List<Venta>> getVentasLazy({
    required int page,
    required int limit,
    Map<String, dynamic>? filters,
  }) async {
    try {
      return await _datosService.getVentasLazy(
        page: page,
        limit: limit,
        filters: filters ?? _stateService.getCurrentFilters(),
      );
    } catch (e) {
      LoggingService.error('❌ Error en lazy loading de ventas: $e');
      return [];
    }
  }

  /// Recargar datos
  Future<void> refreshData() async {
    try {
      LoggingService.info('🔄 Recargando datos de ventas...');
      await loadAllData();
      LoggingService.info('✅ Datos de ventas recargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error recargando datos: $e');
      _stateService.updateError('Error recargando datos: $e');
    }
  }
}
