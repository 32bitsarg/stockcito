import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/datos/dashboard_service.dart';

/// Versión minimalista del DashboardStats con datos reales y fallback
class DashboardStatsMinimal extends StatelessWidget {
  final DashboardService dashboardService;

  const DashboardStatsMinimal({
    super.key,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      child: dashboardService.isLoading 
        ? _buildLoadingState()
        : GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.2,
        children: [
          _buildStatCard(
            'Ventas Totales',
            _getFormattedValue(dashboardService.totalVentas.toDouble(), '\$'),
            FontAwesomeIcons.dollarSign,
          ),
          _buildStatCard(
            'Productos',
            dashboardService.totalProductos.toString(),
            FontAwesomeIcons.boxesStacked,
          ),
          _buildStatCard(
            'Clientes',
            dashboardService.totalClientes.toString(),
            FontAwesomeIcons.users,
          ),
          _buildStatCard(
            'Ventas del Mes',
            _getFormattedValue(dashboardService.ventasDelMes, '\$'),
            FontAwesomeIcons.calendar,
          ),
          _buildStatCard(
            'Valor Inventario',
            _getFormattedValue(dashboardService.valorInventario, '\$'),
            FontAwesomeIcons.warehouse,
          ),
          _buildStatCard(
            'Margen Promedio',
            '${dashboardService.margenPromedio.toStringAsFixed(1)}%',
            FontAwesomeIcons.percent,
          ),
          _buildStatCard(
            'Stock Bajo',
            dashboardService.stockBajo.toString(),
            FontAwesomeIcons.exclamationTriangle,
          ),
          _buildStatCard(
            'Ventas Recientes',
            dashboardService.ventasRecientes.length.toString(),
            FontAwesomeIcons.clock,
          ),
        ],
      ),
    );
  }

  String _getFormattedValue(double value, String prefix) {
    if (value == 0) {
      return 'Sin datos';
    }
    return '$prefix${value.toStringAsFixed(0)}';
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
          SizedBox(height: 12),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    final isEmpty = value == 'Sin datos' || value == '0';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty ? Colors.grey.shade200 : Colors.grey.shade300,
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
                  color: isEmpty ? Colors.grey.shade100 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: isEmpty ? Colors.grey.shade400 : Colors.grey.shade700, 
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isEmpty ? Colors.grey.shade400 : Colors.black87,
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
