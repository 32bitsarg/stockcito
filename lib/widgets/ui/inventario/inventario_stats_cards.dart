import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/inventario/inventario_state_service.dart';
import '../dashboard/modern_card_widget.dart';
import 'inventario_provider.dart';

/// Widget que muestra las tarjetas de estadísticas del inventario
class InventarioStatsCards extends StatelessWidget {
  const InventarioStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioStateService>(
      builder: (context, stateService, child) {
        final logicService = InventarioProvider.ofNotNull(context).logicService;
        final estadisticas = logicService.getEstadisticas();
        
        return Row(
          children: [
            // Estadística: Total Productos
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Total Productos',
                  estadisticas['totalProductos'].toString(),
                  FontAwesomeIcons.boxesStacked,
                  const Color(0xFF3B82F6),
                  'productos en inventario',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Stock Bajo
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Stock Bajo',
                  estadisticas['stockBajo'].toString(),
                  FontAwesomeIcons.exclamationTriangle,
                  const Color(0xFFF59E0B),
                  'productos con stock bajo',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Valor Total
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Valor Total',
                  '\$${estadisticas['valorTotal'].toStringAsFixed(2)}',
                  FontAwesomeIcons.dollarSign,
                  const Color(0xFF10B981),
                  'valor del inventario',
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
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
      ],
    );
  }
}

