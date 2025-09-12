import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Gráfico de barras horizontales minimalista para ventas
class DashboardBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> ventasUltimos7Dias;

  const DashboardBarChart({
    super.key,
    required this.ventasUltimos7Dias,
  });

  @override
  Widget build(BuildContext context) {
    // Usar datos reales directamente - siempre mostrar el gráfico
    return _buildBarChart(ventasUltimos7Dias);
  }


  Widget _buildBarChart(List<Map<String, dynamic>> ventasPorDia) {
    final now = DateTime.now();
    
    // Si no hay datos, crear datos vacíos para los últimos 7 días
    if (ventasPorDia.isEmpty) {
      ventasPorDia = _generateEmptyData();
    }
    
    // Calcular el máximo, pero si todos son 0, usar 1 para evitar división por 0
    final maxVenta = ventasPorDia.map((v) => v['total'] as double).reduce((a, b) => a > b ? a : b);
    final maxVentaForDisplay = maxVenta > 0 ? maxVenta : 1.0;

    return Container(
      width: 400, // Ancho fijo para el layout horizontal
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del gráfico
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  FontAwesomeIcons.chartBar,
                  color: Colors.grey.shade300,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ventas por Día',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade200,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '7 días',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Gráfico de barras horizontales - Ocupando todo el espacio restante
          Expanded(
            child: ListView.builder(
              itemCount: ventasPorDia.length,
              itemBuilder: (context, index) {
                final venta = ventasPorDia[index];
                final fecha = DateTime.parse(venta['fecha']);
                final isToday = fecha.day == now.day && fecha.month == now.month;
                final dayName = _getDayName(fecha.weekday);
                final percentage = (venta['total'] as double) / maxVentaForDisplay;
                
                return _buildBarItem(
                  dayName,
                  venta['total'] as double,
                  percentage,
                  isToday,
                  index,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(String dayName, double value, double percentage, bool isToday, int index) {
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
    ];
    
    final color = colors[index % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20), // Aumentado para mejor distribución
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del día
          Row(
            children: [
              Container(
                width: 24, // Aumentado para mejor visibilidad
                height: 24,
                decoration: BoxDecoration(
                  color: isToday ? color : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    dayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11, // Aumentado
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getFullDayName(dayName),
                style: TextStyle(
                  fontSize: 13, // Aumentado
                  color: isToday ? Colors.white : Colors.grey.shade300,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '\$${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 13, // Aumentado
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Aumentado
          
          // Barra de progreso más gruesa
          Container(
            height: 12, // Aumentado de 8 a 12
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(6),
            ),
            child: value > 0 
              ? FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '0',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }


  // Generar datos vacíos para los últimos 7 días
  List<Map<String, dynamic>> _generateEmptyData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> emptyData = [];
    
    for (int i = 6; i >= 0; i--) {
      final fecha = now.subtract(Duration(days: i));
      emptyData.add({
        'fecha': fecha.toIso8601String().split('T')[0],
        'total': 0.0,
      });
    }
    
    return emptyData;
  }

  // Obtener nombre corto del día
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'L';
      case 2: return 'M';
      case 3: return 'X';
      case 4: return 'J';
      case 5: return 'V';
      case 6: return 'S';
      case 7: return 'D';
      default: return '';
    }
  }

  // Obtener nombre completo del día
  String _getFullDayName(String shortName) {
    switch (shortName) {
      case 'L': return 'Lunes';
      case 'M': return 'Martes';
      case 'X': return 'Miércoles';
      case 'J': return 'Jueves';
      case 'V': return 'Viernes';
      case 'S': return 'Sábado';
      case 'D': return 'Domingo';
      default: return '';
    }
  }
}
