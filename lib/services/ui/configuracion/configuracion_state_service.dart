import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';

/// Servicio que maneja el estado reactivo de la configuración
class ConfiguracionStateService extends ChangeNotifier {
  ConfiguracionStateService();

  // Estado de la configuración
  double _margenDefecto = 50.0;
  double _iva = 21.0;
  String _moneda = 'USD';
  bool _notificacionesStock = true;
  bool _notificacionesVentas = false;
  bool _exportarAutomatico = false;
  bool _respaldoAutomatico = true;
  bool _mlConsentimiento = false;
  int _stockMinimo = 5;
  bool _isLoading = true;
  String? _error;

  // Getters
  double get margenDefecto => _margenDefecto;
  double get iva => _iva;
  String get moneda => _moneda;
  bool get notificacionesStock => _notificacionesStock;
  bool get notificacionesVentas => _notificacionesVentas;
  bool get exportarAutomatico => _exportarAutomatico;
  bool get respaldoAutomatico => _respaldoAutomatico;
  bool get mlConsentimiento => _mlConsentimiento;
  int get stockMinimo => _stockMinimo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Actualizar margen por defecto
  void updateMargenDefecto(double margen) {
    if (_margenDefecto != margen) {
      _margenDefecto = margen;
      LoggingService.info('💰 Margen por defecto actualizado: $margen%');
      notifyListeners();
    }
  }

  /// Actualizar IVA
  void updateIVA(double iva) {
    if (_iva != iva) {
      _iva = iva;
      LoggingService.info('📊 IVA actualizado: $iva%');
      notifyListeners();
    }
  }

  /// Actualizar moneda
  void updateMoneda(String moneda) {
    if (_moneda != moneda) {
      _moneda = moneda;
      LoggingService.info('💱 Moneda actualizada: $moneda');
      notifyListeners();
    }
  }

  /// Actualizar notificaciones de stock
  void updateNotificacionesStock(bool enabled) {
    if (_notificacionesStock != enabled) {
      _notificacionesStock = enabled;
      LoggingService.info('🔔 Notificaciones de stock: ${enabled ? "activadas" : "desactivadas"}');
      notifyListeners();
    }
  }

  /// Actualizar notificaciones de ventas
  void updateNotificacionesVentas(bool enabled) {
    if (_notificacionesVentas != enabled) {
      _notificacionesVentas = enabled;
      LoggingService.info('🔔 Notificaciones de ventas: ${enabled ? "activadas" : "desactivadas"}');
      notifyListeners();
    }
  }

  /// Actualizar exportación automática
  void updateExportarAutomatico(bool enabled) {
    if (_exportarAutomatico != enabled) {
      _exportarAutomatico = enabled;
      LoggingService.info('📤 Exportación automática: ${enabled ? "activada" : "desactivada"}');
      notifyListeners();
    }
  }

  /// Actualizar respaldo automático
  void updateRespaldoAutomatico(bool enabled) {
    if (_respaldoAutomatico != enabled) {
      _respaldoAutomatico = enabled;
      LoggingService.info('💾 Respaldo automático: ${enabled ? "activado" : "desactivado"}');
      notifyListeners();
    }
  }

  /// Actualizar consentimiento ML
  void updateMLConsentimiento(bool consent) {
    if (_mlConsentimiento != consent) {
      _mlConsentimiento = consent;
      LoggingService.info('🤖 Consentimiento ML: ${consent ? "otorgado" : "revocado"}');
      notifyListeners();
    }
  }

  /// Actualizar stock mínimo
  void updateStockMinimo(int stock) {
    if (_stockMinimo != stock) {
      _stockMinimo = stock;
      LoggingService.info('📦 Stock mínimo actualizado: $stock');
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

  /// Obtener configuración actual como mapa
  Map<String, dynamic> getCurrentConfig() {
    return {
      'margenDefecto': _margenDefecto,
      'iva': _iva,
      'moneda': _moneda,
      'notificacionesStock': _notificacionesStock,
      'notificacionesVentas': _notificacionesVentas,
      'exportarAutomatico': _exportarAutomatico,
      'respaldoAutomatico': _respaldoAutomatico,
      'mlConsentimiento': _mlConsentimiento,
      'stockMinimo': _stockMinimo,
    };
  }

  /// Cargar configuración desde mapa
  void loadFromMap(Map<String, dynamic> config) {
    _margenDefecto = config['margenDefecto'] ?? 50.0;
    _iva = config['iva'] ?? 21.0;
    _moneda = config['moneda'] ?? 'USD';
    _notificacionesStock = config['notificacionesStock'] ?? true;
    _notificacionesVentas = config['notificacionesVentas'] ?? false;
    _exportarAutomatico = config['exportarAutomatico'] ?? false;
    _respaldoAutomatico = config['respaldoAutomatico'] ?? true;
    _mlConsentimiento = config['mlConsentimiento'] ?? false;
    _stockMinimo = config['stockMinimo'] ?? 5;
    
    LoggingService.info('📋 Configuración cargada desde mapa');
    notifyListeners();
  }

  /// Resetear a configuración por defecto
  void resetToDefaults() {
    _margenDefecto = 50.0;
    _iva = 21.0;
    _moneda = 'USD';
    _notificacionesStock = true;
    _notificacionesVentas = false;
    _exportarAutomatico = false;
    _respaldoAutomatico = true;
    _mlConsentimiento = false;
    _stockMinimo = 5;
    
    LoggingService.info('🔄 Configuración reseteada a valores por defecto');
    notifyListeners();
  }

  @override
  void dispose() {
    LoggingService.info('🛑 ConfiguracionStateService disposed');
    super.dispose();
  }
}

