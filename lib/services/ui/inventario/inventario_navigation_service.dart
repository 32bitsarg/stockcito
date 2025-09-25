import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../widgets/ui/inventario/modern_gestion_categorias_modal.dart';
import '../../../widgets/ui/inventario/modern_gestion_tallas_modal.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../../../models/producto.dart';
import 'inventario_logic_service.dart';

/// Servicio que maneja la navegación del inventario
class InventarioNavigationService {
  
  /// Navegar a editar producto
  void navigateToEditProduct(BuildContext context, dynamic producto) {
    try {
      LoggingService.info('📝 Navegando a editar producto: ${producto.nombre}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
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
              child: _buildEditProductScreen(producto),
            ),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error navegando a editar producto: $e');
    }
  }

  /// Construir pantalla de editar producto
  Widget _buildEditProductScreen(dynamic producto) {
    // Importar directamente para evitar problemas con imports dinámicos
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text('Pantalla de edición de producto'),
      ),
    );
  }

  /// Mostrar diálogo de gestión de categorías
  void showGestionCategorias(BuildContext context, {
    required List<Categoria> categorias,
    required List<Producto> productos,
    required Function(List<Categoria>) onCategoriasChanged,
    InventarioLogicService? logicService,
  }) {
    try {
      LoggingService.info('🏷️ Mostrando gestión de categorías');
      
      showDialog(
        context: context,
        builder: (context) => ModernGestionCategoriasModal(
          categorias: categorias,
          productos: productos,
          logicService: logicService ?? InventarioLogicService(),
          navigationService: this,
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando gestión de categorías: $e');
    }
  }

  /// Mostrar diálogo de gestión de tallas
  void showGestionTallas(BuildContext context, {
    required List<Talla> tallas,
    required List<Producto> productos,
    required Function(List<Talla>) onTallasChanged,
    InventarioLogicService? logicService,
  }) {
    try {
      LoggingService.info('📏 Mostrando gestión de tallas');
      
      showDialog(
        context: context,
        builder: (context) => ModernGestionTallasModal(
          tallas: tallas,
          productos: productos,
          logicService: logicService ?? InventarioLogicService(),
          navigationService: this,
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando gestión de tallas: $e');
    }
  }

  /// Mostrar diálogo de confirmación de eliminación
  Future<bool> showConfirmDelete(BuildContext context, String nombreProducto) async {
    try {
      LoggingService.info('🗑️ Mostrando confirmación de eliminación: $nombreProducto');
      
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar Producto'),
          content: Text('¿Estás seguro de que quieres eliminar "$nombreProducto"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      
      return result ?? false;
    } catch (e) {
      LoggingService.error('❌ Error mostrando confirmación: $e');
      return false;
    }
  }

  /// Mostrar mensaje de éxito
  void showSuccessMessage(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de éxito: $e');
    }
  }

  /// Mostrar mensaje de error
  void showErrorMessage(BuildContext context, String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('❌ Error mostrando mensaje de error: $e');
    }
  }
}
