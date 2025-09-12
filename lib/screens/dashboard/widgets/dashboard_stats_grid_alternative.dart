import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../services/datos/dashboard_service.dart';

/// Versión alternativa del DashboardStatsGrid que usa Wrap para mejor control del espacio
class DashboardStatsGridAlternative extends StatelessWidget {
  final DashboardService dashboardService;

  const DashboardStatsGridAlternative({
    super.key,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular el ancho de cada tarjeta basado en el espacio disponible
        final cardWidth = (constraints.maxWidth - 48) / 4; // 48 = 3 * 16 (espacios)
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              'Ventas Totales',
              '\$${dashboardService.totalVentas}',
              FontAwesomeIcons.dollarSign,
              AppTheme.successColor,
              cardWidth,
            ),
            _buildStatCard(
              'Productos',
              dashboardService.totalProductos.toString(),
              FontAwesomeIcons.boxesStacked,
              AppTheme.primaryColor,
              cardWidth,
            ),
            _buildStatCard(
              'Clientes',
              dashboardService.totalClientes.toString(),
              FontAwesomeIcons.users,
              AppTheme.accentColor,
              cardWidth,
            ),
            _buildStatCard(
              'Ventas del Mes',
              '\$${dashboardService.ventasDelMes.toStringAsFixed(0)}',
              FontAwesomeIcons.calendar,
              AppTheme.warningColor,
              cardWidth,
            ),
            _buildStatCard(
              'Valor Inventario',
              '\$${dashboardService.valorInventario.toStringAsFixed(0)}',
              FontAwesomeIcons.warehouse,
              AppTheme.primaryColor,
              cardWidth,
            ),
            _buildStatCard(
              'Margen Promedio',
              '${dashboardService.margenPromedio.toStringAsFixed(1)}%',
              FontAwesomeIcons.percent,
              AppTheme.successColor,
              cardWidth,
            ),
            _buildStatCard(
              'Stock Bajo',
              dashboardService.stockBajo.toString(),
              FontAwesomeIcons.exclamationTriangle,
              AppTheme.errorColor,
              cardWidth,
            ),
            _buildStatCard(
              'Ventas Recientes',
              dashboardService.ventasRecientes.length.toString(),
              FontAwesomeIcons.clock,
              AppTheme.primaryColor,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, double width) {
    return SizedBox(
      width: width,
      height: 120, // Altura fija para evitar problemas de overflow
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
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
                Icon(icon, color: color, size: 18),
                const Spacer(),
                Icon(
                  FontAwesomeIcons.arrowUpRightFromSquare,
                  color: Colors.grey.shade400,
                  size: 10,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
