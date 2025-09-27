import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import '../../../models/producto.dart';
import 'calculadora_pricing_service.dart';

/// Historial de cálculo
class CalculoHistorico {
  final String id;
  final ProductoCalculo producto;
  final PrecioCalculado precioCalculado;
  final DateTime fechaCalculo;
  final String modo; // 'simple' o 'avanzado'
  final bool fueGuardado;

  const CalculoHistorico({
    required this.id,
    required this.producto,
    required this.precioCalculado,
    required this.fechaCalculo,
    required this.modo,
    required this.fueGuardado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto': producto.toMap(),
      'precioCalculado': precioCalculado.toMap(),
      'fechaCalculo': fechaCalculo.toIso8601String(),
      'modo': modo,
      'fueGuardado': fueGuardado,
    };
  }

  factory CalculoHistorico.fromMap(Map<String, dynamic> map) {
    return CalculoHistorico(
      id: map['id'] ?? '',
      producto: ProductoCalculo.fromMap(map['producto'] ?? {}),
      precioCalculado: PrecioCalculado.fromMap(map['precioCalculado'] ?? {}),
      fechaCalculo: DateTime.parse(map['fechaCalculo'] ?? DateTime.now().toIso8601String()),
      modo: map['modo'] ?? 'simple',
      fueGuardado: map['fueGuardado'] ?? false,
    );
  }
}

/// Servicio para manejar la persistencia de datos de la calculadora
class CalculadoraPersistenceService {
  static final CalculadoraPersistenceService _instance = CalculadoraPersistenceService._internal();
  factory CalculadoraPersistenceService() => _instance;
  CalculadoraPersistenceService._internal();

  final DatosService _datosService = DatosService();
  
  // Claves para SharedPreferences
  static const String _configKey = 'calculadora_config';
  static const String _historialKey = 'calculadora_historial';
  static const String _estadoKey = 'calculadora_estado';

  /// Guarda un producto calculado en la base de datos
  Future<bool> guardarProductoCalculado({
    required ProductoCalculo productoCalculo,
    required PrecioCalculado precioCalculado,
    required String modo,
  }) async {
    try {
      LoggingService.info('💾 Guardando producto calculado: ${productoCalculo.nombre}');

      // Convertir ProductoCalculo a Producto para la base de datos
      final producto = Producto(
        id: 0, // Se asignará automáticamente
        nombre: productoCalculo.nombre,
        categoria: productoCalculo.categoria,
        talla: productoCalculo.talla,
        stock: productoCalculo.stock,
        costoMateriales: precioCalculado.costoTotal * 0.6, // Estimación
        costoManoObra: precioCalculado.costoTotal * 0.3, // Estimación
        gastosGenerales: precioCalculado.costoTotal * 0.1, // Estimación
        margenGanancia: precioCalculado.margenGanancia,
        fechaCreacion: productoCalculo.fechaCreacion,
      );

      // Guardar en la base de datos
      final success = await _datosService.saveProducto(producto);
      
      if (success) {
        // Guardar en historial
        await _guardarEnHistorial(productoCalculo, precioCalculado, modo, true);
        LoggingService.info('✅ Producto calculado guardado exitosamente');
        return true;
      } else {
        LoggingService.error('❌ Error guardando producto en base de datos');
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ Error guardando producto calculado: $e');
      return false;
    }
  }

  /// Guarda solo el historial sin persistir en base de datos
  Future<bool> guardarSoloHistorial({
    required ProductoCalculo productoCalculo,
    required PrecioCalculado precioCalculado,
    required String modo,
  }) async {
    try {
      LoggingService.info('📝 Guardando solo historial: ${productoCalculo.nombre}');
      
      await _guardarEnHistorial(productoCalculo, precioCalculado, modo, false);
      
      LoggingService.info('✅ Historial guardado exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando historial: $e');
      return false;
    }
  }

  /// Guarda la configuración de la calculadora
  Future<bool> guardarConfiguracion(CalculadoraConfig config) async {
    try {
      LoggingService.info('⚙️ Guardando configuración de calculadora');

      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toMap());
      await prefs.setString(_configKey, configJson);

      LoggingService.info('✅ Configuración guardada exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando configuración: $e');
      return false;
    }
  }

  /// Carga la configuración de la calculadora
  Future<CalculadoraConfig?> cargarConfiguracion() async {
    try {
      LoggingService.info('⚙️ Cargando configuración de calculadora');

      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson != null) {
        final configMap = json.decode(configJson) as Map<String, dynamic>;
        final config = CalculadoraConfig.fromMap(configMap);
        
        LoggingService.info('✅ Configuración cargada exitosamente');
        return config;
      } else {
        LoggingService.info('ℹ️ No hay configuración guardada, usando por defecto');
        return CalculadoraConfig.defaultConfig;
      }
    } catch (e) {
      LoggingService.error('❌ Error cargando configuración: $e');
      return CalculadoraConfig.defaultConfig;
    }
  }

  /// Carga el historial de cálculos
  Future<List<CalculoHistorico>> cargarHistorial({int? limite}) async {
    try {
      LoggingService.info('📚 Cargando historial de cálculos');

      final prefs = await SharedPreferences.getInstance();
      final historialJson = prefs.getString(_historialKey);

      if (historialJson != null) {
        final historialList = json.decode(historialJson) as List;
        final historial = historialList
            .map((item) => CalculoHistorico.fromMap(item as Map<String, dynamic>))
            .toList();

        // Ordenar por fecha más reciente primero
        historial.sort((a, b) => b.fechaCalculo.compareTo(a.fechaCalculo));

        // Aplicar límite si se especifica
        final resultado = limite != null && limite > 0 
            ? historial.take(limite).toList()
            : historial;

        LoggingService.info('✅ Historial cargado: ${resultado.length} cálculos');
        return resultado;
      } else {
        LoggingService.info('ℹ️ No hay historial guardado');
        return [];
      }
    } catch (e) {
      LoggingService.error('❌ Error cargando historial: $e');
      return [];
    }
  }

  /// Guarda el estado actual de la calculadora
  Future<bool> guardarEstado({
    required ProductoCalculo producto,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required int pasoActual,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('💾 Guardando estado actual de calculadora');

      final estado = {
        'producto': producto.toMap(),
        'costosDirectos': costosDirectos.map((c) => c.toMap()).toList(),
        'costosIndirectos': costosIndirectos.map((c) => c.toMap()).toList(),
        'pasoActual': pasoActual,
        'config': config.toMap(),
        'fechaGuardado': DateTime.now().toIso8601String(),
      };

      final prefs = await SharedPreferences.getInstance();
      final estadoJson = json.encode(estado);
      await prefs.setString(_estadoKey, estadoJson);

      LoggingService.info('✅ Estado guardado exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando estado: $e');
      return false;
    }
  }

  /// Carga el estado guardado de la calculadora
  Future<Map<String, dynamic>?> cargarEstado() async {
    try {
      LoggingService.info('📂 Cargando estado guardado de calculadora');

      final prefs = await SharedPreferences.getInstance();
      final estadoJson = prefs.getString(_estadoKey);

      if (estadoJson != null) {
        final estado = json.decode(estadoJson) as Map<String, dynamic>;
        
        LoggingService.info('✅ Estado cargado exitosamente');
        return estado;
      } else {
        LoggingService.info('ℹ️ No hay estado guardado');
        return null;
      }
    } catch (e) {
      LoggingService.error('❌ Error cargando estado: $e');
      return null;
    }
  }

  /// Limpia el estado guardado
  Future<bool> limpiarEstado() async {
    try {
      LoggingService.info('🗑️ Limpiando estado guardado');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_estadoKey);

      LoggingService.info('✅ Estado limpiado exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error limpiando estado: $e');
      return false;
    }
  }

  /// Elimina un cálculo del historial
  Future<bool> eliminarDelHistorial(String id) async {
    try {
      LoggingService.info('🗑️ Eliminando cálculo del historial: $id');

      final historial = await cargarHistorial();
      final historialActualizado = historial.where((h) => h.id != id).toList();
      
      await _guardarHistorialCompleto(historialActualizado);

      LoggingService.info('✅ Cálculo eliminado del historial');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando del historial: $e');
      return false;
    }
  }

  /// Limpia todo el historial
  Future<bool> limpiarHistorial() async {
    try {
      LoggingService.info('🗑️ Limpiando historial completo');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historialKey);

      LoggingService.info('✅ Historial limpiado exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error limpiando historial: $e');
      return false;
    }
  }

  /// Exporta el historial a JSON
  Future<String?> exportarHistorial() async {
    try {
      LoggingService.info('📤 Exportando historial');

      final historial = await cargarHistorial();
      final historialJson = json.encode(historial.map((h) => h.toMap()).toList());

      LoggingService.info('✅ Historial exportado exitosamente');
      return historialJson;
    } catch (e) {
      LoggingService.error('❌ Error exportando historial: $e');
      return null;
    }
  }

  /// Importa historial desde JSON
  Future<bool> importarHistorial(String historialJson) async {
    try {
      LoggingService.info('📥 Importando historial');

      final historialList = json.decode(historialJson) as List;
      final historial = historialList
          .map((item) => CalculoHistorico.fromMap(item as Map<String, dynamic>))
          .toList();

      await _guardarHistorialCompleto(historial);

      LoggingService.info('✅ Historial importado exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error importando historial: $e');
      return false;
    }
  }

  /// Obtiene estadísticas del historial
  Future<Map<String, dynamic>> obtenerEstadisticasHistorial() async {
    try {
      LoggingService.info('📊 Obteniendo estadísticas del historial');

      final historial = await cargarHistorial();
      
      if (historial.isEmpty) {
        return {
          'totalCalculos': 0,
          'calculosGuardados': 0,
          'modoMasUsado': 'simple',
          'promedioMargen': 0.0,
          'promedioPrecio': 0.0,
          'ultimoCalculo': null,
        };
      }

      final calculosGuardados = historial.where((h) => h.fueGuardado).length;
      final modoMasUsado = _obtenerModoMasUsado(historial);
      final promedioMargen = _calcularPromedioMargen(historial);
      final promedioPrecio = _calcularPromedioPrecio(historial);
      final ultimoCalculo = historial.isNotEmpty ? historial.first.fechaCalculo : null;

      final estadisticas = {
        'totalCalculos': historial.length,
        'calculosGuardados': calculosGuardados,
        'modoMasUsado': modoMasUsado,
        'promedioMargen': promedioMargen,
        'promedioPrecio': promedioPrecio,
        'ultimoCalculo': ultimoCalculo?.toIso8601String(),
      };

      LoggingService.info('✅ Estadísticas obtenidas exitosamente');
      return estadisticas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Guarda un cálculo en el historial
  Future<void> _guardarEnHistorial(
    ProductoCalculo producto,
    PrecioCalculado precioCalculado,
    String modo,
    bool fueGuardado,
  ) async {
    final historial = await cargarHistorial();
    
    final nuevoCalculo = CalculoHistorico(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      producto: producto,
      precioCalculado: precioCalculado,
      fechaCalculo: DateTime.now(),
      modo: modo,
      fueGuardado: fueGuardado,
    );

    historial.insert(0, nuevoCalculo); // Agregar al inicio
    
    // Mantener solo los últimos 100 cálculos
    if (historial.length > 100) {
      historial.removeRange(100, historial.length);
    }

    await _guardarHistorialCompleto(historial);
  }

  /// Guarda el historial completo
  Future<void> _guardarHistorialCompleto(List<CalculoHistorico> historial) async {
    final prefs = await SharedPreferences.getInstance();
    final historialJson = json.encode(historial.map((h) => h.toMap()).toList());
    await prefs.setString(_historialKey, historialJson);
  }

  /// Obtiene el modo más usado
  String _obtenerModoMasUsado(List<CalculoHistorico> historial) {
    final conteoModos = <String, int>{};
    
    for (final calculo in historial) {
      conteoModos[calculo.modo] = (conteoModos[calculo.modo] ?? 0) + 1;
    }

    if (conteoModos.isEmpty) return 'simple';
    
    return conteoModos.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calcula el promedio de margen
  double _calcularPromedioMargen(List<CalculoHistorico> historial) {
    if (historial.isEmpty) return 0.0;
    
    final sumaMargenes = historial.fold(0.0, (sum, h) => sum + h.precioCalculado.margenGanancia);
    return sumaMargenes / historial.length;
  }

  /// Calcula el promedio de precio
  double _calcularPromedioPrecio(List<CalculoHistorico> historial) {
    if (historial.isEmpty) return 0.0;
    
    final sumaPrecios = historial.fold(0.0, (sum, h) => sum + h.precioCalculado.precioSugerido);
    return sumaPrecios / historial.length;
  }
}
