import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../../models/producto.dart';
import '../forms/sale_form_widget.dart';

class SaleFormModal extends StatelessWidget {
  final Venta? sale;
  final List<Cliente> clients;
  final List<Producto> products;
  final Function(Venta) onSaleCreated;
  final Function(Venta) onSaleUpdated;

  const SaleFormModal({
    super.key,
    this.sale,
    required this.clients,
    required this.products,
    required this.onSaleCreated,
    required this.onSaleUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.8,
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
              child: SaleFormWidget(
                sale: sale,
                clients: clients,
                products: products,
                onSave: (savedSale) {
                  if (sale == null) {
                    onSaleCreated(savedSale);
                  } else {
                    onSaleUpdated(savedSale);
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
            sale == null ? 'Nueva Venta' : 'Editar Venta',
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