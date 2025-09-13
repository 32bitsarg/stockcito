import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class ReportesMetricas extends StatelessWidget {
  final int totalProductos;
  final double valorTotalInventario;
  final int stockBajo;
  final double margenPromedio;

  const ReportesMetricas({
    super.key,
    required this.totalProductos,
    required this.valorTotalInventario,
    required this.stockBajo,
    required this.margenPromedio,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricaCard(
            context,
            'Total Productos',
            totalProductos.toString(),
            Icons.inventory,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            context,
            'Valor Inventario',
            '\$${valorTotalInventario.toStringAsFixed(0)}',
            Icons.attach_money,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            context,
            'Stock Bajo',
            stockBajo.toString(),
            Icons.warning,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            context,
            'Margen Promedio',
            '${margenPromedio.toStringAsFixed(1)}%',
            Icons.trending_up,
            AppTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
