import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja el estado reactivo de las ventas
class VentasStateService extends ChangeNotifier {
  VentasStateService();

  // Estado de las ventas
  List<dynamic> _ventas = [];
  List<dynamic> _clientes = [];
  String _filtroEstado = 'Todas';
  String _filtroCliente = 'Todos';
  String _filtroMetodoPago = 'Todos';
  bool _cargando = false;
  String? _error;
  
  // Estado para selección específica
  String? _selectedSaleId;
  bool _isSelectingSale = false;

  // Listas para filtros
  final List<String> _estados = ['Todas', 'Pendiente', 'Completada', 'Cancelada'];
  final List<String> _metodosPago = ['Todos', 'Efectivo', 'Tarjeta', 'Transferencia'];

  // Getters
  List<dynamic> get ventas => _ventas;
  List<dynamic> get clientes => _clientes;
  String get filtroEstado => _filtroEstado;
  String get filtroCliente => _filtroCliente;
  String get filtroMetodoPago => _filtroMetodoPago;
  bool get cargando => _cargando;
  String? get error => _error;
  List<String> get estados => _estados;
  List<String> get metodosPago => _metodosPago;
  
  // Getters para selección específica
  String? get selectedSaleId => _selectedSaleId;
  bool get isSelectingSale => _isSelectingSale;

  /// Actualizar ventas
  void updateVentas(List<dynamic> ventas) {
    if (_ventas != ventas) {
      _ventas = ventas;
      LoggingService.info('💰 Ventas actualizadas: ${ventas.length}');
      notifyListeners();
    }
  }

  /// Actualizar clientes
  void updateClientes(List<dynamic> clientes) {
    if (_clientes != clientes) {
      _clientes = clientes;
      LoggingService.info('👥 Clientes actualizados: ${clientes.length}');
      notifyListeners();
    }
  }

  /// Actualizar filtro de estado
  void updateFiltroEstado(String estado) {
    if (_filtroEstado != estado) {
      _filtroEstado = estado;
      LoggingService.info('🔍 Filtro estado: $estado');
      notifyListeners();
    }
  }

  /// Actualizar filtro de cliente
  void updateFiltroCliente(String cliente) {
    if (_filtroCliente != cliente) {
      _filtroCliente = cliente;
      LoggingService.info('🔍 Filtro cliente: $cliente');
      notifyListeners();
    }
  }

  /// Actualizar filtro de método de pago
  void updateFiltroMetodoPago(String metodoPago) {
    if (_filtroMetodoPago != metodoPago) {
      _filtroMetodoPago = metodoPago;
      LoggingService.info('🔍 Filtro método pago: $metodoPago');
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
      'estado': _filtroEstado,
      'cliente': _filtroCliente,
      'metodoPago': _filtroMetodoPago,
    };
  }

  /// Resetear todos los filtros
  void resetFilters() {
    _filtroEstado = 'Todas';
    _filtroCliente = 'Todos';
    _filtroMetodoPago = 'Todos';
    LoggingService.info('🔄 Filtros de ventas reseteados');
    notifyListeners();
  }

  // ==================== MÉTODOS DE SELECCIÓN ESPECÍFICA ====================

  /// Seleccionar una venta específica por ID
  Future<bool> selectSaleById(String saleId) async {
    try {
      LoggingService.info('🎯 Seleccionando venta por ID: $saleId');
      
      _isSelectingSale = true;
      notifyListeners();

      // Buscar la venta en la lista actual
      final venta = _ventas.firstWhere(
        (v) => v.id.toString() == saleId,
        orElse: () => null,
      );

      if (venta != null) {
        _selectedSaleId = saleId;
        LoggingService.info('✅ Venta encontrada y seleccionada: ${venta.cliente} - \$${venta.total}');
        
        // Limpiar filtros para mostrar la venta
        resetFilters();
        
        // Aplicar filtros específicos de la venta si es necesario
        if (venta.estado != null && venta.estado.isNotEmpty) {
          updateFiltroEstado(venta.estado);
        }
        
        if (venta.cliente != null && venta.cliente.isNotEmpty) {
          updateFiltroCliente(venta.cliente);
        }
        
        _isSelectingSale = false;
        notifyListeners();
        return true;
      } else {
        LoggingService.warning('⚠️ Venta no encontrada con ID: $saleId');
        _isSelectingSale = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ Error seleccionando venta: $e');
      _isSelectingSale = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar selección específica
  void clearSaleSelection() {
    if (_selectedSaleId != null || _isSelectingSale) {
      _selectedSaleId = null;
      _isSelectingSale = false;
      LoggingService.info('🔄 Selección de venta limpiada');
      notifyListeners();
    }
  }

  /// Verificar si una venta está seleccionada
  bool isSaleSelected(String saleId) {
    return _selectedSaleId == saleId;
  }

  /// Obtener la venta seleccionada
  dynamic getSelectedSale() {
    if (_selectedSaleId == null) return null;
    
    try {
      return _ventas.firstWhere(
        (v) => v.id.toString() == _selectedSaleId,
        orElse: () => null,
      );
    } catch (e) {
      LoggingService.error('❌ Error obteniendo venta seleccionada: $e');
      return null;
    }
  }

  @override
  void dispose() {
    LoggingService.info('🛑 VentasStateService disposed');
    super.dispose();
  }
}
