import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../functions/reportes_functions.dart';

class ReportesListaProductos extends StatelessWidget {
  final List<Producto> productos;

  const ReportesListaProductos({
    super.key,
    required this.productos,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
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
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos en Reporte (${productos.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de productos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductoCard(context, producto);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(BuildContext context, Producto producto) {
    final isStockBajo = ReportesFunctions.isStockBajo(producto);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStockBajo ? AppTheme.warningColor.withOpacity(0.3) : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del producto
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: ReportesFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ReportesFunctions.getCategoriaIcon(producto.categoria),
              color: ReportesFunctions.getCategoriaColor(producto.categoria),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(context, producto.categoria, Icons.category),
                    const SizedBox(width: 8),
                    _buildInfoChip(context, producto.talla, Icons.straighten),
                    if (isStockBajo) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(context, 'Stock Bajo', Icons.warning, AppTheme.warningColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Precios y stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ReportesFunctions.formatPrecio(producto.precioVenta),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 16,
                    color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${producto.stock} unidades',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                      fontWeight: isStockBajo ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildInfoChip(BuildContext context, String text, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
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
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos para mostrar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros o agrega productos para ver el reporte',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
