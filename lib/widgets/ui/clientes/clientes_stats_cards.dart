import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../dashboard/modern_card_widget.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';

/// Widget que muestra las estadísticas de clientes en tarjetas
class ClientesStatsCards extends StatelessWidget {
  const ClientesStatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientesStateService>(
      builder: (context, stateService, child) {
        final estadisticas = stateService.getEstadisticas();
        
        return Row(
          children: [
            // Estadística: Total Clientes
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Total Clientes',
                  estadisticas['totalClientes'].toString(),
                  FontAwesomeIcons.users,
                  const Color(0xFF3B82F6),
                  'clientes registrados',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Con Email
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Con Email',
                  estadisticas['conEmail'].toString(),
                  FontAwesomeIcons.envelope,
                  const Color(0xFF10B981),
                  'clientes con email',
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Estadística: Con Teléfono
            Expanded(
              child: ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: _buildStatItem(
                  'Con Teléfono',
                  estadisticas['conTelefono'].toString(),
                  FontAwesomeIcons.phone,
                  const Color(0xFF8B5CF6),
                  'clientes con teléfono',
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
