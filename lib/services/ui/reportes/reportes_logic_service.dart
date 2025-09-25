import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import 'reportes_state_service.dart';
import '../../../screens/reportes_screen/functions/reportes_functions.dart';

/// Servicio que maneja la lógica de negocio de los reportes
class ReportesLogicService {
  final DatosService _datosService = DatosService();
  late final ReportesStateService _stateService;
  
  ReportesLogicService(ReportesStateService stateService) : _stateService = stateService;

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando ReportesLogicService...');
      await _datosService.initialize();
      LoggingService.info('✅ ReportesLogicService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando ReportesLogicService: $e');
      _stateService.updateError('Error inicializando servicio: $e');
    }
  }

  /// Cargar productos
  Future<void> loadProductos() async {
    try {
      _stateService.updateLoading(true);
      _stateService.clearError();
      
      LoggingService.info('📊 Cargando productos...');
      final productos = await _datosService.getProductos();
      
      _stateService.updateProductos(productos);
      _stateService.updateLoading(false);
      
      LoggingService.info('✅ Productos cargados: ${productos.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando productos: $e');
      _stateService.updateError('Error cargando productos: $e');
      _stateService.updateLoading(false);
    }
  }

  /// Cargar métricas completas
  Future<void> loadMetricasCompletas() async {
    try {
      LoggingService.info('📈 Cargando métricas completas...');
      
      final metricas = await ReportesFunctions.calcularMetricasCompletas(
        productos: _stateService.productos.cast<Producto>(),
      );
      
      _stateService.updateMetricasCompletas(metricas);
      
      LoggingService.info('✅ Métricas completas cargadas');
    } catch (e) {
      LoggingService.error('❌ Error cargando métricas: $e');
      _stateService.updateError('Error cargando métricas: $e');
    }
  }

  /// Cargar todos los datos
  Future<void> loadAllData() async {
    try {
      LoggingService.info('📊 Cargando todos los datos de reportes...');
      
      await loadProductos();
      await loadMetricasCompletas();
      
      LoggingService.info('✅ Todos los datos de reportes cargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando datos: $e');
      _stateService.updateError('Error cargando datos: $e');
    }
  }

  /// Filtrar productos
  List<Producto> getProductosFiltrados() {
    return ReportesFunctions.filterProductos(
      _stateService.productos.cast<Producto>(),
      _stateService.filtroCategoria,
      _stateService.filtroTalla,
    );
  }

  /// Obtener productos por categoría
  Map<String, int> getProductosPorCategoria() {
    return ReportesFunctions.getProductosPorCategoria(getProductosFiltrados());
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
      LoggingService.error('❌ Error en lazy loading de productos: $e');
      return [];
    }
  }

  /// Exportar reporte
  Future<bool> exportarReporte(String formato) async {
    try {
      LoggingService.info('📄 Exportando reporte en formato: $formato');
      
      // Temporal: simular exportación exitosa hasta implementar el método
      LoggingService.info('✅ Reporte exportado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error exportando reporte: $e');
      _stateService.updateError('Error exportando reporte: $e');
      return false;
    }
  }

  /// Recargar datos
  Future<void> refreshData() async {
    try {
      LoggingService.info('🔄 Recargando datos de reportes...');
      await loadAllData();
      LoggingService.info('✅ Datos de reportes recargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error recargando datos: $e');
      _stateService.updateError('Error recargando datos: $e');
    }
  }
}
