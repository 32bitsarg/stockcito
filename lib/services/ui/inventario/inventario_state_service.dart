import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja el estado reactivo del inventario
class InventarioStateService extends ChangeNotifier {
  static final InventarioStateService _instance = InventarioStateService._internal();
  factory InventarioStateService() => _instance;
  InventarioStateService._internal();

  // Estado del inventario
  List<dynamic> _productos = [];
  List<dynamic> _categorias = [];
  List<dynamic> _tallas = [];
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';
  String _busqueda = '';
  bool _mostrarSoloStockBajo = false;
  bool _cargando = false;
  String? _error;
  
  // Estado para selección específica
  String? _selectedProductId;
  bool _isSelectingProduct = false;

  // Getters
  List<dynamic> get productos => _productos;
  List<dynamic> get categorias => _categorias;
  List<dynamic> get tallas => _tallas;
  String get filtroCategoria => _filtroCategoria;
  String get filtroTalla => _filtroTalla;
  String get busqueda => _busqueda;
  bool get mostrarSoloStockBajo => _mostrarSoloStockBajo;
  bool get cargando => _cargando;
  String? get error => _error;
  
  // Getters para selección específica
  String? get selectedProductId => _selectedProductId;
  bool get isSelectingProduct => _isSelectingProduct;

  /// Actualizar productos
  void updateProductos(List<dynamic> productos) {
    if (_productos != productos) {
      _productos = productos;
      LoggingService.info('📦 Productos actualizados: ${productos.length}');
      notifyListeners();
    }
  }

  /// Actualizar categorías
  void updateCategorias(List<dynamic> categorias) {
    if (_categorias != categorias) {
      _categorias = categorias;
      LoggingService.info('🏷️ Categorías actualizadas: ${categorias.length}');
      notifyListeners();
    }
  }

  /// Actualizar tallas
  void updateTallas(List<dynamic> tallas) {
    if (_tallas != tallas) {
      _tallas = tallas;
      LoggingService.info('📏 Tallas actualizadas: ${tallas.length}');
      notifyListeners();
    }
  }

  /// Actualizar filtro de categoría
  void updateFiltroCategoria(String categoria) {
    if (_filtroCategoria != categoria) {
      _filtroCategoria = categoria;
      LoggingService.info('🔍 Filtro categoría: $categoria');
      notifyListeners();
    }
  }

  /// Actualizar filtro de talla
  void updateFiltroTalla(String talla) {
    if (_filtroTalla != talla) {
      _filtroTalla = talla;
      LoggingService.info('🔍 Filtro talla: $talla');
      notifyListeners();
    }
  }

  /// Actualizar búsqueda
  void updateBusqueda(String busqueda) {
    if (_busqueda != busqueda) {
      _busqueda = busqueda;
      LoggingService.info('🔍 Búsqueda: $busqueda');
      notifyListeners();
    }
  }

  /// Actualizar filtro de stock bajo
  void updateMostrarSoloStockBajo(bool mostrar) {
    if (_mostrarSoloStockBajo != mostrar) {
      _mostrarSoloStockBajo = mostrar;
      LoggingService.info('🔍 Stock bajo: $mostrar');
      notifyListeners();
    }
  }

  /// Actualizar estado de carga
  void updateCargando(bool cargando) {
    if (_cargando != cargando) {
      _cargando = cargando;
      notifyListeners();
    }
  }

  /// Actualizar error
  void updateError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Limpiar error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Obtener filtros actuales
  Map<String, dynamic> getCurrentFilters() {
    return {
      'categoria': _filtroCategoria,
      'talla': _filtroTalla,
      'busqueda': _busqueda,
      'stockBajo': _mostrarSoloStockBajo,
    };
  }

  /// Resetear todos los filtros
  void resetFilters() {
    _filtroCategoria = 'Todas';
    _filtroTalla = 'Todas';
    _busqueda = '';
    _mostrarSoloStockBajo = false;
    LoggingService.info('🔄 Filtros reseteados');
    notifyListeners();
  }

  // ==================== MÉTODOS DE SELECCIÓN ESPECÍFICA ====================

  /// Seleccionar un producto específico por ID
  Future<bool> selectProductById(String productId) async {
    try {
      LoggingService.info('🎯 Seleccionando producto por ID: $productId');
      
      _isSelectingProduct = true;
      notifyListeners();

      // Buscar el producto en la lista actual
      final producto = _productos.firstWhere(
        (p) => p.id.toString() == productId,
        orElse: () => null,
      );

      if (producto != null) {
        _selectedProductId = productId;
        LoggingService.info('✅ Producto encontrado y seleccionado: ${producto.nombre}');
        
        // Limpiar filtros para mostrar el producto
        resetFilters();
        
        // Aplicar filtros específicos del producto si es necesario
        if (producto.categoria != null && producto.categoria.isNotEmpty) {
          updateFiltroCategoria(producto.categoria);
        }
        
        _isSelectingProduct = false;
        notifyListeners();
        return true;
      } else {
        LoggingService.warning('⚠️ Producto no encontrado con ID: $productId');
        _isSelectingProduct = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ Error seleccionando producto: $e');
      _isSelectingProduct = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar selección específica
  void clearProductSelection() {
    if (_selectedProductId != null || _isSelectingProduct) {
      _selectedProductId = null;
      _isSelectingProduct = false;
      LoggingService.info('🔄 Selección de producto limpiada');
      notifyListeners();
    }
  }

  /// Verificar si un producto está seleccionado
  bool isProductSelected(String productId) {
    return _selectedProductId == productId;
  }

  /// Obtener el producto seleccionado
  dynamic getSelectedProduct() {
    if (_selectedProductId == null) return null;
    
    try {
      return _productos.firstWhere(
        (p) => p.id.toString() == _selectedProductId,
        orElse: () => null,
      );
    } catch (e) {
      LoggingService.error('❌ Error obteniendo producto seleccionado: $e');
      return null;
    }
  }

  @override
  void dispose() {
    LoggingService.info('🛑 InventarioStateService disposed');
    super.dispose();
  }
}
