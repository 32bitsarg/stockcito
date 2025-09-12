import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/datos/dashboard_service.dart';

/// Widget único y simple para las estadísticas del dashboard
class DashboardStats extends StatelessWidget {
  final DashboardService dashboardService;

  const DashboardStats({
    super.key,
    required this.dashboardService,
  });

  @override
  Widget build(BuildContext context) {
    return dashboardService.isLoading 
        ? _buildLoadingState()
        : LayoutBuilder(
          builder: (context, constraints) {
            // Layout simplificado con Wrap y tamaños fijos
            
            return SingleChildScrollView(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
          _buildStatCard(
            'Ventas Totales',
            '\$${dashboardService.totalVentas}',
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
            '\$${dashboardService.ventasDelMes.toStringAsFixed(0)}',
            FontAwesomeIcons.calendar,
          ),
          _buildStatCard(
            'Valor Inventario',
            '\$${dashboardService.valorInventario.toStringAsFixed(0)}',
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
          },
        );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cargando estadísticas...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 180, // Ancho fijo para consistencia
      height: 120, // Altura fija para evitar overflow
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono centrado arriba
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.grey.shade700,
                size: 16,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Valor principal
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade900,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 4),
            
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
