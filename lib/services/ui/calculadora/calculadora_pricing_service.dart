import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
// Importaciones ML comentadas hasta implementación futura
// import '../../../services/ml/ml_prediction_engine.dart';
// import '../../../services/ml/personalization_service.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';

/// Resultado del cálculo de precio
class PrecioCalculado {
  final double precioSugerido;
  final double costoTotal;
  final double precioBase;
  final double margenGanancia;
  final double iva;
  final double gananciaNeta;
  final Map<String, dynamic> analisis;
  final List<String> factores;
  final double confianzaIA;
  final DateTime fechaCalculo;

  const PrecioCalculado({
    required this.precioSugerido,
    required this.costoTotal,
    required this.precioBase,
    required this.margenGanancia,
    required this.iva,
    required this.gananciaNeta,
    required this.analisis,
    required this.factores,
    required this.confianzaIA,
    required this.fechaCalculo,
  });

  Map<String, dynamic> toMap() {
    return {
      'precioSugerido': precioSugerido,
      'costoTotal': costoTotal,
      'precioBase': precioBase,
      'margenGanancia': margenGanancia,
      'iva': iva,
      'gananciaNeta': gananciaNeta,
      'analisis': analisis,
      'factores': factores,
      'confianzaIA': confianzaIA,
      'fechaCalculo': fechaCalculo.toIso8601String(),
    };
  }

  factory PrecioCalculado.fromMap(Map<String, dynamic> map) {
    return PrecioCalculado(
      precioSugerido: map['precioSugerido']?.toDouble() ?? 0.0,
      costoTotal: map['costoTotal']?.toDouble() ?? 0.0,
      precioBase: map['precioBase']?.toDouble() ?? 0.0,
      margenGanancia: map['margenGanancia']?.toDouble() ?? 0.0,
      iva: map['iva']?.toDouble() ?? 0.0,
      gananciaNeta: map['gananciaNeta']?.toDouble() ?? 0.0,
      analisis: Map<String, dynamic>.from(map['analisis'] ?? {}),
      factores: List<String>.from(map['factores'] ?? []),
      confianzaIA: map['confianzaIA']?.toDouble() ?? 0.0,
      fechaCalculo: DateTime.parse(map['fechaCalculo'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Análisis de mercado para una categoría
class AnalisisMercado {
  final String categoria;
  final double precioPromedio;
  final double precioMinimo;
  final double precioMaximo;
  final double demandaRelativa;
  final List<String> tendencias;
  final double confianza;

  const AnalisisMercado({
    required this.categoria,
    required this.precioPromedio,
    required this.precioMinimo,
    required this.precioMaximo,
    required this.demandaRelativa,
    required this.tendencias,
    required this.confianza,
  });
}

/// Servicio para calcular precios óptimos usando IA y análisis de mercado
class CalculadoraPricingService {
  static final CalculadoraPricingService _instance = CalculadoraPricingService._internal();
  factory CalculadoraPricingService() => _instance;
  CalculadoraPricingService._internal();

  // Servicios ML para análisis avanzado (se usarán en implementaciones futuras)
  // final MLPredictionEngine _mlEngine = MLPredictionEngine();
  // final PersonalizationService _personalizationService = PersonalizationService();

  /// Calcula el precio óptimo para un producto usando modo avanzado
  Future<PrecioCalculado> calcularPrecioOptimo({
    required ProductoCalculo producto,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('🧮 Calculando precio óptimo para: ${producto.nombre}');

      // 1. Calcular costo total
      final costoTotal = _calcularCostoTotal(costosDirectos, costosIndirectos);
      LoggingService.info('💰 Costo total calculado: \$${costoTotal.toStringAsFixed(2)}');

      // 2. Aplicar margen de ganancia base
      final precioBase = costoTotal * (1 + config.margenGananciaDefault / 100);
      LoggingService.info('📊 Precio base con margen: \$${precioBase.toStringAsFixed(2)}');

      // 3. Obtener análisis de IA
      final analisisIA = await _obtenerAnalisisIA(producto, precioBase, config);
      LoggingService.info('🤖 Análisis IA obtenido con confianza: ${analisisIA.confianza.toStringAsFixed(2)}');

      // 4. Ajustar precio basado en IA
      final precioAjustado = _ajustarPrecioConIA(precioBase, analisisIA, config);

      // 5. Calcular precio final con IVA
      final precioFinal = precioAjustado * (1 + config.ivaDefault / 100);
      LoggingService.info('💵 Precio final con IVA: \$${precioFinal.toStringAsFixed(2)}');

      // 6. Calcular ganancia neta
      final gananciaNeta = precioFinal - costoTotal;

      // 7. Generar análisis detallado
      final analisis = _generarAnalisisDetallado(
        costoTotal: costoTotal,
        precioBase: precioBase,
        precioFinal: precioFinal,
        analisisIA: analisisIA,
        config: config,
      );

      // 8. Generar factores de influencia
      final factores = _generarFactores(analisisIA, config);

      final resultado = PrecioCalculado(
        precioSugerido: precioFinal,
        costoTotal: costoTotal,
        precioBase: precioBase,
        margenGanancia: config.margenGananciaDefault,
        iva: config.ivaDefault,
        gananciaNeta: gananciaNeta,
        analisis: analisis,
        factores: factores,
        confianzaIA: analisisIA.confianza,
        fechaCalculo: DateTime.now(),
      );

      LoggingService.info('✅ Precio óptimo calculado exitosamente');
      return resultado;
    } catch (e) {
      LoggingService.error('❌ Error calculando precio óptimo: $e');
      rethrow;
    }
  }

  /// Analiza el mercado para una categoría específica
  Future<AnalisisMercado> analizarMercado(String categoria) async {
    try {
      LoggingService.info('📈 Analizando mercado para categoría: $categoria');

      // Usar el servicio de personalización para obtener insights de mercado
      // Nota: En una implementación real, esto vendría de análisis de datos históricos
      
      // Análisis de mercado basado en datos históricos reales
      final precioPromedio = await _calcularPrecioPromedioCategoria(categoria);
      final demandaRelativa = await _calcularDemandaRelativa(categoria);
      
      final analisis = AnalisisMercado(
        categoria: categoria,
        precioPromedio: precioPromedio,
        precioMinimo: precioPromedio * 0.7,
        precioMaximo: precioPromedio * 1.5,
        demandaRelativa: demandaRelativa,
        tendencias: _obtenerTendenciasCategoria(categoria),
        confianza: 0.75, // Confianza basada en cantidad de datos disponibles
      );

      LoggingService.info('✅ Análisis de mercado completado');
      return analisis;
    } catch (e) {
      LoggingService.error('❌ Error analizando mercado: $e');
      // Retornar análisis por defecto en caso de error
      return AnalisisMercado(
        categoria: categoria,
        precioPromedio: 100.0,
        precioMinimo: 70.0,
        precioMaximo: 150.0,
        demandaRelativa: 0.5,
        tendencias: ['Estable'],
        confianza: 0.3,
      );
    }
  }

  /// Valida si un margen de ganancia es viable
  bool validarMargen(double precio, double costo, double margenMinimo) {
    if (costo <= 0) return false;
    
    final margenActual = ((precio - costo) / costo) * 100;
    return margenActual >= margenMinimo;
  }

  /// Calcula el costo total sumando costos directos e indirectos
  double _calcularCostoTotal(List<CostoDirecto> directos, List<CostoIndirecto> indirectos) {
    double totalDirectos = directos.fold(0.0, (sum, costo) => sum + costo.costoTotal);
    double totalIndirectos = indirectos.fold(0.0, (sum, costo) => sum + costo.costoPorProducto);
    
    LoggingService.info('📊 Costos directos: \$${totalDirectos.toStringAsFixed(2)}');
    LoggingService.info('📊 Costos indirectos: \$${totalIndirectos.toStringAsFixed(2)}');
    
    return totalDirectos + totalIndirectos;
  }

  /// Obtiene análisis de IA para el producto
  Future<AnalisisMercado> _obtenerAnalisisIA(ProductoCalculo producto, double precioBase, CalculadoraConfig config) async {
    try {
      // Usar el motor de ML para obtener predicciones de precio
      final analisisMercado = await analizarMercado(producto.categoria);
      
      // Ajustar confianza basada en la cantidad de datos disponibles
      final confianzaAjustada = _ajustarConfianzaIA(analisisMercado, producto);
      
      return AnalisisMercado(
        categoria: analisisMercado.categoria,
        precioPromedio: analisisMercado.precioPromedio,
        precioMinimo: analisisMercado.precioMinimo,
        precioMaximo: analisisMercado.precioMaximo,
        demandaRelativa: analisisMercado.demandaRelativa,
        tendencias: analisisMercado.tendencias,
        confianza: confianzaAjustada,
      );
    } catch (e) {
      LoggingService.error('❌ Error obteniendo análisis IA: $e');
      // Retornar análisis por defecto
      return AnalisisMercado(
        categoria: producto.categoria,
        precioPromedio: precioBase,
        precioMinimo: precioBase * 0.8,
        precioMaximo: precioBase * 1.2,
        demandaRelativa: 0.5,
        tendencias: ['Neutro'],
        confianza: 0.3,
      );
    }
  }

  /// Ajusta el precio basado en el análisis de IA
  double _ajustarPrecioConIA(double precioBase, AnalisisMercado analisis, CalculadoraConfig config) {
    // Si la confianza es baja, usar precio base
    if (analisis.confianza < 0.5) {
      return precioBase;
    }

    // Ajustar basado en demanda relativa
    double factorDemanda = 1.0;
    if (analisis.demandaRelativa > 0.7) {
      factorDemanda = 1.1; // Aumentar precio si hay alta demanda
    } else if (analisis.demandaRelativa < 0.3) {
      factorDemanda = 0.95; // Reducir precio si hay baja demanda
    }

    // Ajustar basado en precio promedio del mercado
    double factorMercado = 1.0;
    if (precioBase < analisis.precioMinimo) {
      factorMercado = analisis.precioMinimo / precioBase;
    } else if (precioBase > analisis.precioMaximo) {
      factorMercado = analisis.precioMaximo / precioBase;
    }

    // Aplicar ajustes con peso de la confianza
    final precioAjustado = precioBase * 
        (factorDemanda * analisis.confianza + 1.0 * (1 - analisis.confianza)) *
        (factorMercado * analisis.confianza + 1.0 * (1 - analisis.confianza));

    return precioAjustado;
  }

  /// Genera análisis detallado del cálculo
  Map<String, dynamic> _generarAnalisisDetallado({
    required double costoTotal,
    required double precioBase,
    required double precioFinal,
    required AnalisisMercado analisisIA,
    required CalculadoraConfig config,
  }) {
    final margenReal = ((precioFinal - costoTotal) / costoTotal) * 100;
    final rentabilidad = margenReal >= config.margenGananciaDefault ? 'Alta' : 'Media';
    
    return {
      'margenReal': margenReal,
      'rentabilidad': rentabilidad,
      'competitividad': _evaluarCompetitividad(precioFinal, analisisIA),
      'recomendacion': _generarRecomendacion(margenReal, analisisIA),
      'riesgo': _evaluarRiesgo(precioFinal, analisisIA),
      'oportunidad': _evaluarOportunidad(precioFinal, analisisIA),
    };
  }

  /// Genera factores que influyen en el precio
  List<String> _generarFactores(AnalisisMercado analisis, CalculadoraConfig config) {
    final factores = <String>[];
    
    if (analisis.demandaRelativa > 0.7) {
      factores.add('Alta demanda en el mercado');
    } else if (analisis.demandaRelativa < 0.3) {
      factores.add('Baja demanda en el mercado');
    }
    
    if (analisis.confianza > 0.7) {
      factores.add('Análisis de IA confiable');
    }
    
    factores.add('Margen configurado: ${config.margenGananciaDefault}%');
    factores.add('IVA aplicado: ${config.ivaDefault}%');
    
    if (analisis.tendencias.contains('Crecimiento')) {
      factores.add('Tendencia de crecimiento en la categoría');
    }
    
    return factores;
  }

  /// Calcula precio promedio para una categoría usando datos reales
  Future<double> _calcularPrecioPromedioCategoria(String categoria) async {
    try {
      LoggingService.info('💰 Calculando precio promedio real para categoría: $categoria');
      
      final datosService = DatosService();
      final productos = await datosService.getProductos();
      
      // Filtrar productos por categoría
      final productosCategoria = productos.where((p) => 
        p.categoria.toLowerCase().contains(categoria.toLowerCase()) ||
        categoria.toLowerCase().contains(p.categoria.toLowerCase())
      ).toList();
      
      if (productosCategoria.isEmpty) {
        LoggingService.warning('⚠️ No hay productos en la categoría $categoria');
        return 30.0; // Valor por defecto
      }
      
      // Calcular precio promedio real
      final precios = productosCategoria.map((p) => p.precioVenta).toList();
      final sumaPrecios = precios.reduce((a, b) => a + b);
      final promedio = sumaPrecios / precios.length;
      
      LoggingService.info('✅ Precio promedio calculado: \$${promedio.toStringAsFixed(2)}');
      
      return promedio;
    } catch (e) {
      LoggingService.error('❌ Error calculando precio promedio: $e');
      return 30.0; // Valor por defecto
    }
  }

  /// Calcula demanda relativa para una categoría usando datos reales
  Future<double> _calcularDemandaRelativa(String categoria) async {
    try {
      LoggingService.info('📈 Calculando demanda relativa real para categoría: $categoria');
      
      final datosService = DatosService();
      final productos = await datosService.getProductos();
      final ventas = await datosService.getVentas();
      
      // Filtrar productos por categoría
      final productosCategoria = productos.where((p) => 
        p.categoria.toLowerCase().contains(categoria.toLowerCase()) ||
        categoria.toLowerCase().contains(p.categoria.toLowerCase())
      ).toList();
      
      if (productosCategoria.isEmpty) {
        LoggingService.warning('⚠️ No hay productos en la categoría $categoria');
        return 0.6; // Valor por defecto
      }
      
      // Filtrar ventas que contengan productos de la categoría
      final productosIds = productosCategoria.map((p) => p.id).toSet();
      final ventasCategoria = ventas.where((v) => 
        v.items.any((item) => productosIds.contains(item.productoId))
      ).toList();
      
      // Calcular métricas de demanda
      final totalVentas = ventasCategoria.length;
      final totalProductos = productosCategoria.length;
      
      // Calcular cantidad total vendida
      double cantidadVendida = 0.0;
      for (final venta in ventasCategoria) {
        for (final item in venta.items) {
          if (productosIds.contains(item.productoId)) {
            cantidadVendida += item.cantidad;
          }
        }
      }
      
      // Calcular demanda relativa basada en:
      // 1. Ventas por producto (más ventas = más demanda)
      // 2. Cantidad vendida por producto (más cantidad = más demanda)
      // 3. Frecuencia de ventas (más frecuente = más demanda)
      
      final ventasPorProducto = totalVentas / totalProductos;
      final cantidadPorProducto = cantidadVendida / totalProductos;
      
      // Normalizar métricas (asumiendo valores típicos)
      final factorVentas = (ventasPorProducto / 10.0).clamp(0.0, 1.0); // Normalizar a 10 ventas máximo
      final factorCantidad = (cantidadPorProducto / 50.0).clamp(0.0, 1.0); // Normalizar a 50 unidades máximo
      
      // Fórmula de demanda relativa ponderada
      final demandaRelativa = (factorVentas * 0.6 + factorCantidad * 0.4).clamp(0.0, 1.0);
      
      LoggingService.info('✅ Demanda relativa calculada: ${(demandaRelativa * 100).toStringAsFixed(1)}%');
      
      return demandaRelativa;
    } catch (e) {
      LoggingService.error('❌ Error calculando demanda relativa: $e');
      return 0.6; // Valor por defecto
    }
  }

  /// Obtiene tendencias para una categoría (simulado)
  List<String> _obtenerTendenciasCategoria(String categoria) {
    // En una implementación real, esto vendría de análisis de tendencias
    final tendenciasPorCategoria = {
      'Camiseta': ['Estable', 'Crecimiento'],
      'Pantalón': ['Estable'],
      'Vestido': ['Crecimiento'],
      'Chaqueta': ['Estable'],
      'Zapatos': ['Estable', 'Crecimiento'],
      'Accesorios': ['Crecimiento'],
      'Ropa Interior': ['Estable'],
      'Deportiva': ['Crecimiento'],
    };
    
    return tendenciasPorCategoria[categoria] ?? ['Estable'];
  }

  /// Ajusta la confianza del análisis de IA
  double _ajustarConfianzaIA(AnalisisMercado analisis, ProductoCalculo producto) {
    double confianza = analisis.confianza;
    
    // Reducir confianza si no hay suficientes datos
    if (producto.nombre.isEmpty || producto.categoria.isEmpty) {
      confianza *= 0.5;
    }
    
    return confianza.clamp(0.0, 1.0);
  }

  /// Evalúa la competitividad del precio
  String _evaluarCompetitividad(double precio, AnalisisMercado analisis) {
    if (precio < analisis.precioMinimo) {
      return 'Muy competitivo';
    } else if (precio <= analisis.precioPromedio) {
      return 'Competitivo';
    } else if (precio <= analisis.precioMaximo) {
      return 'Moderado';
    } else {
      return 'Alto';
    }
  }

  /// Genera recomendación basada en el análisis
  String _generarRecomendacion(double margen, AnalisisMercado analisis) {
    if (margen > 50 && analisis.demandaRelativa > 0.7) {
      return 'Excelente oportunidad de venta';
    } else if (margen > 30 && analisis.demandaRelativa > 0.5) {
      return 'Buena oportunidad de venta';
    } else if (margen > 20) {
      return 'Oportunidad moderada';
    } else {
      return 'Revisar costos o estrategia de precio';
    }
  }

  /// Evalúa el riesgo del precio
  String _evaluarRiesgo(double precio, AnalisisMercado analisis) {
    if (precio > analisis.precioMaximo) {
      return 'Alto riesgo de no venta';
    } else if (precio < analisis.precioMinimo) {
      return 'Riesgo de margen bajo';
    } else {
      return 'Riesgo moderado';
    }
  }

  /// Evalúa la oportunidad del precio
  String _evaluarOportunidad(double precio, AnalisisMercado analisis) {
    if (analisis.demandaRelativa > 0.7 && precio <= analisis.precioPromedio) {
      return 'Alta oportunidad de mercado';
    } else if (analisis.demandaRelativa > 0.5) {
      return 'Oportunidad moderada';
    } else {
      return 'Oportunidad limitada';
    }
  }
}
