import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/modern_card_widget.dart';
import '../../../services/ui/ventas/ventas_state_service.dart';
import '../../../services/ui/ventas/ventas_logic_service.dart';
import '../../../screens/ventas_screen/functions/ventas_functions.dart';

/// Widget que muestra las estadísticas de ventas en tarjetas
class VentasStatsCards extends StatelessWidget {
  const VentasStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VentasStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<VentasLogicService>(context, listen: false);
        final estadisticas = logicService.getEstadisticas();
        
        return Row(
          children: [
            // Estadística: Total Ventas
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Total Ventas',
                  VentasFunctions.formatPrecio(estadisticas['totalVentas']),
                  FontAwesomeIcons.dollarSign,
                  const Color(0xFF10B981),
                  'ingresos totales',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Número de Ventas
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Número de Ventas',
                  estadisticas['numeroVentas'].toString(),
                  FontAwesomeIcons.cartShopping,
                  const Color(0xFF3B82F6),
                  'ventas realizadas',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Promedio de Ventas
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Promedio de Ventas',
                  VentasFunctions.formatPrecio(estadisticas['promedioVentas']),
                  FontAwesomeIcons.chartLine,
                  const Color(0xFF8B5CF6),
                  'promedio por venta',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icono y título
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Valor
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Subtítulo
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}
