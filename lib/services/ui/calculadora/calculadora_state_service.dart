import 'package:flutter/material.dart';
import '../../../services/system/logging_service.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_state.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';

/// Servicio que maneja el estado reactivo de la calculadora de precios
class CalculadoraStateService extends ChangeNotifier {
  CalculadoraStateService();

  // Estado de la calculadora
  CalculadoraConfig _config = CalculadoraConfig.defaultConfig;
  CalculadoraState? _currentState;
  ProductoCalculo? _productoCalculo;
  List<CostoDirecto> _costosDirectos = [];
  List<CostoIndirecto> _costosIndirectos = [];
  int _currentStep = 0;
  bool _isLoading = true;
  String? _error;

  // Getters
  CalculadoraConfig get config => _config;
  CalculadoraState? get currentState => _currentState;
  ProductoCalculo? get productoCalculo => _productoCalculo;
  List<CostoDirecto> get costosDirectos => _costosDirectos;
  List<CostoIndirecto> get costosIndirectos => _costosIndirectos;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Actualizar configuración
  void updateConfig(CalculadoraConfig config) {
    if (_config != config) {
      _config = config;
      LoggingService.info('⚙️ Configuración de calculadora actualizada');
      notifyListeners();
    }
  }

  /// Actualizar estado actual
  void updateCurrentState(CalculadoraState? state) {
    if (_currentState != state) {
      _currentState = state;
      LoggingService.info('📊 Estado de calculadora actualizado');
      notifyListeners();
    }
  }

  /// Actualizar producto de cálculo
  void updateProductoCalculo(ProductoCalculo? producto) {
    if (_productoCalculo != producto) {
      _productoCalculo = producto;
      LoggingService.info('📦 Producto de cálculo actualizado: ${producto?.nombre ?? "N/A"}');
      notifyListeners();
    }
  }

  /// Actualizar costos directos
  void updateCostosDirectos(List<CostoDirecto> costos) {
    if (_costosDirectos != costos) {
      _costosDirectos = costos;
      LoggingService.info('💰 Costos directos actualizados: ${costos.length} items');
      notifyListeners();
    }
  }

  /// Actualizar costos indirectos
  void updateCostosIndirectos(List<CostoIndirecto> costos) {
    if (_costosIndirectos != costos) {
      _costosIndirectos = costos;
      LoggingService.info('💼 Costos indirectos actualizados: ${costos.length} items');
      notifyListeners();
    }
  }

  /// Actualizar paso actual
  void updateCurrentStep(int step) {
    if (_currentStep != step) {
      _currentStep = step;
      LoggingService.info('🔄 Paso actual actualizado: $step');
      notifyListeners();
    }
  }

  /// Ir al siguiente paso
  void nextStep() {
    if (_currentStep < 5) { // 0-5 pasos (0-indexed)
      updateCurrentStep(_currentStep + 1);
    }
  }

  /// Ir al paso anterior
  void previousStep() {
    if (_currentStep > 0) {
      updateCurrentStep(_currentStep - 1);
    }
  }

  /// Ir a un paso específico
  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      updateCurrentStep(step);
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

  /// Agregar costo directo
  void addCostoDirecto(CostoDirecto costo) {
    _costosDirectos.add(costo);
    LoggingService.info('➕ Costo directo agregado: ${costo.nombre}');
    notifyListeners();
  }

  /// Eliminar costo directo
  void removeCostoDirecto(int index) {
    if (index >= 0 && index < _costosDirectos.length) {
      final costo = _costosDirectos.removeAt(index);
      LoggingService.info('➖ Costo directo eliminado: ${costo.nombre}');
      notifyListeners();
    }
  }

  /// Agregar costo indirecto
  void addCostoIndirecto(CostoIndirecto costo) {
    _costosIndirectos.add(costo);
    LoggingService.info('➕ Costo indirecto agregado: ${costo.nombre}');
    notifyListeners();
  }

  /// Eliminar costo indirecto
  void removeCostoIndirecto(int index) {
    if (index >= 0 && index < _costosIndirectos.length) {
      final costo = _costosIndirectos.removeAt(index);
      LoggingService.info('➖ Costo indirecto eliminado: ${costo.nombre}');
      notifyListeners();
    }
  }

  /// Calcular total de costos directos
  double get totalCostosDirectos {
    return _costosDirectos.fold(0.0, (sum, costo) => sum + ((costo as dynamic).costo ?? 0.0));
  }

  /// Calcular total de costos indirectos
  double get totalCostosIndirectos {
    return _costosIndirectos.fold(0.0, (sum, costo) => sum + ((costo as dynamic).costo ?? 0.0));
  }

  /// Calcular costo total
  double get costoTotal {
    return totalCostosDirectos + totalCostosIndirectos;
  }

  /// Calcular precio de venta
  double get precioVenta {
    final margen = _config.margenGananciaDefault / 100;
    return costoTotal * (1 + margen);
  }

  /// Calcular precio con IVA
  double get precioConIVA {
    final iva = _config.ivaDefault / 100;
    return precioVenta * (1 + iva);
  }

  /// Resetear calculadora
  void reset() {
    _config = CalculadoraConfig.defaultConfig;
    _currentState = null;
    _productoCalculo = null;
    _costosDirectos.clear();
    _costosIndirectos.clear();
    _currentStep = 0;
    _error = null;
    
    LoggingService.info('🔄 Calculadora reseteada');
    notifyListeners();
  }

  /// Verificar si el paso actual es válido
  bool isStepValid(int step) {
    switch (step) {
      case 0: // Configuración
        return true;
      case 1: // Producto
        return _productoCalculo != null;
      case 2: // Costos directos
        return _costosDirectos.isNotEmpty;
      case 3: // Costos indirectos
        return _costosIndirectos.isNotEmpty;
      case 4: // Resultado
        return _productoCalculo != null && _costosDirectos.isNotEmpty;
      default:
        return false;
    }
  }

  /// Verificar si puede ir al siguiente paso
  bool canGoNext() {
    return _currentStep < 5 && isStepValid(_currentStep);
  }

  /// Verificar si puede ir al paso anterior
  bool canGoPrevious() {
    return _currentStep > 0;
  }

  @override
  void dispose() {
    LoggingService.info('🛑 CalculadoraStateService disposed');
    super.dispose();
  }
}
