import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';
import '../../../services/datos/dashboard_service.dart';

/// Widget para estadísticas reales del dashboard
class RealStatsWidget extends StatefulWidget {
  final int totalVentas;
  final int totalProductos;
  final int totalClientes;
  final double ventasDelMes;

  const RealStatsWidget({
    super.key,
    required this.totalVentas,
    required this.totalProductos,
    required this.totalClientes,
    required this.ventasDelMes,
  });

  @override
  State<RealStatsWidget> createState() => _RealStatsWidgetState();
}

class _RealStatsWidgetState extends State<RealStatsWidget> {
  final DashboardService _dashboardService = DashboardService();
  double _totalVentasMonto = 0.0;
  bool _isLoadingMonto = true;

  @override
  void initState() {
    super.initState();
    _cargarTotalVentasMonto();
  }

  Future<void> _cargarTotalVentasMonto() async {
    try {
      final monto = await _dashboardService.getTotalVentasMonto();
      if (!mounted) return;
      setState(() {
        _totalVentasMonto = monto;
        _isLoadingMonto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMonto = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Estadísticas principales en fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ventas Totales',
                _isLoadingMonto 
                    ? 'Cargando...' 
                    : '\$${_totalVentasMonto.toStringAsFixed(2)}',
                FontAwesomeIcons.dollarSign,
                const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Productos',
                widget.totalProductos.toString(),
                FontAwesomeIcons.boxesStacked,
                const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Clientes',
                widget.totalClientes.toString(),
                FontAwesomeIcons.users,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Ventas del mes (tarjeta más grande)
        _buildLargeStatCard(
          'Ventas del Mes',
          '\$${widget.ventasDelMes.toStringAsFixed(0)}',
          FontAwesomeIcons.chartLine,
          const Color(0xFF00FF88),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Icon(
                FontAwesomeIcons.arrowUp,
                size: 12,
                color: color.withOpacity(0.6),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStatCard(String title, String value, IconData icon, Color color) {
    return ModernCardWidget(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          Icon(
            FontAwesomeIcons.arrowUp,
            size: 16,
            color: color.withOpacity(0.6),
          ),
        ],
      ),
    );
  }
}
