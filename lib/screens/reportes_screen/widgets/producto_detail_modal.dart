import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../services/system/logging_service.dart';
import 'producto_detail_content.dart';

/// Modal para mostrar detalles completos de un producto
class ProductoDetailModal extends StatelessWidget {
  final Producto producto;

  const ProductoDetailModal({
    super.key,
    required this.producto,
  });

  /// Muestra el modal de detalle de producto
  static void show(BuildContext context, Producto producto) {
    try {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ProductoDetailModal(producto: producto),
      );
    } catch (e) {
      LoggingService.error('Error mostrando modal de detalle de producto: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // Header del modal
              _buildHeader(context),
              
              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ProductoDetailContent(producto: producto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icono del producto
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Título y subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detalle del Producto',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Botón de cerrar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.errorColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(8),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.errorColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
