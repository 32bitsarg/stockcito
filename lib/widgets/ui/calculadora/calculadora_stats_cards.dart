import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/modern_card_widget.dart';
import '../../../services/ui/calculadora/calculadora_state_service.dart';

/// Widget que muestra las estadísticas de calculadora en tarjetas
class CalculadoraStatsCards extends StatelessWidget {
  const CalculadoraStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalculadoraStateService>(
      builder: (context, stateService, child) {
        final config = stateService.config;
        final precioVenta = stateService.precioVenta;
        
        return Row(
          children: [
            // Estadística: Margen Configurado
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Margen Configurado',
                  '${config.margenGananciaDefault.toStringAsFixed(1)}%',
                  FontAwesomeIcons.percent,
                  const Color(0xFF3B82F6),
                  'margen de ganancia',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: IVA Configurado
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'IVA Configurado',
                  '${config.ivaDefault.toStringAsFixed(1)}%',
                  FontAwesomeIcons.calculator,
                  const Color(0xFF10B981),
                  'impuesto al valor agregado',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Precio de Venta
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Precio de Venta',
                  '\$${precioVenta.toStringAsFixed(2)}',
                  FontAwesomeIcons.dollarSign,
                  const Color(0xFFF59E0B),
                  'precio calculado',
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
