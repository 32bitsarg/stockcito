import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja el estado reactivo de los clientes
class ClientesStateService extends ChangeNotifier {
  ClientesStateService();

  // Estado de los clientes
  List<dynamic> _clientes = [];
  bool _isLoading = true;
  String _filtroBusqueda = '';
  String? _error;
  
  // Estado para selección específica
  String? _selectedClientId;
  bool _isSelectingClient = false;

  // Getters
  List<dynamic> get clientes => _clientes;
  bool get isLoading => _isLoading;
  String get filtroBusqueda => _filtroBusqueda;
  String? get error => _error;
  
  // Getters para selección específica
  String? get selectedClientId => _selectedClientId;
  bool get isSelectingClient => _isSelectingClient;

  /// Actualizar clientes
  void updateClientes(List<dynamic> clientes) {
    if (_clientes != clientes) {
      _clientes = clientes;
      LoggingService.info('👥 Clientes actualizados: ${clientes.length}');
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

  /// Actualizar filtro de búsqueda
  void updateFiltroBusqueda(String filtro) {
    if (_filtroBusqueda != filtro) {
      _filtroBusqueda = filtro;
      LoggingService.info('🔍 Filtro búsqueda: $filtro');
      notifyListeners();
    }
  }

  /// Limpiar filtro de búsqueda
  void clearFiltroBusqueda() {
    if (_filtroBusqueda.isNotEmpty) {
      _filtroBusqueda = '';
      LoggingService.info('🔄 Filtro búsqueda limpiado');
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

  /// Obtener clientes filtrados
  List<dynamic> getClientesFiltrados() {
    if (_filtroBusqueda.isEmpty) return _clientes;
    
    return _clientes.where((cliente) {
      final nombre = cliente.nombre?.toString().toLowerCase() ?? '';
      final telefono = cliente.telefono?.toString() ?? '';
      final email = cliente.email?.toString().toLowerCase() ?? '';
      final filtro = _filtroBusqueda.toLowerCase();
      
      return nombre.contains(filtro) ||
             telefono.contains(filtro) ||
             email.contains(filtro);
    }).toList();
  }

  /// Obtener estadísticas
  Map<String, dynamic> getEstadisticas() {
    return {
      'totalClientes': _clientes.length,
      'clientesFiltrados': getClientesFiltrados().length,
      'conEmail': _clientes.where((c) => c.email?.isNotEmpty == true).length,
      'conTelefono': _clientes.where((c) => c.telefono?.isNotEmpty == true).length,
    };
  }

  // ==================== MÉTODOS DE SELECCIÓN ESPECÍFICA ====================

  /// Seleccionar un cliente específico por ID
  Future<bool> selectClientById(String clientId) async {
    try {
      LoggingService.info('🎯 Seleccionando cliente por ID: $clientId');
      
      _isSelectingClient = true;
      notifyListeners();

      // Buscar el cliente en la lista actual
      final cliente = _clientes.firstWhere(
        (c) => c.id.toString() == clientId,
        orElse: () => null,
      );

      if (cliente != null) {
        _selectedClientId = clientId;
        LoggingService.info('✅ Cliente encontrado y seleccionado: ${cliente.nombre}');
        
        // Limpiar filtros para mostrar el cliente
        clearFiltroBusqueda();
        
        // Aplicar filtro de búsqueda específico del cliente si es necesario
        if (cliente.nombre != null && cliente.nombre.isNotEmpty) {
          updateFiltroBusqueda(cliente.nombre);
        }
        
        _isSelectingClient = false;
        notifyListeners();
        return true;
      } else {
        LoggingService.warning('⚠️ Cliente no encontrado con ID: $clientId');
        _isSelectingClient = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ Error seleccionando cliente: $e');
      _isSelectingClient = false;
      notifyListeners();
      return false;
    }
  }

  /// Limpiar selección específica
  void clearClientSelection() {
    if (_selectedClientId != null || _isSelectingClient) {
      _selectedClientId = null;
      _isSelectingClient = false;
      LoggingService.info('🔄 Selección de cliente limpiada');
      notifyListeners();
    }
  }

  /// Verificar si un cliente está seleccionado
  bool isClientSelected(String clientId) {
    return _selectedClientId == clientId;
  }

  /// Obtener el cliente seleccionado
  dynamic getSelectedClient() {
    if (_selectedClientId == null) return null;
    
    try {
      return _clientes.firstWhere(
        (c) => c.id.toString() == _selectedClientId,
        orElse: () => null,
      );
    } catch (e) {
      LoggingService.error('❌ Error obteniendo cliente seleccionado: $e');
      return null;
    }
  }

  @override
  void dispose() {
    LoggingService.info('🛑 ClientesStateService disposed');
    super.dispose();
  }
}


