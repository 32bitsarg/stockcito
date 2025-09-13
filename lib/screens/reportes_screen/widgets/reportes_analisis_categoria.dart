import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../functions/reportes_functions.dart';

class ReportesAnalisisCategoria extends StatelessWidget {
  final Map<String, int> productosPorCategoria;
  final Map<String, double> valorPorCategoria;
  final int totalProductos;

  const ReportesAnalisisCategoria({
    super.key,
    required this.productosPorCategoria,
    required this.valorPorCategoria,
    required this.totalProductos,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(
                Icons.pie_chart,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis por Categoría',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...productosPorCategoria.entries.map((entry) {
            final categoria = entry.key;
            final cantidad = entry.value;
            final valor = valorPorCategoria[categoria] ?? 0.0;
            final porcentaje = ReportesFunctions.calcularPorcentajeCategoria(cantidad, totalProductos);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ReportesFunctions.getCategoriaColor(categoria).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ReportesFunctions.getCategoriaColor(categoria),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$cantidad productos • \$${valor.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ReportesFunctions.getCategoriaColor(categoria),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
