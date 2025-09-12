import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../services/datos/dashboard_service.dart';

/// Versión híbrida del DashboardStatsGrid - 2 filas compactas
class DashboardStatsHybrid extends StatelessWidget {
  final DashboardService dashboardService;

  const DashboardStatsHybrid({
    super.key,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160, // Aumentado de 120 a 160 para más espacio
      child: dashboardService.isLoading 
        ? _buildLoadingState()
        : GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2, // Reducido para aprovechar más altura
        children: [
          _buildStatCard(
            'Ventas Totales',
            '\$${dashboardService.totalVentas}',
            FontAwesomeIcons.dollarSign,
            AppTheme.successColor,
          ),
          _buildStatCard(
            'Productos',
            dashboardService.totalProductos.toString(),
            FontAwesomeIcons.boxesStacked,
            AppTheme.primaryColor,
          ),
          _buildStatCard(
            'Clientes',
            dashboardService.totalClientes.toString(),
            FontAwesomeIcons.users,
            AppTheme.accentColor,
          ),
          _buildStatCard(
            'Ventas del Mes',
            '\$${dashboardService.ventasDelMes.toStringAsFixed(0)}',
            FontAwesomeIcons.calendar,
            AppTheme.warningColor,
          ),
          _buildStatCard(
            'Valor Inventario',
            '\$${dashboardService.valorInventario.toStringAsFixed(0)}',
            FontAwesomeIcons.warehouse,
            AppTheme.primaryColor,
          ),
          _buildStatCard(
            'Margen Promedio',
            '${dashboardService.margenPromedio.toStringAsFixed(1)}%',
            FontAwesomeIcons.percent,
            AppTheme.successColor,
          ),
          _buildStatCard(
            'Stock Bajo',
            dashboardService.stockBajo.toString(),
            FontAwesomeIcons.exclamationTriangle,
            AppTheme.errorColor,
          ),
          _buildStatCard(
            'Ventas Recientes',
            dashboardService.ventasRecientes.length.toString(),
            FontAwesomeIcons.clock,
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 8),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: Colors.grey.shade700, 
                  size: 18,
                ),
              ),
              const Spacer(),
              Icon(
                FontAwesomeIcons.arrowUpRightFromSquare,
                color: Colors.grey.shade400,
                size: 12,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
