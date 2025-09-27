import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/ui/dashboard/dashboard_state_service.dart';
import '../../../services/ui/dashboard/dashboard_navigation_service.dart';
import '../../../services/datos/dashboard_service.dart';
import 'real_stats_widget.dart';
import 'real_sales_chart_widget.dart';
import 'top_products_widget.dart';
import 'recent_activities_widget.dart';
import 'assignments_widget.dart';
import 'ml_recommendations_widget.dart';

/// Widget principal del contenido del dashboard estilo Eduplex
class ModernDashboardContentWidget extends StatelessWidget {
  final DashboardStateService stateService;
  final DashboardNavigationService navigationService;
  final VoidCallback? onNavigateToInventario;
  final Function(Map<String, dynamic> actividad)? onActivityTap;

  const ModernDashboardContentWidget({
    super.key,
    required this.stateService,
    required this.navigationService,
    this.onNavigateToInventario,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stateService.isDashboardSelected) {
      return _buildDashboardContent();
    } else {
      return _buildScreenContent();
    }
  }

  Widget _buildDashboardContent() {
    return Consumer<DashboardService>(
      builder: (context, dashboardService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda - Contenido principal
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estadísticas principales
                    RealStatsWidget(
                      totalVentas: dashboardService.totalVentas,
                      totalProductos: dashboardService.totalProductos,
                      totalClientes: dashboardService.totalClientes,
                      ventasDelMes: dashboardService.ventasDelMes,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Gráfico de ventas por día
                    RealSalesChartWidget(
                      ventasPorDia: dashboardService.ventasUltimos7Dias,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Productos populares
                    TopProductsWidget(
                      onVerTodos: onNavigateToInventario,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Actividades recientes
                    RecentActivitiesWidget(
                      onActivityTap: onActivityTap,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Columna derecha - Sidebar
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    // Recomendaciones de IA con predicciones reales
                    MLRecommendationsWidget(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScreenContent() {
    return navigationService.getScreen(stateService.selectedIndex);
  }
}
