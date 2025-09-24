import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/modern_sidebar.dart';
import '../../widgets/modern_header.dart';
import '../../widgets/smart_notifications_widget.dart';
import '../../services/datos/dashboard_service.dart';
import '../../services/ai/ai_insights_service.dart';
import '../../services/ml/advanced_ml_service.dart';
import '../../services/ml/ml_persistence_service.dart';
import '../../services/system/data_migration_service.dart';
import '../../widgets/connectivity_status_widget.dart';
import '../../widgets/sync_status_widget.dart';
import '../../services/system/logging_service.dart';
import '../../widgets/search/global_search_widget.dart';
import '../../models/search_result.dart';
import 'widgets/dashboard_stats.dart';
import 'widgets/dashboard_bar_chart.dart';
import 'widgets/dashboard_ai_sidebar.dart';
import 'models/dashboard_menu_items.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  
  // Servicios de IA
  final AIInsightsService _aiInsightsService = AIInsightsService();
  final AdvancedMLService _advancedMLService = AdvancedMLService();
  final MLPersistenceService _mlPersistenceService = MLPersistenceService();
  final DataMigrationService _dataMigrationService = DataMigrationService();
  AIInsights? _aiInsights;
  bool _isLoadingInsights = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Inicializar servicios
  Future<void> _initializeServices() async {
    try {
      // Inicializar servicios de ML
      await _mlPersistenceService.initialize();
      
      // Migrar datos existentes
      await _migrateExistingData();
      
      // Cargar insights de IA
      await _loadAIInsights();
      
      // Los datos del dashboard se cargan automáticamente en el constructor
    } catch (e) {
      LoggingService.error('Error inicializando servicios: $e');
    }
  }


  // Migrar datos existentes
  Future<void> _migrateExistingData() async {
    try {
      final isMigrated = await _dataMigrationService.isDataMigrated();
      
      if (!isMigrated) {
        LoggingService.info('Iniciando migración de datos...');
        await _dataMigrationService.migrateExistingData();
        
        // Recargar datos de entrenamiento después de la migración
        await _advancedMLService.loadTrainingData();
        
        LoggingService.info('Migración de datos completada');
      } else {
        LoggingService.info('Los datos ya fueron migrados anteriormente');
      }
    } catch (e) {
      LoggingService.error('Error en migración de datos: $e');
    }
  }

  // Cargar insights de IA
  Future<void> _loadAIInsights() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingInsights = true;
    });
    
    try {
      final insights = await _aiInsightsService.generateInsights();
      if (mounted) {
        setState(() {
          _aiInsights = insights;
          _isLoadingInsights = false;
        });
      }
    } catch (e) {
      LoggingService.error('Error cargando insights: $e');
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
    }
  }

  // Realizar búsqueda
  void _performSearch(String query) {
    if (query.isEmpty) {
      // Si la búsqueda está vacía, volver al dashboard
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }
    
    LoggingService.info('🔍 Búsqueda realizada: $query');
    // La búsqueda se maneja automáticamente por GlobalSearchWidget
  }

  // Manejar selección de resultado de búsqueda
  void _onSearchResultSelected(SearchResult result) {
    LoggingService.info('🎯 Resultado seleccionado: ${result.title} (${result.type})');
    
    // Navegar según el tipo de resultado
    switch (result.type) {
      case 'producto':
        setState(() {
          _selectedIndex = 1; // Inventario
        });
        break;
      case 'venta':
        setState(() {
          _selectedIndex = 2; // Ventas
        });
        break;
      case 'cliente':
        setState(() {
          _selectedIndex = 3; // Clientes (si existe) o Ventas
        });
        break;
      default:
        // Mantener en dashboard
        break;
    }
    
    // Mostrar mensaje de navegación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando a ${result.title}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Obtener subtítulo
  String _getSubtitle() {
    return DashboardMenuItems.getSubtitle(_selectedIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // Sidebar izquierdo
          ModernSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          
          // Contenido principal
          Expanded(
            child: Column(
              children: [
                // Header principal solo para otras pantallas (no dashboard)
                if (_selectedIndex != 0)
                  ModernHeader(
                    title: DashboardMenuItems.getLabel(_selectedIndex),
                    subtitle: _getSubtitle(),
                    searchController: _searchController,
                    onSearch: (query) {
                      _performSearch(query);
                    },
                    actions: [
                      // Widget de estado de conectividad
                      const ConnectivityStatusWidget(showDetails: true),
                      const SizedBox(width: 8),
                      // Widget de estado de sincronización
                      const SyncStatusWidget(showDetails: true),
                      const SizedBox(width: 8),
                      // Widget de notificaciones inteligentes
                      const SmartNotificationsWidget(),
                      const SizedBox(width: 8),
                    ],
                  ),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedIndex == 0) {
      return _buildDashboardContent();
    } else {
      return _buildScreenContent();
    }
  }

  Widget _buildDashboardContent() {
    return Consumer<DashboardService>(
      builder: (context, dashboardService, child) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Columna izquierda - Contenido principal
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header del dashboard con búsqueda global
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título del dashboard
                        Text(
                          'Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenido de vuelta. Aquí tienes un resumen de tu negocio.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Búsqueda global
                        GlobalSearchWidget(
                          onResultSelected: _onSearchResultSelected,
                          onSearchPerformed: _performSearch,
                          hintText: 'Buscar productos, ventas, clientes...',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Layout: Gráfico a la izquierda, Stats centrados abajo - Ocupando todo el alto
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch, // Estirar verticalmente
                        children: [
                          // Gráfico de barras - Izquierda (altura completa)
                          SizedBox(
                            width: 400, // Ancho fijo para el gráfico
                            child: DashboardBarChart(
                              ventasUltimos7Dias: dashboardService.ventasUltimos7Dias,
                            ),
                          ),
                          
                          const SizedBox(width: 32),
                          
                          // Estadísticas - Centro expandido ocupando todo el alto
                          Expanded(
                            child: DashboardStats(dashboardService: dashboardService),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Columna derecha - Sidebar de IA
              Expanded(
                flex: 1,
                child: DashboardAISidebar(
                  aiInsights: _aiInsights,
                  isLoadingInsights: _isLoadingInsights,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreenContent() {
    return DashboardMenuItems.getScreen(_selectedIndex);
  }
}
