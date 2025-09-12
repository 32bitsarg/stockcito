import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../functions/ventas_functions.dart';

class VentasMetricsWidget extends StatelessWidget {
  final List<Venta> ventas;
  final List<Venta> ventasFiltradas;

  const VentasMetricsWidget({
    super.key,
    required this.ventas,
    required this.ventasFiltradas,
  });

  @override
  Widget build(BuildContext context) {
    final totalVentas = VentasFunctions.calcularTotalVentas(ventasFiltradas);
    final numeroVentas = VentasFunctions.calcularNumeroVentas(ventasFiltradas);
    final promedioVentas = VentasFunctions.calcularPromedioVentas(ventasFiltradas);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context,
            'Total Ventas',
            VentasFunctions.formatPrecio(totalVentas),
            Icons.attach_money,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            context,
            'Número de Ventas',
            numeroVentas.toString(),
            Icons.shopping_cart,
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            context,
            'Promedio por Venta',
            VentasFunctions.formatPrecio(promedioVentas),
            Icons.trending_up,
            AppTheme.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
