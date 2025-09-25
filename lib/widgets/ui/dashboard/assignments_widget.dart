import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';

/// Widget para lista de tareas estilo Eduplex
class AssignmentsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> assignments;

  const AssignmentsWidget({
    super.key,
    required this.assignments,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y botón de agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recomendaciones IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.robot,
                  size: 12,
                  color: Color(0xFF00FF88),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de tareas
          ...assignments.map((assignment) => _buildAssignmentItem(assignment)).toList(),
        ],
      ),
    );
  }

  Widget _buildAssignmentItem(Map<String, dynamic> assignment) {
    final status = assignment['status'] as String;
    Color statusColor;
    Color statusBgColor;
    
    switch (status.toLowerCase()) {
      case 'nueva':
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFF59E0B).withOpacity(0.1);
        break;
      case 'importante':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFF10B981).withOpacity(0.1);
        break;
      case 'urgente':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFEF4444).withOpacity(0.1);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusBgColor = const Color(0xFF6B7280).withOpacity(0.1);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icono de la tarea
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (assignment['iconColor'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              assignment['icon'] as IconData,
              color: assignment['iconColor'] as Color,
              size: 16,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Contenido de la tarea
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  assignment['dateTime'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
