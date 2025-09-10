import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../widgets/modern_sidebar.dart';
import '../widgets/modern_header.dart';
import '../widgets/animated_widgets.dart';
import '../widgets/tutorial_overlay_widget.dart';
import '../widgets/notification_banner.dart';
import '../widgets/notification_settings_widget.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
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
  
  // Claves globales para el tutorial
  final GlobalKey _welcomeKey = GlobalKey();
  final GlobalKey _metricsKey = GlobalKey();
  final GlobalKey _chartKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar datos del dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardService>().cargarDatos();
      // Inicializar servicio de notificaciones
      _initializeNotifications();
    });
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

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.bell, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Notificaciones'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              // Configuración de notificaciones
              Expanded(
                child: NotificationList(
                  notifications: NotificationService().scheduledNotifications,
                  onNotificationTap: (notification) {
                    // Manejar tap en notificación
                    Navigator.pop(context);
                  },
                  onNotificationDismiss: (notification) {
                    NotificationService().cancelNotification(notification.id);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Botón de configuración
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showNotificationSettings();
                },
                icon: const FaIcon(FontAwesomeIcons.gear, size: 16),
                label: const Text('Configurar Notificaciones'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Notificaciones'),
        content: const SizedBox(
          width: 500,
          child: NotificationSettingsWidget(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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

  void _showTutorialOverlay() {
    final tutorialSteps = [
      TutorialStep(
        title: '¡Bienvenido a Stockcito!',
        description: 'Esta es tu pantalla principal donde podrás ver un resumen completo de tu gestión de inventario y ventas.',
        icon: FontAwesomeIcons.house,
        color: AppTheme.primaryColor,
        targetKey: _welcomeKey,
      ),
      TutorialStep(
        title: 'Métricas Principales',
        description: 'Aquí puedes ver las estadísticas más importantes: productos, ventas, clientes y valor del inventario.',
        icon: FontAwesomeIcons.chartPie,
        color: AppTheme.successColor,
        targetKey: _metricsKey,
      ),
      TutorialStep(
        title: 'Gráfico de Ventas',
        description: 'Visualiza las ventas de los últimos 7 días para identificar tendencias y patrones.',
        icon: FontAwesomeIcons.chartLine,
        color: AppTheme.accentColor,
        targetKey: _chartKey,
      ),
      TutorialStep(
        title: 'Menú de Navegación',
        description: 'Usa el menú lateral para acceder a todas las funciones: calcular precios, gestionar inventario, ventas y más.',
        icon: FontAwesomeIcons.bars,
        color: AppTheme.warningColor,
        targetKey: _menuKey,
      ),
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TutorialOverlayWidget(
        steps: tutorialSteps,
        onComplete: () {},
        onSkip: () {},
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
                ModernHeader(
                  title: _menuItems[_selectedIndex]['label'],
                  subtitle: _getSubtitle(),
                  searchController: _searchController,
                  onSearch: () {
                    // Implementar búsqueda
                  },
                  actions: [
                    // Botón de notificaciones
                    IconButton(
                      onPressed: _showNotifications,
                      icon: const FaIcon(
                        FontAwesomeIcons.bell,
                        color: AppTheme.textPrimary,
                      ),
                      tooltip: 'Notificaciones',
                    ),
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
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section compacta
              AnimatedCard(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  key: _welcomeKey,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Bienvenido a Stockcito!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Administra tu emprendimiento en un solo lugar',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                AnimatedButton(
                                  text: 'Tutorial',
                                  icon: FontAwesomeIcons.graduationCap,
                                  type: ButtonType.success,
                                  delay: const Duration(milliseconds: 200),
                                  onPressed: _showTutorialOverlay,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        FontAwesomeIcons.baby,
                        size: 60,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Métricas principales en grid compacto
              Container(
                key: _metricsKey,
                child: Row(
                  children: [
                    Expanded(
                      child: AnimatedMetricCard(
                        title: 'Productos',
                        value: '${dashboardService.totalProductos}',
                        icon: FontAwesomeIcons.boxesStacked,
                        color: AppTheme.primaryColor,
                        delay: const Duration(milliseconds: 200),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedMetricCard(
                        title: 'Ventas del Mes',
                        value: '${dashboardService.ventasRecientes.length}',
                        icon: FontAwesomeIcons.arrowTrendUp,
                        color: AppTheme.successColor,
                        trend: '+12%',
                        delay: const Duration(milliseconds: 300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedMetricCard(
                        title: 'Total Clientes',
                        value: '${dashboardService.totalClientes}',
                        icon: FontAwesomeIcons.users,
                        color: AppTheme.accentColor,
                        trend: '+5%',
                        delay: const Duration(milliseconds: 400),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AnimatedMetricCard(
                        title: 'Valor Inventario',
                        value: '\$${dashboardService.valorInventario.toStringAsFixed(0)}',
                        icon: FontAwesomeIcons.tag,
                        color: AppTheme.secondaryColor,
                        delay: const Duration(milliseconds: 500),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sección de Información del Negocio
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del Negocio - Columna izquierda
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información del Negocio',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildInfoCard(
                                    'Margen Promedio',
                                    '${dashboardService.margenPromedio.toStringAsFixed(1)}%',
                                    FontAwesomeIcons.percent,
                                    AppTheme.warningColor,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoCard(
                                    'Stock Bajo',
                                    '${dashboardService.stockBajo} productos',
                                    FontAwesomeIcons.triangleExclamation,
                                    AppTheme.errorColor,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoCard(
                                    'Productos Activos',
                                    '${dashboardService.totalProductos} en catálogo',
                                    FontAwesomeIcons.list,
                                    AppTheme.accentColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Consumer<DashboardService>(
                                    builder: (context, dashboardService, child) {
                                      return _buildInfoCard(
                                        'Última Venta',
                                        _getLastSaleDateText(dashboardService),
                                        FontAwesomeIcons.clock,
                                        AppTheme.successColor,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Gráfico de ventas - Columna derecha
                    Expanded(
                      flex: 2,
                      child: AnimatedCard(
                        delay: const Duration(milliseconds: 600),
                        child: Container(
                          key: _chartKey,
                          height: 200,
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
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Ventas Recientes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.successColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Últimos 7 días',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.successColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: _buildSalesChart(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildInfoCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSalesChart() {
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
        final maxHeight = maxValue > 0 ? 80.0 : 80.0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: salesData.map((data) {
            final count = data['count'] as int;
            final day = data['day'] as String;
            final height = maxValue > 0 ? (count / maxValue) * maxHeight : 0.0;
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 20,
                  height: height,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (count > 0)
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            );
          }).toList(),
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
