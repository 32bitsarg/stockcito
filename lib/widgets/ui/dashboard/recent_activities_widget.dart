import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';
import '../../../services/datos/dashboard_service.dart';

/// Widget para actividades recientes
class RecentActivitiesWidget extends StatefulWidget {
  final Function(Map<String, dynamic> actividad)? onActivityTap;
  
  const RecentActivitiesWidget({
    super.key,
    this.onActivityTap,
  });

  @override
  State<RecentActivitiesWidget> createState() => _RecentActivitiesWidgetState();
}

class _RecentActivitiesWidgetState extends State<RecentActivitiesWidget> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _actividades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    try {
      final actividades = await _dashboardService.getActividadesRecientes(limit: 5);
      setState(() {
        _actividades = actividades;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Actividades Recientes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contenido
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_actividades.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay actividades recientes',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            // Lista de actividades
            ..._actividades.map((actividad) => _buildActivityItem(actividad)).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> actividad) {
    final icon = actividad['icono'] as IconData? ?? FontAwesomeIcons.bell;
    final color = actividad['color'] as Color? ?? const Color(0xFF6B7280);
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => widget.onActivityTap?.call(actividad),
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.grey.withOpacity(0.1),
        splashColor: Colors.grey.withOpacity(0.2),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.transparent,
          ),
          child: Row(
        children: [
          // Icono de la actividad
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Contenido de la actividad
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actividad['descripcion'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  actividad['fecha'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Flecha
          const Icon(
            FontAwesomeIcons.chevronRight,
            size: 12,
            color: Color(0xFF6B7280),
          ),
        ],
          ),
        ),
      ),
    );
  }
}
