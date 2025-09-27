import 'package:flutter/material.dart';
import '../../../services/ui/inventario/inventario_state_service.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../../../services/ui/inventario/inventario_data_service.dart';
import '../../../models/producto.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import '../modals/product_form_modal.dart';
import 'inventario_provider.dart';
import 'inventario_content_widget.dart';

/// Widget que maneja el layout principal del inventario
class InventarioLayoutWidget extends StatelessWidget {
  final InventarioStateService stateService;
  final InventarioLogicService logicService;
  final InventarioNavigationService navigationService;
  final InventarioDataService dataService;

  const InventarioLayoutWidget({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return InventarioProvider(
      stateService: stateService,
      logicService: logicService,
      navigationService: navigationService,
      dataService: dataService,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DashboardGlassmorphismWidget(
          child: InventarioContentWidget(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showProductModal(context),
          icon: const Icon(Icons.add),
          label: const Text('Nuevo Producto'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  /// Mostrar modal de producto
  void _showProductModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ProductFormModal(
        categories: stateService.categorias.cast<Categoria>(),
        sizes: stateService.tallas.cast<Talla>(),
        onProductCreated: (producto) async {
          try {
            await dataService.createProducto(producto);
            // Recargar datos
            await logicService.loadAllData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto creado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear producto: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onProductUpdated: (producto) async {
          try {
            await dataService.updateProducto(producto);
            // Recargar datos
            await logicService.loadAllData();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Producto actualizado exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar producto: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}
