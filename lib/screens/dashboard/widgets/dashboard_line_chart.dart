import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Gráfico de líneas minimalista y profesional para ventas
class DashboardLineChart extends StatelessWidget {
  final double ventasDelMes;

  const DashboardLineChart({
    super.key,
    required this.ventasDelMes,
  });

  @override
  Widget build(BuildContext context) {
    final ventasPorDia = _generateVentasPorDia(ventasDelMes);
    
    if (ventasPorDia.isEmpty) {
      return _buildEmptyChart();
    }

    return _buildLineChart(ventasPorDia);
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Fondo flat minimalista
        borderRadius: BorderRadius.circular(12), // Bordes más suaves
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                FontAwesomeIcons.chartLine,
                color: Colors.grey.shade600,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos de ventas',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> ventasPorDia) {
    final maxVenta = ventasPorDia.map((v) => v['total'] as double).reduce((a, b) => a > b ? a : b);
    final minVenta = ventasPorDia.map((v) => v['total'] as double).reduce((a, b) => a < b ? a : b);
    final now = DateTime.now();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50, // Fondo flat de contraste
        borderRadius: BorderRadius.circular(12), // Bordes más suaves
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del gráfico - Flat design
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  FontAwesomeIcons.chartLine,
                  color: Colors.grey.shade700,
                  size: 14,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Ventas por Día',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '7 días',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Gráfico de líneas
          Expanded(
            child: CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: LineChartPainter(
                data: ventasPorDia,
                maxValue: maxVenta,
                minValue: minVenta,
                now: now,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Leyenda de días - Flat design
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ventasPorDia.map((venta) {
                final fecha = DateTime.parse(venta['fecha']);
                final isToday = fecha.day == now.day && fecha.month == now.month;
                final day = _getDayName(fecha.weekday);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.grey.shade200 : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday ? Colors.grey.shade800 : Colors.grey.shade600,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${venta['total'].toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Generar datos simulados de ventas por día
  List<Map<String, dynamic>> _generateVentasPorDia(double ventasMes) {
    final now = DateTime.now();
    final List<Map<String, dynamic>> ventasPorDia = [];
    final ventasSemana = ventasMes * 0.25; // 25% del mes
    
    for (int i = 6; i >= 0; i--) {
      final fecha = now.subtract(Duration(days: i));
      final factor = _getDayFactor(fecha.weekday);
      final total = (ventasSemana * factor).roundToDouble();
      
      ventasPorDia.add({
        'fecha': fecha.toIso8601String().split('T')[0],
        'total': total,
      });
    }
    
    return ventasPorDia;
  }

  // Obtener factor de ventas por día de la semana
  double _getDayFactor(int weekday) {
    switch (weekday) {
      case 1: return 0.12; // Lunes
      case 2: return 0.15; // Martes
      case 3: return 0.18; // Miércoles
      case 4: return 0.20; // Jueves
      case 5: return 0.22; // Viernes
      case 6: return 0.08; // Sábado
      case 7: return 0.05; // Domingo
      default: return 0.10;
    }
  }

  // Obtener nombre del día
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
}

/// Custom painter para dibujar el gráfico de líneas
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxValue;
  final double minValue;
  final DateTime now;

  LineChartPainter({
    required this.data,
    required this.maxValue,
    required this.minValue,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // Calcular puntos
    final points = <Offset>[];
    final double stepX = size.width / (data.length - 1);
    final double range = maxValue - minValue;
    final double stepY = range > 0 ? size.height / range : size.height;

    for (int i = 0; i < data.length; i++) {
      final value = data[i]['total'] as double;
      final x = i * stepX;
      final y = size.height - ((value - minValue) * stepY);
      points.add(Offset(x, y));
    }

    // Dibujar líneas de fondo
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Dibujar línea principal
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        final current = points[i];
        final previous = points[i - 1];
        
        // Curva suave
        final controlPoint1 = Offset(
          previous.dx + (current.dx - previous.dx) / 3,
          previous.dy,
        );
        final controlPoint2 = Offset(
          current.dx - (current.dx - previous.dx) / 3,
          current.dy,
        );
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          current.dx, current.dy,
        );
      }
      
      canvas.drawPath(path, linePaint);
    }

    // Dibujar puntos - Flat design
    for (final point in points) {
      // Círculo exterior
      canvas.drawCircle(point, 4, Paint()..color = Colors.grey.shade50);
      // Círculo interior
      canvas.drawCircle(point, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
