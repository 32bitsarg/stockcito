import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/venta.dart';
import '../../functions/nueva_venta_functions.dart';

class NuevaVentaItemsSection extends StatelessWidget {
  final List<VentaItem> itemsVenta;
  final Function(int) onIncrementarCantidad;
  final Function(int) onDecrementarCantidad;
  final Function(int) onEliminarItem;

  const NuevaVentaItemsSection({
    super.key,
    required this.itemsVenta,
    required this.onIncrementarCantidad,
    required this.onDecrementarCantidad,
    required this.onEliminarItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.cartShopping,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Items de la Venta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (itemsVenta.isEmpty)
            _buildEmptyItemsState(context)
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: itemsVenta.length,
                itemBuilder: (context, index) {
                  final item = itemsVenta[index];
                  return _buildItemVentaCardCompact(context, item, index);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.cartShopping,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay productos agregados',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos desde la lista de la izquierda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemVentaCardCompact(BuildContext context, VentaItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Información del item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NuevaVentaFunctions.getItemVentaText(item),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NuevaVentaFunctions.getSubtotalText(item),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Controles de cantidad
          Row(
            children: [
              // Botón decrementar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () => onDecrementarCantidad(index),
                  icon: const Icon(
                    FontAwesomeIcons.minus,
                    color: Colors.white,
                    size: 12,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              // Cantidad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${item.cantidad}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón incrementar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () => onIncrementarCantidad(index),
                  icon: const Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 12,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(width: 8),
              // Botón eliminar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  onPressed: () => onEliminarItem(index),
                  icon: const Icon(
                    FontAwesomeIcons.trashCan,
                    color: Colors.white,
                    size: 12,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
