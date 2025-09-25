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

  @override
  void dispose() {
    LoggingService.info('🛑 InventarioStateService disposed');
    super.dispose();
  }
}
