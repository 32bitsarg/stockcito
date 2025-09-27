import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../forms/product_form_widget.dart';

/// Modal para crear o editar productos
class ProductFormModal extends StatelessWidget {
  final Producto? product;
  final List<Categoria> categories;
  final List<Talla> sizes;
  final Function(Producto) onProductCreated;
  final Function(Producto) onProductUpdated;

  const ProductFormModal({
    super.key,
    this.product,
    required this.categories,
    required this.sizes,
    required this.onProductCreated,
    required this.onProductUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ProductFormWidget(
                product: product,
                categories: categories,
                sizes: sizes,
                onSave: (savedProduct) {
                  if (product == null) {
                    onProductCreated(savedProduct);
                  } else {
                    onProductUpdated(savedProduct);
                  }
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            product == null ? 'Nuevo Producto' : 'Editar Producto',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}