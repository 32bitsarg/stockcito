import 'package:flutter/material.dart';

/// Widget para mostrar indicadores de progreso personalizados
class ProgressIndicatorsWidget extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Color color;
  final String? unit;
  final bool showPercentage;
  final bool showValue;
  final double height;

  const ProgressIndicatorsWidget({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.unit,
    this.showPercentage = true,
    this.showValue = true,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final displayValue = showValue ? value : null;
    final displayUnit = unit ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (showPercentage)
                Text(
                  '${(percentage * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              Container(
                height: height,
                width: MediaQuery.of(context).size.width * percentage * 0.8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ],
          ),
          if (displayValue != null) ...[
            const SizedBox(height: 4),
            Text(
              '${displayValue.toStringAsFixed(1)}$displayUnit',
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget para indicador de progreso circular
class CircularProgressIndicatorWidget extends StatelessWidget {
  final double value;
  final double maxValue;
  final String label;
  final Color color;
  final double size;
  final bool showValue;
  final String? unit;

  const CircularProgressIndicatorWidget({
    super.key,
    required this.value,
    required this.maxValue,
    required this.label,
    required this.color,
    this.size = 60.0,
    this.showValue = true,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final displayValue = showValue ? value : null;
    final displayUnit = unit ?? '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: percentage,
                  strokeWidth: 6,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (displayValue != null)
                        Text(
                          '${displayValue.toStringAsFixed(1)}$displayUnit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para indicador de estado con iconos
class StatusIndicatorWidget extends StatelessWidget {
  final String label;
  final String status;
  final Color color;
  final IconData icon;
  final String? description;

  const StatusIndicatorWidget({
    super.key,
    required this.label,
    required this.status,
    required this.color,
    required this.icon,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withOpacity(0.8),
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: TextStyle(
                      fontSize: 9,
                      color: color.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para indicador de tendencia con flecha
class TrendIndicatorWidget extends StatelessWidget {
  final String label;
  final double value;
  final double previousValue;
  final String unit;
  final Color positiveColor;
  final Color negativeColor;

  const TrendIndicatorWidget({
    super.key,
    required this.label,
    required this.value,
    required this.previousValue,
    required this.unit,
    this.positiveColor = Colors.green,
    this.negativeColor = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    final change = value - previousValue;
    final changePercent = previousValue != 0 ? (change / previousValue) * 100 : 0.0;
    
    final isPositive = change >= 0;
    final color = isPositive ? positiveColor : negativeColor;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final arrow = isPositive ? '↗' : '↘';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$arrow ${changePercent.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
