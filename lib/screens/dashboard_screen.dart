import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../widgets/modern_sidebar.dart';
import '../widgets/modern_header.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/stock_recommendations_widget.dart';
import '../widgets/notification_dropdown.dart';
import '../widgets/notification_dropdown_widget.dart';
import '../widgets/advanced_ai_analysis_widget.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../services/ai_insights_service.dart';
import 'modern_calculo_precio_screen.dart';
import 'modern_inventario_screen.dart';
import 'modern_reportes_screen.dart';
import 'modern_ventas_screen.dart';
import 'gestión_clientes_screen.dart';
import 'modern_configuracion_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  
  // Clave global para el menú
  final GlobalKey _menuKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  
  // Servicios de IA
  final AIInsightsService _aiInsightsService = AIInsightsService();
  AIInsights? _aiInsights;
  bool _isLoadingInsights = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().cargarDatos();
      // Inicializar servicio de notificaciones
      _initializeNotifications();
      // Cargar insights de IA
      _loadAIInsights();
    });
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
      if (mounted) {
        setState(() {
          _isLoadingInsights = false;
        });
      }
      print('Error cargando insights de IA: $e');
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService().initialize();
      // Verificar stock bajo y mostrar notificaciones
      _checkStockAlerts();
      // Programar recordatorios de tareas
      _scheduleTaskReminders();
    } catch (e) {
      print('Error inicializando notificaciones: $e');
    }
  }

  Future<void> _checkStockAlerts() async {
    try {
      final dashboardService = context.read<DashboardService>();
      if (dashboardService.stockBajo > 0) {
        await NotificationService().showStockLowAlert(
          'Productos con stock bajo',
          dashboardService.stockBajo,
        );
      }
    } catch (e) {
      print('Error verificando alertas de stock: $e');
    }
  }

  Future<void> _scheduleTaskReminders() async {
    try {
      // Programar recordatorio diario para revisar inventario
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
      
      await NotificationService().scheduleNotification(
        id: 'daily_inventory_check',
        title: '📋 Recordatorio Diario',
        body: 'Es hora de revisar tu inventario y verificar el stock de productos',
        scheduledTime: reminderTime,
        type: NotificationType.taskReminder,
        data: {
          'action': 'check_inventory',
          'recurring': true,
        },
      );

      // Programar recordatorio semanal para análisis de ventas
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      final weeklyReminderTime = DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10, 0);
      
      await NotificationService().scheduleNotification(
        id: 'weekly_sales_analysis',
        title: '📊 Análisis Semanal',
        body: 'Revisa el análisis de ventas de la semana y planifica la próxima',
        scheduledTime: weeklyReminderTime,
        type: NotificationType.taskReminder,
        data: {
          'action': 'analyze_sales',
          'recurring': true,
        },
      );
    } catch (e) {
      print('Error programando recordatorios: $e');
    }
  }



  final List<Map<String, dynamic>> _menuItems = [
    {'icon': FontAwesomeIcons.chartPie, 'label': 'Dashboard', 'color': AppTheme.primaryColor, 'subtitle': 'Resumen del negocio'},
    {'icon': FontAwesomeIcons.calculator, 'label': 'Calcular', 'color': AppTheme.secondaryColor, 'subtitle': 'Precios de productos'},
    {'icon': FontAwesomeIcons.boxesStacked, 'label': 'Inventario', 'color': AppTheme.accentColor, 'subtitle': 'Gestión de stock'},
    {'icon': FontAwesomeIcons.cartShopping, 'label': 'Ventas', 'color': AppTheme.successColor, 'subtitle': 'Gestión de ventas'},
    {'icon': FontAwesomeIcons.users, 'label': 'Clientes', 'color': AppTheme.warningColor, 'subtitle': 'Base de datos de clientes'},
    {'icon': FontAwesomeIcons.chartLine, 'label': 'Reportes', 'color': AppTheme.errorColor, 'subtitle': 'Análisis y estadísticas'},
    {'icon': FontAwesomeIcons.gear, 'label': 'Configuración', 'color': AppTheme.textSecondary, 'subtitle': 'Ajustes del sistema'},
  ];

  String _getSubtitle() {
    return _menuItems[_selectedIndex]['subtitle'] ?? '';
  }

  // Método para realizar búsqueda
  void _performSearch(String query) {
    if (query.isEmpty) {
      // Si la búsqueda está vacía, mostrar todos los datos
      return;
    }
    
    // Aquí puedes implementar la lógica de búsqueda
    // Por ejemplo, filtrar productos, clientes, etc.
    print('Buscando: $query');
    
    // Mostrar un snackbar con el resultado de la búsqueda
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buscando: "$query"'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
        body: Row(
          children: [
            // Sidebar
            ModernSidebar(
              key: _menuKey,
              selectedIndex: _selectedIndex,
              onItemSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header principal solo para otras pantallas (no dashboard)
                if (_selectedIndex != 0)
                  ModernHeader(
                    title: _menuItems[_selectedIndex]['label'],
                    subtitle: _getSubtitle(),
                    searchController: _searchController,
                    onSearch: () {
                      // Implementar búsqueda
                    },
                    actions: [
                      // Widget de notificaciones desplegable
                      const NotificationDropdown(),
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
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return const ModernCalculoPrecioScreen();
      case 2:
        return const ModernInventarioScreen();
      case 3:
        return const ModernVentasScreen();
      case 4:
        return const GestionClientesScreen();
      case 5:
        return const ModernReportesScreen();
      case 6:
        return const ModernConfiguracionScreen();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Consumer<DashboardService>(
      builder: (context, dashboardService, child) {
        if (dashboardService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (dashboardService.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error cargando datos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dashboardService.error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AnimatedButton(
                  text: 'Reintentar',
                  type: ButtonType.primary,
                  onPressed: () {
                    dashboardService.cargarDatos();
                  },
                  icon: FontAwesomeIcons.arrowRotateRight,
                  delay: const Duration(milliseconds: 100),
                ),
              ],
            ),
          );
        }
        
        return Row(
          children: [
            // Columna izquierda - Contenido principal
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header falso del dashboard simplificado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Título y subtítulo
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dashboard',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Text(
                                'Resumen del negocio',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Buscador compacto funcional
                          Container(
                            width: 200,
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Buscar productos, clientes...',
                                hintStyle: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                prefixIcon: Icon(
                                  FontAwesomeIcons.magnifyingGlass,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  minWidth: 20,
                                  minHeight: 20,
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black87,
                              ),
                              onChanged: (value) {
                                // Implementar búsqueda en tiempo real
                                _performSearch(value);
                              },
                              onSubmitted: (value) {
                                // Implementar búsqueda al presionar Enter
                                _performSearch(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Notificaciones desplegables modernas
                          const NotificationDropdownWidget(),
                          const SizedBox(width: 8),
                          // Perfil
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              FontAwesomeIcons.user,
                              color: Colors.grey.shade600,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón de tutorial
                          AnimatedButton(
                            text: 'Tutorial',
                            type: ButtonType.success,
                            onPressed: () {
                              // TODO: Implementar tutorial
                            },
                            icon: FontAwesomeIcons.graduationCap,
                            delay: const Duration(milliseconds: 100),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Métricas principales en diseño minimalista
                    _buildMinimalistMetrics(dashboardService),
                    const SizedBox(height: 12),
                    
                    // Contenido principal
                    Expanded(
                      child: Column(
                        children: [
                          _buildBusinessInfo(dashboardService),
                          const SizedBox(height: 12),
                          _buildMinimalistChart(dashboardService),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Columna derecha - Sidebar de IA que ocupa todo el alto de la ventana
            Expanded(
              flex: 1,
              child: _buildRightSidebar(),
            ),
          ],
        );
      },
    );
  }





  Widget _buildMinimalistMetrics(DashboardService dashboardService) {
    return Row(
      children: [
        Expanded(
          child: _buildMinimalistMetricCard(
            'Productos',
            '${dashboardService.totalProductos}',
            FontAwesomeIcons.boxesStacked,
            '+12%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMinimalistMetricCard(
            'Ventas del Mes',
            '${dashboardService.ventasRecientes.length}',
            FontAwesomeIcons.arrowTrendUp,
            '+8%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMinimalistMetricCard(
            'Clientes',
            '${dashboardService.totalClientes}',
            FontAwesomeIcons.users,
            '+5%',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMinimalistMetricCard(
            'Valor Inventario',
            '\$${dashboardService.valorInventario.toStringAsFixed(0)}',
            FontAwesomeIcons.tag,
            '+15%',
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalistMetricCard(String title, String value, IconData icon, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfo(DashboardService dashboardService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información del Negocio',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Margen Promedio',
                  '${dashboardService.margenPromedio.toStringAsFixed(1)}%',
                  FontAwesomeIcons.percent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Stock Bajo',
                  '${dashboardService.stockBajo} productos',
                  FontAwesomeIcons.triangleExclamation,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Última Venta',
                  _getLastSaleDateText(dashboardService),
                  FontAwesomeIcons.clock,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  'Estado',
                  'Activo',
                  FontAwesomeIcons.checkCircle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.textSecondary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Container(
      height: double.infinity, // Usar todo el alto disponible
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header completo de la aplicación que reemplaza el header principal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Título de IA en la parte superior
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.brain,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Análisis de IA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Pestañas de IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildAITab('Insights', true),
                const SizedBox(width: 16),
                _buildAITab('Recomendaciones', false),
              ],
            ),
          ),
          
          // Contenido de IA - Usar todo el espacio disponible
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Insights principales - Generados por IA
                  if (_isLoadingInsights)
                    _buildLoadingInsight()
                  else if (_aiInsights != null)
                    ..._buildAIInsights()
                  else
                    _buildNoDataInsight(),
                  
                  const SizedBox(height: 16),
                  
                  // Widget de análisis avanzado
                  const AdvancedAIAnalysisWidget(),
                  
                  const SizedBox(height: 12),
                  
                  // Recomendaciones de stock
                  const StockRecommendationsWidget(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }

  // Construir insights generados por IA
  List<Widget> _buildAIInsights() {
    final List<Widget> insights = [];
    
    if (_aiInsights == null) return insights;

    // Tendencia de ventas
    final salesTrend = _aiInsights!.salesTrend;
    final salesColor = _getColorFromString(salesTrend.color);
    insights.add(
      _buildDirectInsightItem(
        FontAwesomeIcons.chartLine,
        'Tendencia de Ventas',
        '${salesTrend.growthPercentage.toStringAsFixed(1)}% ${salesTrend.trend.toLowerCase()}',
        '${salesTrend.bestDay}: mejor día de ventas',
        salesColor,
      ),
    );
    insights.add(const SizedBox(height: 12));

    // Productos populares
    final popularProducts = _aiInsights!.popularProducts;
    final popularColor = _getColorFromString(popularProducts.color);
    insights.add(
      _buildDirectInsightItem(
        FontAwesomeIcons.star,
        'Productos Populares',
        popularProducts.topProduct,
        '${popularProducts.salesCount} ventas esta semana',
        popularColor,
      ),
    );
    insights.add(const SizedBox(height: 12));

    // Recomendaciones de stock
    for (final recommendation in _aiInsights!.stockRecommendations) {
      final stockColor = _getColorFromString(recommendation.color);
      final icon = _getIconFromAction(recommendation.action);
      
      insights.add(
        _buildDirectInsightItem(
          icon,
          '${recommendation.action} Stock',
          recommendation.productName,
          recommendation.details,
          stockColor,
        ),
      );
      insights.add(const SizedBox(height: 12));
    }

    return insights;
  }

  // Widget de carga
  Widget _buildLoadingInsight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Analizando datos con IA...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Widget sin datos
  Widget _buildNoDataInsight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 12),
          const Text(
            'No hay datos suficientes para análisis',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Convertir string de color a Color
  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'green': return Colors.green;
      case 'red': return Colors.red;
      case 'orange': return Colors.orange;
      case 'blue': return Colors.blue;
      case 'purple': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Obtener icono basado en la acción
  IconData _getIconFromAction(String action) {
    switch (action.toLowerCase()) {
      case 'aumentar': return FontAwesomeIcons.arrowUp;
      case 'reducir': return FontAwesomeIcons.arrowDown;
      case 'mantener': return FontAwesomeIcons.check;
      default: return FontAwesomeIcons.lightbulb;
    }
  }

  Widget _buildDirectInsightItem(IconData icon, String title, String mainInfo, String detailInfo, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainInfo,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detailInfo,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMinimalistChart(DashboardService dashboardService) {
    return Container(
      height: 150, // Altura reducida para evitar overflow
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                color: AppTheme.primaryColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text(
                'Ventas Semanales',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildModernChart(),
          ),
        ],
      ),
    );
  }




  Widget _buildModernChart() {
    return Consumer<DashboardService>(
      builder: (context, dashboardService, child) {
        // Obtener datos reales de ventas de los últimos 7 días
        final now = DateTime.now();
        final List<Map<String, dynamic>> salesData = [];
        
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayName = _getDayName(date.weekday);
          final salesCount = _getSalesForDate(date, dashboardService);
          salesData.add({
            'day': dayName,
            'count': salesCount,
            'date': date,
          });
        }
        
        final maxValue = salesData.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
        final maxHeight = maxValue > 0 ? 100.0 : 100.0;
        
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: salesData.map((data) {
              final count = data['count'] as int;
              final day = data['day'] as String;
              final height = maxValue > 0 ? (count / maxValue) * maxHeight : 0.0;
              final isToday = data['date'] == DateTime.now().subtract(const Duration(days: 0));
              
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Barra del gráfico
                      Container(
                        width: double.infinity,
                        height: height,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isToday 
                              ? [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)]
                              : [AppTheme.primaryColor.withOpacity(0.6), AppTheme.primaryColor.withOpacity(0.3)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Día de la semana
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Número de ventas
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: isToday ? AppTheme.primaryColor : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'L';
      case 2: return 'M';
      case 3: return 'X';
      case 4: return 'J';
      case 5: return 'V';
      case 6: return 'S';
      case 7: return 'D';
      default: return 'L';
    }
  }

  int _getSalesForDate(DateTime date, DashboardService dashboardService) {
    // Filtrar ventas del día específico
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return dashboardService.ventasRecientes.where((venta) {
      return venta.fecha.isAfter(startOfDay) && venta.fecha.isBefore(endOfDay);
    }).length;
  }

  String _getLastSaleDateText(DashboardService dashboardService) {
    if (dashboardService.ventasRecientes.isEmpty) {
      return 'Sin ventas';
    }
    
    final lastSale = dashboardService.ventasRecientes.first;
    final saleDate = lastSale.fecha;
    final now = DateTime.now();
    final difference = now.difference(saleDate);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return 'Hace ${(difference.inDays / 7).floor()} semanas';
    }
  }

}
