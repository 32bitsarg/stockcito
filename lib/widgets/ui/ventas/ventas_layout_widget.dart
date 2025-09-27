import 'package:flutter/material.dart';
import '../../../services/ui/ventas/ventas_state_service.dart';
import '../../../services/ui/ventas/ventas_logic_service.dart';
import '../../../services/ui/ventas/ventas_navigation_service.dart';
import '../../../services/ui/ventas/ventas_data_service.dart';
import '../../../services/ui/inventario/inventario_data_service.dart';
import '../../../models/cliente.dart';
import '../../../models/producto.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import '../modals/sale_form_modal.dart';
import 'ventas_content_widget.dart';

/// Widget que define el layout principal de la pantalla de ventas
class VentasLayoutWidget extends StatelessWidget {
  final VentasStateService stateService;
  final VentasLogicService logicService;
  final VentasNavigationService navigationService;
  final VentasDataService dataService;

  const VentasLayoutWidget({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo completamente blanco
      body: DashboardGlassmorphismWidget(
        child: VentasContentWidget(
          onNuevaVenta: () => _showSaleModal(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSaleModal(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Mostrar modal de venta
  void _showSaleModal(BuildContext context) async {
    // Cargar productos del inventario
    final inventarioDataService = InventarioDataService();
    await inventarioDataService.initialize();
    final productos = await inventarioDataService.getProductos();
    
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => SaleFormModal(
          clients: stateService.clientes.cast<Cliente>(),
          products: productos.cast<Producto>(),
          onSaleCreated: (venta) async {
            try {
              await dataService.createVenta(venta);
              // Recargar datos
              await logicService.loadAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta creada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al crear venta: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          onSaleUpdated: (venta) async {
            try {
              await dataService.updateVenta(venta);
              // Recargar datos
              await logicService.loadAllData();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta actualizada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al actualizar venta: $e'),
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
}
