import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';

/// Widget para gráfico de ventas reales por día
class RealSalesChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> ventasPorDia;

  const RealSalesChartWidget({
    super.key,
    required this.ventasPorDia,
  });

  String _formatearDia(String? fecha) {
    if (fecha == null) return 'N/A';
    
    try {
      final fechaObj = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaObj).inDays;
      
      if (diferencia == 0) {
        return 'Hoy';
      } else if (diferencia == 1) {
        return 'Ayer';
      } else {
        // Mostrar día de la semana
        final diasSemana = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
        return diasSemana[fechaObj.weekday % 7];
      }
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ventas por Día',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '7 días',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00FF88),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Gráfico de barras
          SizedBox(
            height: 140,
            child: ventasPorDia.isEmpty 
                ? const Center(
                    child: Text(
                      'No hay datos de ventas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: ventasPorDia.map((venta) {
                final total = (venta['total'] as double?) ?? 0.0;
                final maxVenta = ventasPorDia.isEmpty ? 0.0 : ventasPorDia.map((v) => (v['total'] as double?) ?? 0.0).reduce((a, b) => a > b ? a : b);
                final height = maxVenta > 0 ? (total / maxVenta) : 0.0;
                final isMax = total == maxVenta && total > 0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tooltip
                    if (isMax)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D2D2D),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '\$${total.round()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Barra
                    Container(
                      width: 24,
                      height: height * 70,
                      decoration: BoxDecoration(
                        color: isMax ? const Color(0xFF00FF88) : const Color(0xFF00FF88).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Etiqueta del día
                    Text(
                      _formatearDia(venta['fecha'] as String?),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                );
              }).toList(),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Resumen
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartLine,
                size: 12,
                color: const Color(0xFF00FF88),
              ),
              const SizedBox(width: 8),
              Text(
                'Total: \$${ventasPorDia.isEmpty ? '0' : ventasPorDia.map((v) => (v['total'] as double?) ?? 0.0).reduce((a, b) => a + b).round()}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF00FF88),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
