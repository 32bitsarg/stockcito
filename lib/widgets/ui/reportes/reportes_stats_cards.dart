import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/modern_card_widget.dart';
import '../../../services/ui/reportes/reportes_state_service.dart';

/// Widget que muestra las estadísticas de reportes en tarjetas
class ReportesStatsCards extends StatelessWidget {
  const ReportesStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportesStateService>(
      builder: (context, stateService, child) {
        final productos = stateService.productos;
        final totalProductos = productos.length;
        final stockBajo = productos.where((p) => p.stock < 10).length;
        final valorTotal = productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
        
        return Row(
          children: [
            // Estadística: Total Productos
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Total Productos',
                  totalProductos.toString(),
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
                  stockBajo.toString(),
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
                  '\$${valorTotal.toStringAsFixed(2)}',
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

