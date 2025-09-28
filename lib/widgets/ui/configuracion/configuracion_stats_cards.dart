import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/modern_card_widget.dart';
import '../../../services/ui/configuracion/configuracion_state_service.dart';

/// Widget que muestra las estadísticas de configuración en tarjetas
class ConfiguracionStatsCards extends StatelessWidget {
  const ConfiguracionStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfiguracionStateService>(
      builder: (context, stateService, child) {
        final enabledFeatures = [
          stateService.notificacionesStock,
          stateService.notificacionesVentas,
          stateService.exportarAutomatico,
          stateService.respaldoAutomatico,
        ].where((enabled) => enabled).length;
        
        return Row(
          children: [
            // Estadística: Configuraciones Activas
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Configuraciones Activas',
                  '$enabledFeatures/4',
                  FontAwesomeIcons.gear,
                  const Color(0xFF3B82F6),
                  'características habilitadas',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Margen por Defecto
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Margen por Defecto',
                  '${stateService.margenDefecto.toStringAsFixed(1)}%',
                  FontAwesomeIcons.percent,
                  const Color(0xFF10B981),
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
                  '${stateService.iva.toStringAsFixed(1)}%',
                  FontAwesomeIcons.calculator,
                  const Color(0xFFF59E0B),
                  'impuesto al valor agregado',
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




