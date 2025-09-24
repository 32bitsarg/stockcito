import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../functions/reportes_functions.dart';

/// Contenido del modal de detalle de producto
class ProductoDetailContent extends StatelessWidget {
  final Producto producto;

  const ProductoDetailContent({
    super.key,
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información básica
        _buildBasicInfo(context),
        const SizedBox(height: 24),
        
        // Información de costos
        _buildCostInfo(context),
        const SizedBox(height: 24),
        
        // Información de precios
        _buildPriceInfo(context),
        const SizedBox(height: 24),
        
        // Información de stock
        _buildStockInfo(context),
        const SizedBox(height: 24),
        
        // Información de fechas
        _buildDateInfo(context),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return _buildInfoSection(
      context,
      'Información Básica',
      Icons.info_outline,
      AppTheme.infoColor,
      [
        _buildInfoRow('Nombre', producto.nombre),
        _buildInfoRow('Categoría', producto.categoria),
        _buildInfoRow('Talla', producto.talla),
      ],
    );
  }

  Widget _buildCostInfo(BuildContext context) {
    return _buildInfoSection(
      context,
      'Costos Detallados',
      Icons.account_balance_wallet_outlined,
      AppTheme.warningColor,
      [
        _buildInfoRow('Costo Materiales', _formatCurrency(producto.costoMateriales)),
        _buildInfoRow('Costo Mano de Obra', _formatCurrency(producto.costoManoObra)),
        _buildInfoRow('Gastos Generales', _formatCurrency(producto.gastosGenerales)),
        _buildInfoRow('Costo Total', _formatCurrency(producto.costoTotal), isHighlight: true),
      ],
    );
  }

  Widget _buildPriceInfo(BuildContext context) {
    final margenGanancia = ((producto.precioVenta - producto.costoTotal) / producto.costoTotal * 100);
    final utilidad = producto.precioVenta - producto.costoTotal;
    
    return _buildInfoSection(
      context,
      'Información de Precios',
      Icons.attach_money_outlined,
      AppTheme.successColor,
      [
        _buildInfoRow('Precio de Venta', _formatCurrency(producto.precioVenta), isHighlight: true),
        _buildInfoRow('Margen de Ganancia', '${margenGanancia.toStringAsFixed(1)}%'),
        _buildInfoRow('Utilidad por Unidad', _formatCurrency(utilidad)),
        _buildInfoRow('Valor Total en Inventario', _formatCurrency(producto.precioVenta * producto.stock)),
      ],
    );
  }

  Widget _buildStockInfo(BuildContext context) {
    final stockColor = ReportesFunctions.getStockColor(producto.stock);
    
    return _buildInfoSection(
      context,
      'Información de Stock',
      Icons.inventory_outlined,
      stockColor,
      [
        _buildInfoRow('Stock Actual', '${producto.stock} unidades', isHighlight: true),
        _buildInfoRow('Estado', _getStockStatus(producto.stock)),
        _buildInfoRow('Valor de Stock', _formatCurrency(producto.costoTotal * producto.stock)),
      ],
    );
  }

  Widget _buildDateInfo(BuildContext context) {
    return _buildInfoSection(
      context,
      'Información de Fechas',
      Icons.calendar_today_outlined,
      AppTheme.textSecondary,
      [
        _buildInfoRow('Fecha de Creación', _formatDate(producto.fechaCreacion)),
        _buildInfoRow('Días en Inventario', '${DateTime.now().difference(producto.fechaCreacion).inDays} días'),
      ],
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Contenido de la sección
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isHighlight ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStockStatus(int stock) {
    if (stock <= 0) return 'Sin Stock';
    if (stock <= 5) return 'Stock Bajo';
    if (stock <= 20) return 'Stock Medio';
    return 'Stock Alto';
  }
}
