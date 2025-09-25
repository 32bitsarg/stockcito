import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget para mostrar mini gráficos de tendencias
class MiniChartWidget extends StatelessWidget {
  final List<double> data;
  final Color color;
  final String title;
  final double? maxValue;
  final double? minValue;
  final bool showTrend;
  final bool showValues;

  const MiniChartWidget({
    super.key,
    required this.data,
    required this.color,
    required this.title,
    this.maxValue,
    this.minValue,
    this.showTrend = true,
    this.showValues = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    final chartData = _normalizeData(data);
    final trend = _calculateTrend(chartData);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (showTrend) _buildTrendIndicator(trend),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: CustomPaint(
              painter: MiniChartPainter(
                data: chartData,
                color: color,
                showValues: showValues,
              ),
              size: const Size(double.infinity, 40),
            ),
          ),
          if (showValues) ...[
            const SizedBox(height: 4),
            _buildValueLabels(data),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: const Center(
        child: Text(
          'Sin datos',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(double trend) {
    IconData icon;
    Color trendColor;
    String text;

    if (trend > 0.1) {
      icon = Icons.trending_up;
      trendColor = Colors.green;
      text = '↗';
    } else if (trend < -0.1) {
      icon = Icons.trending_down;
      trendColor = Colors.red;
      text = '↘';
    } else {
      icon = Icons.trending_flat;
      trendColor = Colors.orange;
      text = '→';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: trendColor),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: trendColor,
          ),
        ),
      ],
    );
  }

  Widget _buildValueLabels(List<double> data) {
    if (data.length < 2) return const SizedBox.shrink();

    final firstValue = data.first;
    final lastValue = data.last;
    final change = lastValue - firstValue;
    final changePercent = firstValue != 0 ? (change / firstValue) * 100 : 0.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Inicio: ${firstValue.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
        Text(
          'Final: ${lastValue.toStringAsFixed(1)}',
          style: const TextStyle(fontSize: 9, color: Colors.grey),
        ),
        Text(
          '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 9,
            color: changePercent >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<double> _normalizeData(List<double> data) {
    if (data.isEmpty) return [];

    final min = minValue ?? data.reduce(math.min);
    final max = maxValue ?? data.reduce(math.max);
    final range = max - min;

    if (range == 0) return List.filled(data.length, 0.5);

    return data.map((value) => (value - min) / range).toList();
  }

  double _calculateTrend(List<double> normalizedData) {
    if (normalizedData.length < 2) return 0.0;

    final first = normalizedData.first;
    final last = normalizedData.last;
    return last - first;
  }
}

/// Painter personalizado para dibujar el mini gráfico
class MiniChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool showValues;

  MiniChartPainter({
    required this.data,
    required this.color,
    this.showValues = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] * size.height);
      points.add(Offset(x, y));
    }

    // Crear línea del gráfico
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // Crear área rellena
    fillPath.addPath(path, Offset.zero);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    // Dibujar área rellena
    canvas.drawPath(fillPath, fillPaint);

    // Dibujar línea
    canvas.drawPath(path, paint);

    // Dibujar puntos
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 2, pointPaint);
    }

    // Dibujar valores si está habilitado
    if (showValues) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      for (int i = 0; i < points.length; i++) {
        final value = data[i];
        textPainter.text = TextSpan(
          text: value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 8,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            points[i].dx - textPainter.width / 2,
            points[i].dy - 12,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
