import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../services/datos/dashboard_service.dart';

class DashboardStatsGrid extends StatelessWidget {
  final DashboardService dashboardService;

  const DashboardStatsGrid({
    super.key,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el número de columnas basado en el ancho disponible
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                              constraints.maxWidth > 800 ? 3 : 2;
        
        // Calcular la altura máxima disponible para evitar overflow
        final availableHeight = constraints.maxHeight;
        final childAspectRatio = availableHeight > 200 ? 3.5 : 4.0; // Más compacto
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
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
    );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8), // Más compacto: de 12 a 8
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, // Reducido de 10 a 8
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribuir espacio uniformemente
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16), // Más pequeño: de 18 a 16
              const Spacer(),
              Icon(
                FontAwesomeIcons.arrowUpRightFromSquare,
                color: Colors.grey.shade400,
                size: 8, // Más pequeño: de 10 a 8
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14, // Más pequeño: de 16 a 14
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10, // Más pequeño: de 11 a 10
                  color: AppTheme.textSecondary,
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
