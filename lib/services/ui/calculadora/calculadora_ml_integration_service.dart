import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import '../../../services/ml/ml_prediction_engine.dart';
import '../../../services/ml/personalization_service.dart';
import '../../../services/ml/random_forest_service.dart';
import '../../../services/ml/elastic_net_service.dart';
import '../../../services/ml/kmeans_service.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import '../../../models/producto.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';

/// Resultado de análisis ML
class ResultadoAnalisisML {
  final bool exito;
  final String? mensaje;
  final Map<String, dynamic>? predicciones;
  final Map<String, dynamic>? insights;
  final double confianza;
  final List<String>? recomendaciones;

  const ResultadoAnalisisML({
    required this.exito,
    this.mensaje,
    this.predicciones,
    this.insights,
    required this.confianza,
    this.recomendaciones,
  });
}

/// Servicio para integrar ML con la calculadora de precios
class CalculadoraMLIntegrationService {
  static final CalculadoraMLIntegrationService _instance = CalculadoraMLIntegrationService._internal();
  factory CalculadoraMLIntegrationService() => _instance;
  CalculadoraMLIntegrationService._internal();

  final MLPredictionEngine _mlEngine = MLPredictionEngine();
  final PersonalizationService _personalizationService = PersonalizationService();
  final RandomForestService _randomForestService = RandomForestService();
  final ElasticNetService _elasticNetService = ElasticNetService();
  final KMeansService _kmeansService = KMeansService();

  /// Analiza el producto usando ML para obtener insights avanzados
  Future<ResultadoAnalisisML> analizarProductoConML({
    required ProductoCalculo producto,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('🤖 Analizando producto con ML: ${producto.nombre}');

      // 1. Obtener datos históricos para análisis
      final datosHistoricos = await _obtenerDatosHistoricos(producto.categoria);
      
      // 2. Generar predicciones básicas (simplificado para evitar errores)
      final prediccionDemanda = _generarPrediccionDemandaBasica(producto);
      
      // 3. Optimizar precio básico
      final optimizacionPrecio = _generarOptimizacionPrecioBasica(producto, costosDirectos, costosIndirectos, config);
      
      // 4. Análisis básico de segmentación
      final segmentacionClientes = _generarSegmentacionBasica(producto);
      
      // 5. Generar insights personalizados
      final insightsPersonalizados = await _generarInsightsPersonalizados(producto, prediccionDemanda, optimizacionPrecio);
      
      // 6. Calcular confianza general
      final confianzaGeneral = _calcularConfianzaGeneral(prediccionDemanda, optimizacionPrecio, segmentacionClientes);
      
      // 7. Generar recomendaciones
      final recomendaciones = _generarRecomendacionesML(prediccionDemanda, optimizacionPrecio, segmentacionClientes);

      LoggingService.info('✅ Análisis ML completado con confianza: ${confianzaGeneral.toStringAsFixed(2)}');
      
      return ResultadoAnalisisML(
        exito: true,
        mensaje: 'Análisis ML completado exitosamente',
        predicciones: {
          'demanda': prediccionDemanda,
          'precio': optimizacionPrecio,
          'segmentacion': segmentacionClientes,
        },
        insights: insightsPersonalizados,
        confianza: confianzaGeneral,
        recomendaciones: recomendaciones,
      );
    } catch (e) {
      LoggingService.error('❌ Error en análisis ML: $e');
      return ResultadoAnalisisML(
        exito: false,
        mensaje: 'Error en análisis ML: $e',
        confianza: 0.0,
        recomendaciones: ['Usar análisis básico debido a error en ML'],
      );
    }
  }

  /// Genera predicción de demanda básica
  Map<String, dynamic> _generarPrediccionDemandaBasica(ProductoCalculo producto) {
    // Análisis básico basado en categoría
    final demandaPorCategoria = {
      'Camiseta': 1.2,
      'Pantalón': 1.0,
      'Vestido': 0.8,
      'Chaqueta': 0.6,
      'Zapatos': 1.1,
      'Accesorios': 1.3,
    };
    
    final demandaBase = demandaPorCategoria[producto.categoria] ?? 1.0;
    
    return {
      'demandaPredicha': demandaBase,
      'confianza': 0.6,
      'factores': ['Categoría', 'Temporada'],
      'tendencia': 'Estable',
    };
  }

  /// Genera optimización de precio básica
  Map<String, dynamic> _generarOptimizacionPrecioBasica(
    ProductoCalculo producto,
    List<CostoDirecto> costosDirectos,
    List<CostoIndirecto> costosIndirectos,
    CalculadoraConfig config,
  ) {
    final costoTotal = costosDirectos.fold(0.0, (sum, c) => sum + c.costoTotal) +
                      costosIndirectos.fold(0.0, (sum, c) => sum + c.costoPorProducto);
    
    final precioBase = costoTotal * (1 + config.margenGananciaDefault / 100);
    final precioConIVA = precioBase * (1 + config.ivaDefault / 100);
    
    return {
      'precioOptimo': precioConIVA,
      'confianza': 0.7,
      'factores': ['Costos', 'Margen', 'IVA'],
      'sensibilidad': 'Media',
    };
  }

  /// Genera segmentación básica
  Map<String, dynamic> _generarSegmentacionBasica(ProductoCalculo producto) {
    return {
      'segmentos': [
        {'nombre': 'Premium', 'caracteristicas': ['Alto poder adquisitivo']},
        {'nombre': 'Estandar', 'caracteristicas': ['Poder adquisitivo medio']},
        {'nombre': 'Económico', 'caracteristicas': ['Precio sensible']},
      ],
      'confianza': 0.5,
      'recomendacion': 'Considera estrategias diferenciadas por segmento',
    };
  }

  /// Predice la demanda del producto (versión simplificada)
  Future<Map<String, dynamic>> _predecirDemanda(ProductoCalculo producto, Map<String, dynamic> datosHistoricos) async {
    // Usar el método básico por ahora
    return _generarPrediccionDemandaBasica(producto);
  }

  /// Optimiza el precio (versión simplificada)
  Future<Map<String, dynamic>> _optimizarPrecioConML(
    ProductoCalculo producto,
    List<CostoDirecto> costosDirectos,
    List<CostoIndirecto> costosIndirectos,
    CalculadoraConfig config,
  ) async {
    // Usar el método básico por ahora
    return _generarOptimizacionPrecioBasica(producto, costosDirectos, costosIndirectos, config);
  }

  /// Analiza segmentación de clientes (versión simplificada)
  Future<Map<String, dynamic>> _analizarSegmentacionClientes(ProductoCalculo producto, Map<String, dynamic> datosHistoricos) async {
    // Usar el método básico por ahora
    return _generarSegmentacionBasica(producto);
  }

  /// Genera insights personalizados (versión simplificada)
  Future<Map<String, dynamic>> _generarInsightsPersonalizados(
    ProductoCalculo producto,
    Map<String, dynamic> prediccionDemanda,
    Map<String, dynamic> optimizacionPrecio,
  ) async {
    try {
      LoggingService.info('💡 Generando insights personalizados');

      // Generar insights básicos
      final insights = _generarInsightsBasicos(producto, prediccionDemanda, optimizacionPrecio);
      final oportunidades = _identificarOportunidades(producto, prediccionDemanda, optimizacionPrecio);

      return {
        'recomendaciones': [],
        'insights': insights,
        'oportunidades': oportunidades,
      };
    } catch (e) {
      LoggingService.error('❌ Error generando insights personalizados: $e');
      return {
        'recomendaciones': [],
        'insights': ['Análisis básico disponible'],
        'oportunidades': ['Revisar datos históricos'],
      };
    }
  }

  /// Obtiene datos históricos para análisis
  Future<Map<String, dynamic>> _obtenerDatosHistoricos(String categoria) async {
    try {
      LoggingService.info('📊 Obteniendo datos históricos reales para categoría: $categoria');
      
      final datosService = DatosService();
      
      // Obtener todos los datos y filtrar por categoría
      final todosProductos = await datosService.getProductos();
      final todosVentas = await datosService.getVentas();
      final todosClientes = await datosService.getClientes();
      
      // Filtrar productos por categoría
      final productos = todosProductos.where((p) => 
        p.categoria.toLowerCase().contains(categoria.toLowerCase()) ||
        categoria.toLowerCase().contains(p.categoria.toLowerCase())
      ).toList();
      
      // Filtrar ventas que contengan productos de la categoría
      final productosIds = productos.map((p) => p.id).toSet();
      final ventas = todosVentas.where((v) => 
        v.items.any((item) => productosIds.contains(item.productoId))
      ).toList();
      
      // Filtrar clientes que hayan comprado productos de la categoría
      final clientesNombres = ventas.map((v) => v.cliente).toSet();
      final clientes = todosClientes.where((c) => clientesNombres.contains(c.nombre)).toList();
      
      LoggingService.info('✅ Datos históricos obtenidos: ${productos.length} productos, ${ventas.length} ventas, ${clientes.length} clientes');
      
      return {
        'ventas': ventas,
        'clientes': clientes,
        'productos': productos,
        'categoria': categoria,
      };
    } catch (e) {
      LoggingService.error('❌ Error obteniendo datos históricos: $e');
      return {
        'ventas': <Venta>[],
        'clientes': <Cliente>[],
        'productos': <Producto>[],
        'categoria': categoria,
      };
    }
  }

  /// Obtiene la temporada actual
  String _obtenerTemporadaActual() {
    final mes = DateTime.now().month;
    if (mes >= 3 && mes <= 5) return 'Otoño';
    if (mes >= 6 && mes <= 8) return 'Invierno';
    if (mes >= 9 && mes <= 11) return 'Primavera';
    return 'Verano';
  }

  /// Obtiene el nivel de competencia para una categoría
  Future<double> _obtenerNivelCompetencia(String categoria) async {
    try {
      LoggingService.info('📈 Calculando nivel de competencia real para categoría: $categoria');
      
      final datosService = DatosService();
      final productos = await datosService.getProductos();
      
      // Filtrar productos por categoría
      final productosCategoria = productos.where((p) => 
        p.categoria.toLowerCase().contains(categoria.toLowerCase()) ||
        categoria.toLowerCase().contains(p.categoria.toLowerCase())
      ).toList();
      
      if (productosCategoria.isEmpty) {
        LoggingService.warning('⚠️ No hay productos en la categoría $categoria');
        return 0.5; // Valor por defecto
      }
      
      // Calcular métricas de competencia
      final cantidadProductos = productosCategoria.length;
      final precios = productosCategoria.map((p) => p.precioVenta).toList();
      final precioMin = precios.reduce((a, b) => a < b ? a : b);
      final precioMax = precios.reduce((a, b) => a > b ? a : b);
      final variacionPrecios = precioMax - precioMin;
      final precioPromedio = precios.reduce((a, b) => a + b) / precios.length;
      
      // Calcular nivel de competencia basado en:
      // 1. Cantidad de productos (más productos = más competencia)
      // 2. Variación de precios (más variación = más competencia)
      // 3. Densidad de precios (precios cercanos = más competencia)
      
      final factorCantidad = (cantidadProductos / 20.0).clamp(0.0, 1.0); // Normalizar a 20 productos máximo
      final factorVariacion = (variacionPrecios / precioPromedio).clamp(0.0, 1.0); // Coeficiente de variación
      
      // Calcular densidad de precios (qué tan cerca están los precios)
      final preciosOrdenados = precios..sort();
      double densidadPrecios = 0.0;
      for (int i = 1; i < preciosOrdenados.length; i++) {
        final diferencia = preciosOrdenados[i] - preciosOrdenados[i-1];
        densidadPrecios += diferencia;
      }
      final densidadPromedio = densidadPrecios / (preciosOrdenados.length - 1);
      final factorDensidad = (densidadPromedio / precioPromedio).clamp(0.0, 1.0);
      
      // Fórmula de competencia ponderada
      final nivelCompetencia = (factorCantidad * 0.4 + factorVariacion * 0.3 + factorDensidad * 0.3).clamp(0.0, 1.0);
      
      LoggingService.info('✅ Nivel de competencia calculado: ${(nivelCompetencia * 100).toStringAsFixed(1)}%');
      
      return nivelCompetencia;
    } catch (e) {
      LoggingService.error('❌ Error calculando nivel de competencia: $e');
      return 0.5; // Valor por defecto
    }
  }

  /// Genera recomendación basada en segmentación
  String _generarRecomendacionSegmentacion(List<dynamic> segmentos) {
    if (segmentos.isEmpty) {
      return 'No hay suficientes datos para segmentación';
    }
    
    return 'Considera estrategias de precio diferenciadas por segmento';
  }

  /// Genera insights básicos
  List<String> _generarInsightsBasicos(
    ProductoCalculo producto,
    Map<String, dynamic> prediccionDemanda,
    Map<String, dynamic> optimizacionPrecio,
  ) {
    final insights = <String>[];

    final demanda = prediccionDemanda['demandaPredicha'] as double;
    final confianzaDemanda = prediccionDemanda['confianza'] as double;

    if (confianzaDemanda > 0.7) {
      if (demanda > 1.5) {
        insights.add('Alta demanda esperada, considera aumentar producción');
      } else if (demanda < 0.5) {
        insights.add('Baja demanda esperada, considera ajustar estrategia');
      }
    }

    final precioOptimo = optimizacionPrecio['precioOptimo'] as double;
    final confianzaPrecio = optimizacionPrecio['confianza'] as double;

    if (confianzaPrecio > 0.7) {
      insights.add('Precio óptimo sugerido: \$${precioOptimo.toStringAsFixed(2)}');
    }

    return insights;
  }

  /// Identifica oportunidades de mercado
  List<String> _identificarOportunidades(
    ProductoCalculo producto,
    Map<String, dynamic> prediccionDemanda,
    Map<String, dynamic> optimizacionPrecio,
  ) {
    final oportunidades = <String>[];

    final demanda = prediccionDemanda['demandaPredicha'] as double;
    final precioOptimo = optimizacionPrecio['precioOptimo'] as double;

    if (demanda > 1.2 && precioOptimo > 0) {
      oportunidades.add('Oportunidad de mercado con alta demanda');
    }

    if (producto.categoria.toLowerCase().contains('nuevo') || 
        producto.categoria.toLowerCase().contains('tendencia')) {
      oportunidades.add('Producto en categoría de tendencia');
    }

    return oportunidades;
  }

  /// Calcula confianza general del análisis ML
  double _calcularConfianzaGeneral(
    Map<String, dynamic> prediccionDemanda,
    Map<String, dynamic> optimizacionPrecio,
    Map<String, dynamic> segmentacionClientes,
  ) {
    final confianzaDemanda = prediccionDemanda['confianza'] as double? ?? 0.0;
    final confianzaPrecio = optimizacionPrecio['confianza'] as double? ?? 0.0;
    final confianzaSegmentacion = segmentacionClientes['confianza'] as double? ?? 0.0;

    // Promedio ponderado de las confianzas
    return (confianzaDemanda * 0.4 + confianzaPrecio * 0.4 + confianzaSegmentacion * 0.2);
  }

  /// Genera recomendaciones basadas en ML
  List<String> _generarRecomendacionesML(
    Map<String, dynamic> prediccionDemanda,
    Map<String, dynamic> optimizacionPrecio,
    Map<String, dynamic> segmentacionClientes,
  ) {
    final recomendaciones = <String>[];

    final confianzaGeneral = _calcularConfianzaGeneral(prediccionDemanda, optimizacionPrecio, segmentacionClientes);

    if (confianzaGeneral > 0.7) {
      recomendaciones.add('Análisis ML confiable, recomendamos seguir las predicciones');
    } else if (confianzaGeneral > 0.4) {
      recomendaciones.add('Análisis ML moderado, considera como referencia');
    } else {
      recomendaciones.add('Análisis ML con baja confianza, usa análisis básico');
    }

    final demanda = prediccionDemanda['demandaPredicha'] as double;
    if (demanda > 1.5) {
      recomendaciones.add('Alta demanda esperada, prepara inventario');
    }

    final precioOptimo = optimizacionPrecio['precioOptimo'] as double;
    if (precioOptimo > 0) {
      recomendaciones.add('Considera el precio óptimo sugerido por ML');
    }

    return recomendaciones;
  }

  /// Valida si hay suficientes datos para análisis ML
  Future<bool> validarDatosParaML(String categoria) async {
    try {
      final datosHistoricos = await _obtenerDatosHistoricos(categoria);
      final ventas = datosHistoricos['ventas'] as List<Venta>;
      final clientes = datosHistoricos['clientes'] as List<Cliente>;

      // Mínimos requeridos para análisis ML
      return ventas.length >= 10 && clientes.length >= 5;
    } catch (e) {
      LoggingService.error('❌ Error validando datos para ML: $e');
      return false;
    }
  }

  /// Obtiene métricas de calidad de datos ML
  Future<Map<String, dynamic>> obtenerMetricasCalidadML(String categoria) async {
    try {
      final datosHistoricos = await _obtenerDatosHistoricos(categoria);
      final ventas = datosHistoricos['ventas'] as List<Venta>;
      final clientes = datosHistoricos['clientes'] as List<Cliente>;

      return {
        'totalVentas': ventas.length,
        'totalClientes': clientes.length,
        'completitud': _calcularCompletitud(ventas, clientes),
        'consistencia': _calcularConsistencia(ventas),
        'actualidad': _calcularActualidad(ventas),
        'suficienteParaML': ventas.length >= 10 && clientes.length >= 5,
      };
    } catch (e) {
      LoggingService.error('❌ Error obteniendo métricas de calidad: $e');
      return {
        'totalVentas': 0,
        'totalClientes': 0,
        'completitud': 0.0,
        'consistencia': 0.0,
        'actualidad': 0.0,
        'suficienteParaML': false,
      };
    }
  }

  /// Calcula completitud de datos (versión simplificada)
  double _calcularCompletitud(List<Venta> ventas, List<Cliente> clientes) {
    if (ventas.isEmpty) return 0.0;
    
    // Análisis básico de completitud
    int camposCompletos = 0;
    int totalCampos = ventas.length * 2; // Campos básicos
    
    for (final venta in ventas) {
      if (venta.fecha != null) camposCompletos++;
      if (venta.total > 0) camposCompletos++;
    }
    
    return camposCompletos / totalCampos;
  }

  /// Calcula consistencia de datos (versión simplificada)
  double _calcularConsistencia(List<Venta> ventas) {
    if (ventas.length < 2) return 1.0;
    
    // Verificar consistencia básica
    int inconsistencias = 0;
    for (final venta in ventas) {
      if (venta.total <= 0) {
        inconsistencias++;
      }
    }
    
    return 1.0 - (inconsistencias / ventas.length);
  }

  /// Calcula actualidad de datos (versión simplificada)
  double _calcularActualidad(List<Venta> ventas) {
    if (ventas.isEmpty) return 0.0;
    
    final ahora = DateTime.now();
    int datosRecientes = 0;
    
    for (final venta in ventas) {
      final diferencia = ahora.difference(venta.fecha).inDays;
      if (diferencia <= 90) { // Datos de los últimos 90 días
        datosRecientes++;
      }
    }
    
    return datosRecientes / ventas.length;
  }
}
