import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja el estado reactivo de los reportes
class ReportesStateService extends ChangeNotifier {
  ReportesStateService();

  // Estado de los reportes
  List<dynamic> _productos = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';
  Map<String, dynamic>? _metricasCompletas;
  String? _error;

  // Getters
  List<dynamic> get productos => _productos;
  bool get isLoading => _isLoading;
  String get filtroCategoria => _filtroCategoria;
  String get filtroTalla => _filtroTalla;
  Map<String, dynamic>? get metricasCompletas => _metricasCompletas;
  String? get error => _error;

  /// Actualizar productos
  void updateProductos(List<dynamic> productos) {
    if (_productos != productos) {
      _productos = productos;
      LoggingService.info('📊 Productos actualizados: ${productos.length}');
      notifyListeners();
    }
  }

  /// Actualizar estado de carga
  void updateLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
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

  /// Actualizar métricas completas
  void updateMetricasCompletas(Map<String, dynamic>? metricas) {
    if (_metricasCompletas != metricas) {
      _metricasCompletas = metricas;
      LoggingService.info('📈 Métricas completas actualizadas');
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
    };
  }

  /// Resetear todos los filtros
  void resetFilters() {
    _filtroCategoria = 'Todas';
    _filtroTalla = 'Todas';
    LoggingService.info('🔄 Filtros de reportes reseteados');
    notifyListeners();
  }

  @override
  void dispose() {
    LoggingService.info('🛑 ReportesStateService disposed');
    super.dispose();
  }
}


