import '../../system/logging_service.dart';
import '../../ai/ai_insights_service.dart';
import '../../ml/ml_persistence_service.dart';
import '../../system/data_migration_service.dart';
import '../../datos/dashboard_service.dart';

/// Servicio que maneja toda la lógica del dashboard
class DashboardLogicService {
  static final DashboardLogicService _instance = DashboardLogicService._internal();
  factory DashboardLogicService() => _instance;
  DashboardLogicService._internal();

  // Servicios
  final AIInsightsService _aiInsightsService = AIInsightsService();
  final MLPersistenceService _mlPersistenceService = MLPersistenceService();
  final DataMigrationService _dataMigrationService = DataMigrationService();
  final DashboardService _dashboardService = DashboardService();

  // Estado
  AIInsights? _aiInsights;
  bool _isLoadingInsights = false;
  bool _isInitialized = false;

  // Getters
  AIInsights? get aiInsights => _aiInsights;
  bool get isLoadingInsights => _isLoadingInsights;
  bool get isInitialized => _isInitialized;
  DashboardService get dashboardService => _dashboardService;

  /// Inicializar todos los servicios del dashboard
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      LoggingService.info('🚀 Inicializando servicios del dashboard...');
      
      // Inicializar servicios de ML
      await _mlPersistenceService.initialize();
      
      // Migrar datos existentes
      await _migrateExistingData();
      
      // Cargar insights de IA
      await _loadAIInsights();
      
      _isInitialized = true;
      LoggingService.info('✅ Servicios del dashboard inicializados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicios del dashboard: $e');
      rethrow;
    }
  }

  /// Migrar datos existentes
  Future<void> _migrateExistingData() async {
    try {
      final isMigrated = await _dataMigrationService.isDataMigrated();
      
      if (!isMigrated) {
        LoggingService.info('📦 Iniciando migración de datos...');
        await _dataMigrationService.migrateExistingData();
        
        // Recargar datos de entrenamiento después de la migración
        LoggingService.info('📊 Datos migrados, listos para análisis ML');
        
        LoggingService.info('✅ Migración de datos completada');
      } else {
        LoggingService.info('ℹ️ Los datos ya fueron migrados anteriormente');
      }
    } catch (e) {
      LoggingService.error('❌ Error en migración de datos: $e');
      rethrow;
    }
  }

  /// Cargar insights de IA
  Future<void> _loadAIInsights() async {
    try {
      _isLoadingInsights = true;
      LoggingService.info('🤖 Cargando insights de IA...');
      
      final insights = await _aiInsightsService.generateInsights();
      _aiInsights = insights;
      _isLoadingInsights = false;
      
      LoggingService.info('✅ Insights de IA cargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando insights de IA: $e');
      _isLoadingInsights = false;
      rethrow;
    }
  }

  /// Recargar insights de IA
  Future<void> reloadAIInsights() async {
    await _loadAIInsights();
  }

  /// Realizar búsqueda
  void performSearch(String query) {
    if (query.isEmpty) {
      LoggingService.info('🔍 Búsqueda vacía - volviendo al dashboard');
      return;
    }
    
    LoggingService.info('🔍 Búsqueda realizada: $query');
    // La búsqueda se maneja automáticamente por GlobalSearchWidget
  }

  /// Obtener subtítulo para una pantalla específica
  String getSubtitle(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 'Aquí tienes un resumen de tu negocio.';
      case 1:
        return 'Gestiona tu inventario de productos.';
      case 2:
        return 'Registra y gestiona tus ventas.';
      case 3:
        return 'Administra tu base de clientes.';
      case 4:
        return 'Visualiza reportes y estadísticas.';
      case 5:
        return 'Calcula precios de venta.';
      case 6:
        return 'Configura tu aplicación.';
      default:
        return 'Pantalla de la aplicación.';
    }
  }

  /// Obtener título para una pantalla específica
  String getTitle(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Inventario';
      case 2:
        return 'Ventas';
      case 3:
        return 'Clientes';
      case 4:
        return 'Reportes';
      case 5:
        return 'Cálculo de Precios';
      case 6:
        return 'Configuración';
      default:
        return 'Pantalla';
    }
  }

  /// Limpiar recursos
  void dispose() {
    LoggingService.info('🧹 Limpiando recursos del dashboard...');
    // Los servicios se limpian automáticamente
  }
}
