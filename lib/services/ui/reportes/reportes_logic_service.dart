import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/export/export_service.dart';
import '../../../services/export/export_models.dart';
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

  /// Exportar reporte usando el nuevo sistema de exportación
  Future<bool> exportarReporte(String formato) async {
    try {
      LoggingService.info('📄 Exportando reporte en formato: $formato');
      
      final productos = getProductosFiltrados();
      final metricas = _stateService.metricasCompletas ?? {};
      
      // Preparar datos para exportación
      final insightsData = {
        'salesTrend': {
          'growthPercentage': metricas['ventas']?['ultimos_30_dias'] ?? 0,
          'trend': 'Estable',
          'bestDay': 'Lunes',
        },
        'popularProducts': {
          'topProduct': productos.isNotEmpty ? productos.first.nombre : 'N/A',
          'salesCount': productos.length,
          'category': productos.isNotEmpty ? productos.first.categoria : 'N/A',
        },
        'stockRecommendations': productos.where((p) => p.stock <= 5).map((p) => {
          'productName': p.nombre,
          'action': 'Reabastecer',
          'details': 'Stock bajo: ${p.stock} unidades',
          'urgency': p.stock <= 0 ? 'Alta' : 'Media',
        }).toList(),
      };
      
      final exportService = ExportService();
      final fileName = 'reporte_inventario_${DateTime.now().millisecondsSinceEpoch}';
      
      ExportResult result;
      if (formato.toLowerCase() == 'pdf') {
        result = await exportService.exportInsightsToPDF(
          insightsData: insightsData,
          fileName: fileName,
          options: ExportOptions(
            includeCharts: true,
            includeRecommendations: true,
            includeMetadata: true,
            customTitle: 'Reporte de Inventario - Stockcito',
          ),
        );
      } else if (formato.toLowerCase() == 'excel') {
        result = await exportService.exportInsightsToExcel(
          insightsData: insightsData,
          fileName: fileName,
          options: ExportOptions(
            includeCharts: true,
            includeRecommendations: true,
            includeMetadata: true,
            customTitle: 'Reporte de Inventario - Stockcito',
          ),
        );
      } else {
        throw Exception('Formato no soportado: $formato');
      }
      
      if (result.success) {
        LoggingService.info('✅ Reporte $formato exportado correctamente: ${result.filePath}');
        return true;
      } else {
        LoggingService.error('❌ Error en exportación: ${result.errorMessage}');
        _stateService.updateError('Error exportando reporte: ${result.errorMessage}');
        return false;
      }
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
