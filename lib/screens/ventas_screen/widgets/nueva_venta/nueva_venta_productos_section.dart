import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/producto.dart';
import '../../functions/nueva_venta_functions.dart';

class NuevaVentaProductosSection extends StatelessWidget {
  final List<Producto> productos;
  final Function(Producto) onAgregarProducto;

  const NuevaVentaProductosSection({
    super.key,
    required this.productos,
    required this.onAgregarProducto,
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
                FontAwesomeIcons.box,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Productos Disponibles',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Lista de productos compacta
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                return _buildProductoCardCompact(context, producto);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCardCompact(BuildContext context, Producto producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Información del producto compacta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _buildInfoChipCompact(context, producto.categoria),
                    const SizedBox(width: 4),
                    _buildInfoChipCompact(context, producto.talla),
                    const SizedBox(width: 4),
                    _buildInfoChipCompact(context, NuevaVentaFunctions.getStockText(producto.stock)),
                  ],
                ),
              ],
            ),
          ),
          // Precio y botón agregar compactos
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NuevaVentaFunctions.formatPrecio(producto.precioVenta),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => onAgregarProducto(producto),
                  icon: const Icon(
                    FontAwesomeIcons.plus,
                    color: Colors.white,
                    size: 16,
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

  Widget _buildInfoChipCompact(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 10,
        ),
      ),
    );
  }
}
