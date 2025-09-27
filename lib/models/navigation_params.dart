/// Parámetros de navegación para selección específica de elementos
class NavigationParams {
  final int? initialIndex;
  final String? selectedItemId;
  final String? selectedItemType;
  final Map<String, dynamic>? additionalData;

  const NavigationParams({
    this.initialIndex,
    this.selectedItemId,
    this.selectedItemType,
    this.additionalData,
  });

  /// Crea parámetros para selección de producto
  factory NavigationParams.forProduct(String productId) {
    return NavigationParams(
      initialIndex: 1, // Inventario
      selectedItemId: productId,
      selectedItemType: 'producto',
    );
  }

  /// Crea parámetros para selección de venta
  factory NavigationParams.forSale(String saleId) {
    return NavigationParams(
      initialIndex: 2, // Ventas
      selectedItemId: saleId,
      selectedItemType: 'venta',
    );
  }

  /// Crea parámetros para selección de cliente
  factory NavigationParams.forClient(String clientId) {
    return NavigationParams(
      initialIndex: 3, // Clientes
      selectedItemId: clientId,
      selectedItemType: 'cliente',
    );
  }

  /// Verifica si hay selección específica
  bool get hasSpecificSelection => selectedItemId != null && selectedItemType != null;

  Map<String, dynamic> toMap() {
    return {
      'initialIndex': initialIndex,
      'selectedItemId': selectedItemId,
      'selectedItemType': selectedItemType,
      'additionalData': additionalData,
    };
  }

  factory NavigationParams.fromMap(Map<String, dynamic> map) {
    return NavigationParams(
      initialIndex: map['initialIndex'],
      selectedItemId: map['selectedItemId'],
      selectedItemType: map['selectedItemType'],
      additionalData: map['additionalData'] != null 
          ? Map<String, dynamic>.from(map['additionalData']) 
          : null,
    );
  }

  @override
  String toString() {
    return 'NavigationParams(initialIndex: $initialIndex, selectedItemId: $selectedItemId, selectedItemType: $selectedItemType)';
  }
}
