import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import '../../../models/producto.dart';
import 'calculadora_validation_service.dart';
import 'calculadora_pricing_service.dart';
import 'calculadora_persistence_service.dart';

/// Resultado del modo avanzado
class ResultadoModoAvanzado {
  final bool exito;
  final String? mensaje;
  final PrecioCalculado? precioCalculado;
  final Producto? productoGuardado;
  final Map<String, dynamic>? analisisDetallado;
  final List<String>? recomendaciones;

  const ResultadoModoAvanzado({
    required this.exito,
    this.mensaje,
    this.precioCalculado,
    this.productoGuardado,
    this.analisisDetallado,
    this.recomendaciones,
  });
}

/// Servicio para manejar el modo avanzado de la calculadora
class ModoAvanzadoService {
  static final ModoAvanzadoService _instance = ModoAvanzadoService._internal();
  factory ModoAvanzadoService() => _instance;
  ModoAvanzadoService._internal();

  final DatosService _datosService = DatosService();
  final CalculadoraValidationService _validationService = CalculadoraValidationService();
  final CalculadoraPricingService _pricingService = CalculadoraPricingService();
  final CalculadoraPersistenceService _persistenceService = CalculadoraPersistenceService();

  /// Calcula precio óptimo en modo avanzado
  Future<ResultadoModoAvanzado> calcularPrecioAvanzado({
    required ProductoCalculo producto,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('🧮 Calculando precio avanzado para: ${producto.nombre}');

      // 1. Validar datos completos
      final validacion = _validationService.validarModoAvanzado(
        producto: producto,
        costosDirectos: costosDirectos,
        costosIndirectos: costosIndirectos,
        config: config,
      );

      if (!validacion.esValido) {
        final errores = validacion.errores.values.join(', ');
        LoggingService.error('❌ Validación fallida: $errores');
        return ResultadoModoAvanzado(
          exito: false,
          mensaje: 'Datos inválidos: $errores',
          recomendaciones: validacion.sugerencias,
        );
      }

      // 2. Calcular precio óptimo usando el servicio de pricing
      final precioCalculado = await _pricingService.calcularPrecioOptimo(
        producto: producto,
        costosDirectos: costosDirectos,
        costosIndirectos: costosIndirectos,
        config: config,
      );

      // 3. Generar análisis detallado
      final analisisDetallado = await _generarAnalisisDetallado(
        producto: producto,
        precioCalculado: precioCalculado,
        costosDirectos: costosDirectos,
        costosIndirectos: costosIndirectos,
        config: config,
      );

      // 4. Generar recomendaciones
      final recomendaciones = _generarRecomendaciones(
        precioCalculado: precioCalculado,
        analisisDetallado: analisisDetallado,
        validacion: validacion,
      );

      LoggingService.info('✅ Precio avanzado calculado exitosamente');
      
      return ResultadoModoAvanzado(
        exito: true,
        mensaje: 'Precio calculado exitosamente',
        precioCalculado: precioCalculado,
        analisisDetallado: analisisDetallado,
        recomendaciones: recomendaciones,
      );
    } catch (e) {
      LoggingService.error('❌ Error calculando precio avanzado: $e');
      return ResultadoModoAvanzado(
        exito: false,
        mensaje: 'Error interno: $e',
      );
    }
  }

  /// Guarda el producto calculado en modo avanzado
  Future<ResultadoModoAvanzado> guardarProductoAvanzado({
    required ProductoCalculo producto,
    required PrecioCalculado precioCalculado,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
  }) async {
    try {
      LoggingService.info('💾 Guardando producto avanzado: ${producto.nombre}');

      // 1. Guardar producto calculado usando el servicio de persistencia
      final success = await _persistenceService.guardarProductoCalculado(
        productoCalculo: producto,
        precioCalculado: precioCalculado,
        modo: 'avanzado',
      );

      if (!success) {
        LoggingService.error('❌ Error guardando producto avanzado');
        return ResultadoModoAvanzado(
          exito: false,
          mensaje: 'Error guardando producto en la base de datos',
        );
      }

      // 2. Guardar costos para futuras referencias
      await _guardarCostosParaReferencia(costosDirectos, costosIndirectos);

      LoggingService.info('✅ Producto avanzado guardado exitosamente');
      
      return ResultadoModoAvanzado(
        exito: true,
        mensaje: 'Producto guardado exitosamente',
        precioCalculado: precioCalculado,
      );
    } catch (e) {
      LoggingService.error('❌ Error guardando producto avanzado: $e');
      return ResultadoModoAvanzado(
        exito: false,
        mensaje: 'Error interno: $e',
      );
    }
  }

  /// Genera análisis detallado del cálculo
  Future<Map<String, dynamic>> _generarAnalisisDetallado({
    required ProductoCalculo producto,
    required PrecioCalculado precioCalculado,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required CalculadoraConfig config,
  }) async {
    // Análisis de costos
    final analisisCostos = _analizarCostos(costosDirectos, costosIndirectos);
    
    // Análisis de rentabilidad
    final analisisRentabilidad = _analizarRentabilidad(precioCalculado, config);
    
    // Análisis de competitividad
    final analisisCompetitividad = await _analizarCompetitividad(producto, precioCalculado);
    
    // Análisis de riesgo
    final analisisRiesgo = _analizarRiesgo(precioCalculado, analisisCostos);

    return {
      'costos': analisisCostos,
      'rentabilidad': analisisRentabilidad,
      'competitividad': analisisCompetitividad,
      'riesgo': analisisRiesgo,
      'resumen': _generarResumenAnalisis(precioCalculado, analisisCostos),
    };
  }

  /// Genera recomendaciones basadas en el análisis
  List<String> _generarRecomendaciones({
    required PrecioCalculado precioCalculado,
    required Map<String, dynamic> analisisDetallado,
    required ValidacionResultado validacion,
  }) {
    final recomendaciones = <String>[];

    // Recomendaciones de validación
    recomendaciones.addAll(validacion.sugerencias);

    // Recomendaciones de rentabilidad
    final rentabilidad = analisisDetallado['rentabilidad'] as Map<String, dynamic>;
    if (rentabilidad['nivel'] == 'Baja') {
      recomendaciones.add('Considera reducir costos o aumentar el margen');
    } else if (rentabilidad['nivel'] == 'Alta') {
      recomendaciones.add('Excelente rentabilidad, considera mantener el precio');
    }

    // Recomendaciones de competitividad
    final competitividad = analisisDetallado['competitividad'] as Map<String, dynamic>;
    if (competitividad['nivel'] == 'Alto') {
      recomendaciones.add('Precio muy alto para el mercado, considera reducirlo');
    } else if (competitividad['nivel'] == 'Muy competitivo') {
      recomendaciones.add('Precio muy competitivo, considera aumentarlo gradualmente');
    }

    // Recomendaciones de IA
    if (precioCalculado.confianzaIA > 0.7) {
      recomendaciones.add('Análisis de IA confiable, considera seguir las recomendaciones');
    } else {
      recomendaciones.add('Análisis de IA con baja confianza, considera más datos');
    }

    return recomendaciones;
  }

  /// Obtiene productos similares de la base de datos
  Future<List<Producto>> _obtenerProductosSimilares(String categoria) async {
    try {
      final todosLosProductos = await _datosService.getProductos();
      return todosLosProductos.where((p) => p.categoria.toLowerCase() == categoria.toLowerCase()).toList();
    } catch (e) {
      LoggingService.error('❌ Error obteniendo productos similares: $e');
      return [];
    }
  }

  /// Analiza la estructura de costos
  Map<String, dynamic> _analizarCostos(List<CostoDirecto> directos, List<CostoIndirecto> indirectos) {
    final totalDirectos = directos.fold(0.0, (sum, c) => sum + c.costoTotal);
    final totalIndirectos = indirectos.fold(0.0, (sum, c) => sum + c.costoPorProducto);
    final totalCostos = totalDirectos + totalIndirectos;

    return {
      'totalDirectos': totalDirectos,
      'totalIndirectos': totalIndirectos,
      'totalCostos': totalCostos,
      'proporcionDirectos': totalCostos > 0 ? (totalDirectos / totalCostos) * 100 : 0,
      'proporcionIndirectos': totalCostos > 0 ? (totalIndirectos / totalCostos) * 100 : 0,
      'eficiencia': _evaluarEficienciaCostos(totalDirectos, totalIndirectos),
    };
  }

  /// Analiza la rentabilidad
  Map<String, dynamic> _analizarRentabilidad(PrecioCalculado precioCalculado, CalculadoraConfig config) {
    final margenReal = precioCalculado.margenGanancia;
    final nivelRentabilidad = margenReal < config.margenGananciaDefault * 0.8 
        ? 'Baja' 
        : margenReal > config.margenGananciaDefault * 1.2 
            ? 'Alta' 
            : 'Media';

    return {
      'margenReal': margenReal,
      'margenObjetivo': config.margenGananciaDefault,
      'nivel': nivelRentabilidad,
      'gananciaNeta': precioCalculado.gananciaNeta,
      'roi': precioCalculado.costoTotal > 0 ? (precioCalculado.gananciaNeta / precioCalculado.costoTotal) * 100 : 0,
    };
  }

  /// Analiza la competitividad
  Future<Map<String, dynamic>> _analizarCompetitividad(ProductoCalculo producto, PrecioCalculado precioCalculado) async {
    final productosSimilares = await _obtenerProductosSimilares(producto.categoria);
    
    if (productosSimilares.isEmpty) {
      return {
        'nivel': 'Sin datos',
        'confianza': 0.0,
        'recomendacion': 'No hay productos similares para comparar',
      };
    }

    final preciosSimilares = productosSimilares.map((p) => p.precioVenta).toList();
    final precioPromedio = preciosSimilares.reduce((a, b) => a + b) / preciosSimilares.length;
    
    final diferenciaPorcentual = ((precioCalculado.precioSugerido - precioPromedio) / precioPromedio) * 100;
    
    String nivel;
    if (diferenciaPorcentual < -20) nivel = 'Muy competitivo';
    else if (diferenciaPorcentual < -5) nivel = 'Competitivo';
    else if (diferenciaPorcentual < 5) nivel = 'Promedio';
    else if (diferenciaPorcentual < 20) nivel = 'Alto';
    else nivel = 'Muy alto';

    return {
      'nivel': nivel,
      'confianza': _calcularConfianzaComparativo(productosSimilares.length),
      'diferenciaPorcentual': diferenciaPorcentual,
      'precioPromedioMercado': precioPromedio,
    };
  }

  /// Analiza el riesgo
  Map<String, dynamic> _analizarRiesgo(PrecioCalculado precioCalculado, Map<String, dynamic> analisisCostos) {
    final factoresRiesgo = <String>[];
    double nivelRiesgo = 0.0;

    // Riesgo por margen bajo
    if (precioCalculado.margenGanancia < 20) {
      factoresRiesgo.add('Margen de ganancia bajo');
      nivelRiesgo += 0.3;
    }

    // Riesgo por costos indirectos altos
    final proporcionIndirectos = analisisCostos['proporcionIndirectos'] as double;
    if (proporcionIndirectos > 40) {
      factoresRiesgo.add('Costos indirectos muy altos');
      nivelRiesgo += 0.2;
    }

    // Riesgo por precio alto
    if (precioCalculado.precioSugerido > 1000) {
      factoresRiesgo.add('Precio muy alto');
      nivelRiesgo += 0.2;
    }

    String nivel;
    if (nivelRiesgo < 0.3) nivel = 'Bajo';
    else if (nivelRiesgo < 0.6) nivel = 'Medio';
    else nivel = 'Alto';

    return {
      'nivel': nivel,
      'puntuacion': nivelRiesgo,
      'factores': factoresRiesgo,
    };
  }

  /// Genera resumen del análisis
  Map<String, dynamic> _generarResumenAnalisis(PrecioCalculado precioCalculado, Map<String, dynamic> analisisCostos) {
    return {
      'precioSugerido': precioCalculado.precioSugerido,
      'costoTotal': precioCalculado.costoTotal,
      'margenGanancia': precioCalculado.margenGanancia,
      'confianzaIA': precioCalculado.confianzaIA,
      'eficienciaCostos': analisisCostos['eficiencia'],
      'recomendacionGeneral': _generarRecomendacionGeneral(precioCalculado, analisisCostos),
    };
  }

  /// Genera recomendación general
  String _generarRecomendacionGeneral(PrecioCalculado precioCalculado, Map<String, dynamic> analisisCostos) {
    if (precioCalculado.confianzaIA > 0.7 && precioCalculado.margenGanancia > 30) {
      return 'Excelente cálculo, recomendamos proceder con este precio';
    } else if (precioCalculado.confianzaIA > 0.5) {
      return 'Buen cálculo, considera revisar algunos factores';
    } else {
      return 'Cálculo con baja confianza, considera agregar más datos';
    }
  }

  /// Evalúa la eficiencia de costos
  String _evaluarEficienciaCostos(double directos, double indirectos) {
    if (directos == 0) return 'Sin costos directos';
    
    final proporcion = indirectos / directos;
    if (proporcion < 0.3) return 'Muy eficiente';
    else if (proporcion < 0.6) return 'Eficiente';
    else if (proporcion < 1.0) return 'Moderada';
    else return 'Ineficiente';
  }

  /// Calcula confianza del análisis comparativo
  double _calcularConfianzaComparativo(int cantidadProductos) {
    if (cantidadProductos == 0) return 0.0;
    if (cantidadProductos < 3) return 0.3;
    if (cantidadProductos < 10) return 0.6;
    if (cantidadProductos < 20) return 0.8;
    return 0.9;
  }

  /// Guarda costos para futuras referencias
  Future<void> _guardarCostosParaReferencia(List<CostoDirecto> directos, List<CostoIndirecto> indirectos) async {
    try {
      // Guardar costos directos
      for (final costo in directos) {
        await _datosService.saveCostoDirecto(costo);
      }
      
      // Guardar costos indirectos
      for (final costo in indirectos) {
        await _datosService.saveCostoIndirecto(costo);
      }
      
      LoggingService.info('✅ Costos guardados para futuras referencias');
    } catch (e) {
      LoggingService.error('❌ Error guardando costos: $e');
    }
  }
}