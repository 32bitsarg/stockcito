import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculadora_config.dart';
import '../models/calculadora_state.dart';
import '../models/producto_calculo.dart';
import '../models/costo_directo.dart';
import '../models/costo_indirecto.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import 'global_config_service.dart';

/// Servicio para manejar la calculadora de precios
class CalculadoraService {
  static const String _configKey = 'calculadora_config';
  static const String _stateKey = 'calculadora_state';
  
  static final CalculadoraService _instance = CalculadoraService._internal();
  factory CalculadoraService() => _instance;
  CalculadoraService._internal();

  CalculadoraConfig _config = CalculadoraConfig.defaultConfig;
  CalculadoraState? _currentState;
  final GlobalConfigService _globalConfigService = GlobalConfigService();
  final DatosService _datosService = DatosService();

  /// Obtiene la configuración actual
  CalculadoraConfig get config => _config;

  /// Obtiene el estado actual
  CalculadoraState? get currentState => _currentState;

  /// Inicializa el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando CalculadoraService...');
      await _globalConfigService.initialize();
      await _loadConfig();
      await _loadState();
      LoggingService.info('CalculadoraService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando CalculadoraService: $e');
    }
  }

  /// Carga la configuración desde SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        _config = CalculadoraConfig.fromMap(configMap);
        LoggingService.info('Configuración de calculadora cargada: ${_config.modoAvanzado ? "Avanzado" : "Simple"}');
      } else {
        // Usar configuración global para margen e IVA
        _config = CalculadoraConfig(
          modoAvanzado: false,
          tipoNegocio: 'textil',
          margenGananciaDefault: _globalConfigService.margenDefecto,
          ivaDefault: _globalConfigService.iva,
          autoGuardar: true,
          mostrarAnalisisDetallado: true,
        );
        LoggingService.info('Usando configuración por defecto con valores globales');
      }
    } catch (e) {
      LoggingService.error('Error cargando configuración: $e');
      _config = CalculadoraConfig(
        modoAvanzado: false,
        tipoNegocio: 'textil',
        margenGananciaDefault: _globalConfigService.margenDefecto,
        ivaDefault: _globalConfigService.iva,
        autoGuardar: true,
        mostrarAnalisisDetallado: true,
      );
    }
  }

  /// Guarda la configuración en SharedPreferences
  Future<void> saveConfig(CalculadoraConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toMap());
      await prefs.setString(_configKey, configJson);
      _config = config;
      LoggingService.info('Configuración guardada: ${config.modoAvanzado ? "Avanzado" : "Simple"}');
    } catch (e) {
      LoggingService.error('Error guardando configuración: $e');
    }
  }

  /// Carga el estado desde SharedPreferences y costos desde base de datos
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_stateKey);
      
      CalculadoraState baseState;
      if (stateJson != null) {
        final stateMap = json.decode(stateJson) as Map<String, dynamic>;
        baseState = _deserializeState(stateMap);
        LoggingService.info('Estado de calculadora cargado desde SharedPreferences');
      } else {
        baseState = CalculadoraState.initial(_config);
        LoggingService.info('Estado inicial creado');
      }

      // Cargar costos desde la base de datos
      final costosDirectos = await _datosService.getCostosDirectos();
      final costosIndirectos = await _datosService.getCostosIndirectos();
      
      LoggingService.info('Costos cargados - Directos: ${costosDirectos.length}, Indirectos: ${costosIndirectos.length}');

      // Crear estado con costos de la base de datos
      _currentState = baseState.copyWith(
        costosDirectos: costosDirectos,
        costosIndirectos: costosIndirectos,
      );
      
      LoggingService.info('Estado de calculadora inicializado con costos persistentes');
    } catch (e) {
      LoggingService.error('Error cargando estado: $e');
      _currentState = CalculadoraState.initial(_config);
    }
  }

  /// Guarda el estado en SharedPreferences
  Future<void> saveState(CalculadoraState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = json.encode(_serializeState(state));
      await prefs.setString(_stateKey, stateJson);
      _currentState = state;
      LoggingService.info('Estado de calculadora guardado');
    } catch (e) {
      LoggingService.error('Error guardando estado: $e');
    }
  }

  /// Actualiza la configuración
  Future<void> updateConfig(CalculadoraConfig newConfig) async {
    await saveConfig(newConfig);
    // Actualizar la configuración del estado actual sin resetear el paso
    if (_currentState != null) {
      final newState = _currentState!.copyWith(config: newConfig);
      await updateState(newState);
    } else {
      _currentState = CalculadoraState.initial(newConfig);
      await saveState(_currentState!);
    }
  }

  /// Actualiza el estado
  Future<void> updateState(CalculadoraState newState) async {
    await saveState(newState);
  }

  /// Avanza al siguiente paso
  Future<void> nextStep() async {
    if (_currentState != null && _currentState!.canGoToNextStep()) {
      final newState = _currentState!.copyWith(
        pasoActual: _currentState!.pasoActual + 1,
        hasChanges: true,
      );
      await updateState(newState);
    }
  }

  /// Retrocede al paso anterior
  Future<void> previousStep() async {
    if (_currentState != null && _currentState!.canGoToPreviousStep()) {
      final newState = _currentState!.copyWith(
        pasoActual: _currentState!.pasoActual - 1,
        hasChanges: true,
      );
      await updateState(newState);
    }
  }

  /// Va a un paso específico
  Future<void> goToStep(int step) async {
    if (_currentState != null && step >= 0 && step < 4) {
      final newState = _currentState!.copyWith(
        pasoActual: step,
        hasChanges: true,
      );
      await updateState(newState);
    }
  }

  /// Actualiza el producto
  Future<void> updateProducto(ProductoCalculo producto) async {
    if (_currentState != null) {
      final newState = _currentState!.copyWith(
        producto: producto,
        hasChanges: true,
      );
      await updateState(newState);
    }
  }

  /// Agrega un costo directo
  Future<void> addCostoDirecto(CostoDirecto costo) async {
    if (_currentState != null) {
      try {
        // Guardar en la base de datos
        final success = await _datosService.saveCostoDirecto(costo);
        if (success) {
          // Recargar costos desde la base de datos
          final costosDirectos = await _datosService.getCostosDirectos();
          
          final newState = _currentState!.copyWith(
            costosDirectos: costosDirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo directo agregado y guardado: ${costo.nombre}');
        } else {
          LoggingService.error('Error guardando costo directo en base de datos');
        }
      } catch (e) {
        LoggingService.error('Error agregando costo directo: $e');
      }
    }
  }

  /// Actualiza un costo directo
  Future<void> updateCostoDirecto(String id, CostoDirecto costo) async {
    if (_currentState != null) {
      try {
        // Actualizar en la base de datos
        final success = await _datosService.updateCostoDirecto(costo);
        if (success) {
          // Recargar costos desde la base de datos
          final costosDirectos = await _datosService.getCostosDirectos();
          
          final newState = _currentState!.copyWith(
            costosDirectos: costosDirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo directo actualizado y guardado: ${costo.nombre}');
        } else {
          LoggingService.error('Error actualizando costo directo en base de datos');
        }
      } catch (e) {
        LoggingService.error('Error actualizando costo directo: $e');
      }
    }
  }

  /// Elimina un costo directo
  Future<void> removeCostoDirecto(String id) async {
    if (_currentState != null) {
      try {
        // Buscar el costo para obtener su ID numérico
        final costo = _currentState!.costosDirectos.firstWhere((c) => c.id == id);
        
        // Eliminar de la base de datos
        final success = await _datosService.deleteCostoDirecto(int.parse(costo.id));
        if (success) {
          // Recargar costos desde la base de datos
          final costosDirectos = await _datosService.getCostosDirectos();
          
          final newState = _currentState!.copyWith(
            costosDirectos: costosDirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo directo eliminado: ${costo.nombre}');
        } else {
          LoggingService.error('Error eliminando costo directo de la base de datos');
        }
      } catch (e) {
        LoggingService.error('Error eliminando costo directo: $e');
      }
    }
  }

  /// Agrega un costo indirecto
  Future<void> addCostoIndirecto(CostoIndirecto costo) async {
    if (_currentState != null) {
      try {
        // Guardar en la base de datos
        final success = await _datosService.saveCostoIndirecto(costo);
        if (success) {
          // Recargar costos desde la base de datos
          final costosIndirectos = await _datosService.getCostosIndirectos();
          
          final newState = _currentState!.copyWith(
            costosIndirectos: costosIndirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo indirecto agregado y guardado: ${costo.nombre}');
        } else {
          LoggingService.error('Error guardando costo indirecto en base de datos');
        }
      } catch (e) {
        LoggingService.error('Error agregando costo indirecto: $e');
      }
    }
  }

  /// Actualiza un costo indirecto
  Future<void> updateCostoIndirecto(String id, CostoIndirecto costo) async {
    if (_currentState != null) {
      try {
        // Actualizar en la base de datos
        final success = await _datosService.updateCostoIndirecto(costo);
        if (success) {
          // Recargar costos desde la base de datos
          final costosIndirectos = await _datosService.getCostosIndirectos();
          
          final newState = _currentState!.copyWith(
            costosIndirectos: costosIndirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo indirecto actualizado y guardado: ${costo.nombre}');
        } else {
          LoggingService.error('Error actualizando costo indirecto en base de datos');
        }
      } catch (e) {
        LoggingService.error('Error actualizando costo indirecto: $e');
      }
    }
  }

  /// Elimina un costo indirecto
  Future<void> removeCostoIndirecto(String id) async {
    if (_currentState != null) {
      try {
        // Buscar el costo para obtener su ID numérico
        final costo = _currentState!.costosIndirectos.firstWhere((c) => c.id == id);
        
        // Eliminar de la base de datos
        final success = await _datosService.deleteCostoIndirecto(int.parse(costo.id));
        if (success) {
          // Recargar costos desde la base de datos
          final costosIndirectos = await _datosService.getCostosIndirectos();
          
          final newState = _currentState!.copyWith(
            costosIndirectos: costosIndirectos,
            hasChanges: true,
          );
          await updateState(newState);
          
          LoggingService.info('Costo indirecto eliminado: ${costo.nombre}');
        } else {
          LoggingService.error('Error eliminando costo indirecto de la base de datos');
        }
      } catch (e) {
        LoggingService.error('Error eliminando costo indirecto: $e');
      }
    }
  }

  /// Limpia el estado actual
  Future<void> clearState() async {
    _currentState = CalculadoraState.initial(_config);
    await saveState(_currentState!);
    LoggingService.info('Estado de calculadora limpiado');
  }

  /// Serializa el estado para guardar
  Map<String, dynamic> _serializeState(CalculadoraState state) {
    return {
      'config': state.config.toMap(),
      'producto': state.producto.toMap(),
      'costosDirectos': state.costosDirectos.map((c) => c.toMap()).toList(),
      'costosIndirectos': state.costosIndirectos.map((c) => c.toMap()).toList(),
      'pasoActual': state.pasoActual,
      'isLoading': state.isLoading,
      'error': state.error,
      'hasChanges': state.hasChanges,
    };
  }

  /// Deserializa el estado desde guardado
  CalculadoraState _deserializeState(Map<String, dynamic> map) {
    final config = CalculadoraConfig.fromMap(map['config'] ?? {});
    final producto = ProductoCalculo.fromMap(map['producto'] ?? {});
    final costosDirectos = (map['costosDirectos'] as List?)
        ?.map((c) => CostoDirecto.fromMap(c))
        .toList() ?? [];
    final costosIndirectos = (map['costosIndirectos'] as List?)
        ?.map((c) => CostoIndirecto.fromMap(c))
        .toList() ?? [];
    
    return CalculadoraState(
      config: config,
      producto: producto,
      costosDirectos: costosDirectos,
      costosIndirectos: costosIndirectos,
      pasoActual: map['pasoActual'] ?? 0,
      isLoading: map['isLoading'] ?? false,
      error: map['error'],
      hasChanges: map['hasChanges'] ?? false,
    );
  }
}
