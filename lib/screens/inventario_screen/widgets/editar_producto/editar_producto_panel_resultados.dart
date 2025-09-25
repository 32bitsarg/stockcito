import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../widgets/ui/utility/windows_button.dart';
import '../../functions/editar_producto_functions.dart';

class EditarProductoPanelResultados extends StatelessWidget {
  final double costoTotal;
  final double precioVenta;
  final double precioConIVA;
  final double gananciaNeta;
  final double porcentajeMargen;
  final VoidCallback onActualizarProducto;
  final VoidCallback onRecalcular;

  const EditarProductoPanelResultados({
    super.key,
    required this.costoTotal,
    required this.precioVenta,
    required this.precioConIVA,
    required this.gananciaNeta,
    required this.porcentajeMargen,
    required this.onActualizarProducto,
    required this.onRecalcular,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                Icons.calculate,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Resultados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildResultadoItem(
            context,
            'Costo Total',
            EditarProductoFunctions.formatPrecio(costoTotal),
            AppTheme.textSecondary,
            Icons.receipt,
          ),
          const SizedBox(height: 16),
          _buildResultadoItem(
            context,
            'Precio de Venta',
            EditarProductoFunctions.formatPrecio(precioVenta),
            AppTheme.primaryColor,
            Icons.sell,
          ),
          const SizedBox(height: 16),
          _buildResultadoItem(
            context,
            'Precio con IVA',
            EditarProductoFunctions.formatPrecio(precioConIVA),
            AppTheme.successColor,
            Icons.payment,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Ganancia Neta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  EditarProductoFunctions.formatPrecio(gananciaNeta),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  EditarProductoFunctions.formatPorcentaje(porcentajeMargen),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botones de acción
          Column(
            children: [
              // Botón principal - Actualizar
              SizedBox(
                width: double.infinity,
                child: WindowsButton(
                  text: 'Actualizar Producto',
                  type: ButtonType.primary,
                  onPressed: onActualizarProducto,
                  icon: Icons.save,
                ),
              ),
              const SizedBox(height: 12),
              // Botones secundarios
              Row(
                children: [
                  Expanded(
                    child: WindowsButton(
                      text: 'Recalcular',
                      type: ButtonType.secondary,
                      onPressed: onRecalcular,
                      icon: Icons.refresh,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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
