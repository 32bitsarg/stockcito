import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Gráfico circular minimalista para ventas
class DashboardCircularChart extends StatelessWidget {
  final double ventasDelMes;

  const DashboardCircularChart({
    super.key,
    required this.ventasDelMes,
  });

  @override
  Widget build(BuildContext context) {
    final ventasPorDia = _generateVentasPorDia(ventasDelMes);
    
    if (ventasPorDia.isEmpty || ventasDelMes == 0) {
      return _buildEmptyChart();
    }

    return _buildCircularChart(ventasPorDia);
  }

  Widget _buildEmptyChart() {
    return Container(
      width: 300,
      height: 300,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                FontAwesomeIcons.chartPie,
                color: Colors.grey.shade300,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos',
              style: TextStyle(
                color: Colors.grey.shade300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularChart(List<Map<String, dynamic>> ventasPorDia) {
    final totalVentas = ventasPorDia.map((v) => v['total'] as double).reduce((a, b) => a + b);
    final now = DateTime.now();

    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade900, // Fondo oscuro como en la imagen
        borderRadius: BorderRadius.circular(16), // Bordes redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gráfico circular
          Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: CircularChartPainter(
                  data: ventasPorDia,
                  totalVentas: totalVentas,
                  now: now,
                ),
              ),
            ),
          ),
          
          // Información central
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ventas',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${totalVentas.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '7 días',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
        'dayName': _getDayName(fecha.weekday),
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

/// Custom painter para dibujar el gráfico circular
class CircularChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double totalVentas;
  final DateTime now;

  CircularChartPainter({
    required this.data,
    required this.totalVentas,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || totalVentas == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Colores vibrantes como en la imagen
    final colors = [
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Emerald
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEF4444), // Red
    ];

    double startAngle = -90 * (3.14159 / 180); // Empezar desde arriba

    for (int i = 0; i < data.length; i++) {
      final venta = data[i]['total'] as double;
      final sweepAngle = (venta / totalVentas) * 2 * 3.14159;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      // Dibujar arco
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Dibujar borde del arco
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Dibujar círculo central
    final centerPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.4, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
