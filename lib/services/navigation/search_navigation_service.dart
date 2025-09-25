import 'package:flutter/material.dart';
import 'package:stockcito/models/search_result.dart';
import 'package:stockcito/screens/dashboard/dashboard_screen.dart';

/// Servicio para manejar la navegación desde resultados de búsqueda
class SearchNavigationService {
  static final SearchNavigationService _instance = SearchNavigationService._internal();
  factory SearchNavigationService() => _instance;
  SearchNavigationService._internal();

  /// Navega a la pantalla correspondiente según el tipo de resultado
  void navigateToResult(BuildContext context, SearchResult result) {
    print('🔍 [DEBUG] SearchNavigationService.navigateToResult:');
    print('   - Tipo: ${result.type}');
    print('   - Título: ${result.title}');
    print('   - ID: ${result.id}');
    
    switch (result.type) {
      case 'producto':
        _navigateToProduct(context, result);
        break;
      case 'venta':
        _navigateToSale(context, result);
        break;
      case 'cliente':
        _navigateToClient(context, result);
        break;
      default:
        _showUnsupportedTypeDialog(context, result);
    }
  }

  /// Navega a la pantalla de inventario y selecciona el producto
  void _navigateToProduct(BuildContext context, SearchResult result) {
    print('🔍 [DEBUG] _navigateToProduct: Navegando a Inventario (índice 1)');
    
    // Navegar al dashboard con índice inicial
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(initialIndex: 1), // Index 1 = Inventario
      ),
      (route) => false,
    );
    
    print('🔍 [DEBUG] _navigateToProduct: Navegación completada');
    
    // TODO: Implementar selección específica del producto en inventario
    // Esto requeriría pasar el ID del producto y que el inventario lo seleccione automáticamente
  }

  /// Navega a la pantalla de ventas y selecciona la venta
  void _navigateToSale(BuildContext context, SearchResult result) {
    // Navegar al dashboard con índice inicial
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(initialIndex: 2), // Index 2 = Ventas
      ),
      (route) => false,
    );
    
    // TODO: Implementar selección específica de la venta
    // Esto requeriría pasar el ID de la venta y que la pantalla de ventas la seleccione automáticamente
  }

  /// Navega a la pantalla de clientes y selecciona el cliente
  void _navigateToClient(BuildContext context, SearchResult result) {
    // Navegar al dashboard con índice inicial
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const DashboardScreen(initialIndex: 3), // Index 3 = Clientes
      ),
      (route) => false,
    );
    
    // TODO: Implementar selección específica del cliente
    // Esto requeriría pasar el ID del cliente y que la pantalla de clientes lo seleccione automáticamente
  }

  /// Muestra un diálogo para tipos no soportados
  void _showUnsupportedTypeDialog(BuildContext context, SearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tipo no soportado'),
        content: Text('El tipo "${result.type}" no tiene navegación implementada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Obtiene el índice de la pantalla según el tipo
  int getScreenIndexForType(String type) {
    switch (type) {
      case 'producto':
        return 1; // Inventario
      case 'venta':
        return 2; // Ventas
      case 'cliente':
        return 3; // Clientes
      default:
        return 0; // Dashboard
    }
  }

  /// Obtiene el nombre de la pantalla según el tipo
  String getScreenNameForType(String type) {
    switch (type) {
      case 'producto':
        return 'Inventario';
      case 'venta':
        return 'Ventas';
      case 'cliente':
        return 'Clientes';
      default:
        return 'Dashboard';
    }
  }
}
