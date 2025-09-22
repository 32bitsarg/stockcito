import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/system/logging_service.dart';

/// Servicio para manejar la configuración global de la app
class GlobalConfigService {
  static const String _margenKey = 'margen_defecto';
  static const String _ivaKey = 'iva';
  static const String _monedaKey = 'moneda';
  
  static final GlobalConfigService _instance = GlobalConfigService._internal();
  factory GlobalConfigService() => _instance;
  GlobalConfigService._internal();

  double _margenDefecto = 50.0;
  double _iva = 21.0;
  String _moneda = 'USD';

  /// Obtiene el margen de ganancia por defecto
  double get margenDefecto => _margenDefecto;

  /// Obtiene el IVA por defecto
  double get iva => _iva;

  /// Obtiene la moneda por defecto
  String get moneda => _moneda;

  /// Inicializa el servicio cargando la configuración
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando GlobalConfigService...');
      await _loadConfig();
      LoggingService.info('GlobalConfigService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando GlobalConfigService: $e');
    }
  }

  /// Carga la configuración desde SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _margenDefecto = prefs.getDouble(_margenKey) ?? 50.0;
      _iva = prefs.getDouble(_ivaKey) ?? 21.0;
      _moneda = prefs.getString(_monedaKey) ?? 'USD';
      
      LoggingService.info('Configuración global cargada - Margen: $_margenDefecto%, IVA: $_iva%, Moneda: $_moneda');
    } catch (e) {
      LoggingService.error('Error cargando configuración global: $e');
      // Usar valores por defecto
      _margenDefecto = 50.0;
      _iva = 21.0;
      _moneda = 'USD';
    }
  }

  /// Actualiza el margen de ganancia
  Future<void> updateMargenDefecto(double margen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_margenKey, margen);
      _margenDefecto = margen;
      LoggingService.info('Margen de ganancia actualizado: $margen%');
    } catch (e) {
      LoggingService.error('Error actualizando margen de ganancia: $e');
    }
  }

  /// Actualiza el IVA
  Future<void> updateIVA(double iva) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_ivaKey, iva);
      _iva = iva;
      LoggingService.info('IVA actualizado: $iva%');
    } catch (e) {
      LoggingService.error('Error actualizando IVA: $e');
    }
  }

  /// Actualiza la moneda
  Future<void> updateMoneda(String moneda) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_monedaKey, moneda);
      _moneda = moneda;
      LoggingService.info('Moneda actualizada: $moneda');
    } catch (e) {
      LoggingService.error('Error actualizando moneda: $e');
    }
  }

  /// Recarga la configuración desde SharedPreferences
  Future<void> reload() async {
    await _loadConfig();
  }

  /// Obtiene la configuración completa
  Map<String, dynamic> getConfig() {
    return {
      'margenDefecto': _margenDefecto,
      'iva': _iva,
      'moneda': _moneda,
    };
  }
}
