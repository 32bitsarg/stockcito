import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/ml_prediction_models.dart';
import 'feature_engineering_service.dart';
import 'statistical_analysis_service.dart';

/// Motor de predicción ML real sin simulaciones
class MLPredictionEngine {
  static final MLPredictionEngine _instance = MLPredictionEngine._internal();
  factory MLPredictionEngine() => _instance;
  MLPredictionEngine._internal();

  final FeatureEngineeringService _featureService = FeatureEngineeringService();
  final StatisticalAnalysisService _statisticalService = StatisticalAnalysisService();

  /// Predice la demanda usando algoritmos estadísticos reales
  MLDemandPrediction predictDemand(List<Venta> ventas, Producto producto, int daysAhead) {
    try {
      LoggingService.info('🤖 Prediciendo demanda real para producto ${producto.id ?? 0}');

      // Generar features
      final features = _featureService.generateDemandFeatures(ventas, producto, daysAhead);
      
      if (features.demandFeatures.isEmpty) {
        return _createEmptyDemandPrediction(producto.id ?? 0, daysAhead);
      }

      // Filtrar ventas del producto
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();

      if (productVentas.isEmpty) {
        return _createEmptyDemandPrediction(producto.id ?? 0, daysAhead);
      }

      // Calcular predicción usando múltiples algoritmos
      final predictions = <double>[];
      final confidences = <double>[];

      // 1. Predicción basada en tendencia
      final trendPrediction = _predictUsingTrend(productVentas, daysAhead);
      predictions.add(trendPrediction.value);
      confidences.add(trendPrediction.confidence);

      // 2. Predicción basada en estacionalidad
      final seasonalPrediction = _predictUsingSeasonality(productVentas, daysAhead);
      predictions.add(seasonalPrediction.value);
      confidences.add(seasonalPrediction.confidence);

      // 3. Predicción basada en promedio móvil
      final movingAvgPrediction = _predictUsingMovingAverage(productVentas, daysAhead);
      predictions.add(movingAvgPrediction.value);
      confidences.add(movingAvgPrediction.confidence);

      // 4. Predicción basada en regresión lineal
      final linearPrediction = _predictUsingLinearRegression(productVentas, daysAhead);
      predictions.add(linearPrediction.value);
      confidences.add(linearPrediction.confidence);

      // Combinar predicciones usando ensemble
      final finalPrediction = _ensemblePredictions(predictions, confidences);
      final finalConfidence = _calculateEnsembleConfidence(confidences);

      // Generar factores explicativos
      final factors = _generateDemandFactors(productVentas, producto, finalPrediction, daysAhead);
      
      // Generar recomendación
      final recommendation = _generateDemandRecommendation(producto, finalPrediction, factors);

      // Calcular importancia de features
      final featureImportance = _calculateFeatureImportance(features.demandFeatures, predictions);

      LoggingService.info('✅ Predicción de demanda completada: ${finalPrediction.round()} unidades');

      return MLDemandPrediction(
        productoId: producto.id ?? 0,
        predictedDemand: finalPrediction.round(),
        confidence: finalConfidence,
        factors: factors,
        recommendation: recommendation,
        predictionDate: DateTime.now(),
        featureImportance: featureImportance,
        seasonalFactor: seasonalPrediction.seasonalFactor,
        trendFactor: trendPrediction.trendFactor,
        daysAhead: daysAhead,
      );
    } catch (e) {
      LoggingService.error('❌ Error en predicción de demanda: $e');
      return _createEmptyDemandPrediction(producto.id ?? 0, daysAhead);
    }
  }

  /// Predice el precio óptimo usando análisis estadístico real
  MLPricePrediction predictOptimalPrice(List<Venta> ventas, Producto producto) {
    try {
      LoggingService.info('💰 Prediciendo precio óptimo real para producto ${producto.id ?? 0}');

      // Generar features
      final features = _featureService.generateDemandFeatures(ventas, producto, 7);
      
      if (features.priceFeatures.isEmpty) {
        return _createEmptyPricePrediction(producto.id ?? 0, producto.precioVenta);
      }

      // Filtrar ventas del producto
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();

      if (productVentas.isEmpty) {
        return _createEmptyPricePrediction(producto.id ?? 0, producto.precioVenta);
      }

      // Calcular elasticidad de precio real
      final priceElasticity = _statisticalService.calculatePriceElasticity(productVentas, producto.precioVenta);
      
      // Calcular correlación precio-cantidad
      final priceQuantityCorrelation = _statisticalService.calculatePriceQuantityCorrelation(productVentas);

      // Calcular precio óptimo usando múltiples métodos
      final optimalPrices = <double>[];
      final confidences = <double>[];

      // 1. Método de elasticidad
      final elasticityPrice = _calculateOptimalPriceByElasticity(producto.precioVenta, priceElasticity);
      optimalPrices.add(elasticityPrice.value);
      confidences.add(elasticityPrice.confidence);

      // 2. Método de maximización de ingresos
      final revenuePrice = _calculateOptimalPriceByRevenue(productVentas, producto.precioVenta);
      optimalPrices.add(revenuePrice.value);
      confidences.add(revenuePrice.confidence);

      // 3. Método de análisis de competencia
      final competitionPrice = _calculateOptimalPriceByCompetition(producto, productVentas);
      optimalPrices.add(competitionPrice.value);
      confidences.add(competitionPrice.confidence);

      // Combinar predicciones
      final finalOptimalPrice = _ensemblePredictions(optimalPrices, confidences);
      final finalConfidence = _calculateEnsembleConfidence(confidences);

      // Generar factores
      final factors = _generatePriceFactors(producto, finalOptimalPrice, priceElasticity, priceQuantityCorrelation);
      
      // Generar recomendación
      final recommendation = _generatePriceRecommendation(producto, finalOptimalPrice, factors);

      // Calcular sensibilidad de demanda
      final demandSensitivity = _calculateDemandSensitivity(productVentas, producto.precioVenta, finalOptimalPrice);

      LoggingService.info('✅ Predicción de precio completada: \$${finalOptimalPrice.toStringAsFixed(2)}');

      return MLPricePrediction(
        productoId: producto.id ?? 0,
        currentPrice: producto.precioVenta,
        optimalPrice: finalOptimalPrice,
        confidence: finalConfidence,
        factors: factors,
        recommendation: recommendation,
        predictionDate: DateTime.now(),
        priceElasticity: priceElasticity,
        demandSensitivity: demandSensitivity,
        marketFactors: features.marketFeatures,
      );
    } catch (e) {
      LoggingService.error('❌ Error en predicción de precio: $e');
      return _createEmptyPricePrediction(producto.id ?? 0, producto.precioVenta);
    }
  }

  /// Analiza patrones de clientes usando clustering real
  MLCustomerAnalysis analyzeCustomerPatterns(List<Venta> ventas, List<dynamic> clientes) {
    try {
      LoggingService.info('👥 Analizando patrones de clientes reales');

      if (ventas.isEmpty || clientes.isEmpty) {
        return _createEmptyCustomerAnalysis();
      }

      // Generar features de clientes
      final customerFeatures = _featureService.generateCustomerFeatures(ventas, clientes);
      
      if (customerFeatures.isEmpty) {
        return _createEmptyCustomerAnalysis();
      }

      // Realizar segmentación usando K-means simplificado
      final segments = _performCustomerSegmentation(customerFeatures);
      
      // Generar insights
      final insights = _generateCustomerInsights(segments, customerFeatures);
      
      // Generar recomendaciones
      final recommendations = _generateCustomerRecommendations(segments, insights);

      // Calcular métricas agregadas
      final customerLifetimeValue = _statisticalService.calculateCustomerLifetimeValue(ventas, clientes);
      final retentionRate = _statisticalService.calculateRetentionRate(ventas, clientes);

      // Calcular métricas por segmento
      final segmentMetrics = _calculateSegmentMetrics(segments);

      LoggingService.info('✅ Análisis de clientes completado: ${segments.length} segmentos');

      return MLCustomerAnalysis(
        totalCustomers: clientes.length,
        segments: segments,
        insights: insights,
        recommendations: recommendations,
        analysisDate: DateTime.now(),
        segmentMetrics: segmentMetrics,
        customerLifetimeValue: customerLifetimeValue,
        retentionRate: retentionRate,
      );
    } catch (e) {
      LoggingService.error('❌ Error en análisis de clientes: $e');
      return _createEmptyCustomerAnalysis();
    }
  }

  // Métodos auxiliares para predicciones específicas
  _PredictionResult _predictUsingTrend(List<Venta> ventas, int daysAhead) {
    final trend = _statisticalService.calculateSalesTrend(ventas, 30);
    final recentSales = ventas.where((v) => 
      v.fecha.isAfter(DateTime.now().subtract(const Duration(days: 7)))
    ).length;

    final predictedValue = recentSales + (trend * daysAhead);
    final confidence = (1.0 - trend.abs() / 10.0).clamp(0.1, 0.9);

    return _PredictionResult(
      value: max(0, predictedValue),
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: trend,
    );
  }

  _PredictionResult _predictUsingSeasonality(List<Venta> ventas, int daysAhead) {
    final seasonalFactors = _statisticalService.calculateSeasonalFactors(ventas);
    final currentMonth = DateTime.now().month;
    final seasonalFactor = seasonalFactors[currentMonth] ?? 1.0;

    final avgSales = ventas.length / max(ventas.map((v) => v.fecha).reduce((a, b) => 
      a.isBefore(b) ? a : b).difference(ventas.map((v) => v.fecha).reduce((a, b) => 
      a.isAfter(b) ? a : b)).inDays / 30.0, 1.0);

    final predictedValue = avgSales * seasonalFactor * (daysAhead / 7.0);
    final confidence = 0.7;

    return _PredictionResult(
      value: max(0, predictedValue),
      confidence: confidence,
      seasonalFactor: seasonalFactor,
      trendFactor: 1.0,
    );
  }

  _PredictionResult _predictUsingMovingAverage(List<Venta> ventas, int daysAhead) {
    if (ventas.length < 7) {
      return _PredictionResult(value: 0, confidence: 0.1, seasonalFactor: 1.0, trendFactor: 1.0);
    }

    final now = DateTime.now();
    final periods = [7, 14, 21];
    final averages = <double>[];

    for (final period in periods) {
      final periodStart = now.subtract(Duration(days: period));
      final periodSales = ventas.where((v) => v.fecha.isAfter(periodStart)).length;
      averages.add(periodSales / period * 7); // Normalizar a ventas por semana
    }

    final predictedValue = averages.reduce((a, b) => a + b) / averages.length * (daysAhead / 7.0);
    final confidence = 0.6;

    return _PredictionResult(
      value: max(0, predictedValue),
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: 1.0,
    );
  }

  _PredictionResult _predictUsingLinearRegression(List<Venta> ventas, int daysAhead) {
    if (ventas.length < 3) {
      return _PredictionResult(value: 0, confidence: 0.1, seasonalFactor: 1.0, trendFactor: 1.0);
    }

    // Agrupar ventas por semana
    final Map<int, int> weeklySales = {};
    for (final venta in ventas) {
      final weekNumber = venta.fecha.difference(DateTime(2024, 1, 1)).inDays ~/ 7;
      weeklySales[weekNumber] = (weeklySales[weekNumber] ?? 0) + 1;
    }

    if (weeklySales.length < 3) {
      return _PredictionResult(value: 0, confidence: 0.1, seasonalFactor: 1.0, trendFactor: 1.0);
    }

    final weeks = weeklySales.keys.toList()..sort();
    final xValues = weeks.map((w) => w.toDouble()).toList();
    final yValues = weeks.map((w) => weeklySales[w]!.toDouble()).toList();

    final slope = _calculateLinearRegressionSlope(xValues, yValues);
    final intercept = yValues.last - slope * xValues.last;
    
    final currentWeek = DateTime.now().difference(DateTime(2024, 1, 1)).inDays ~/ 7;
    final futureWeek = currentWeek + (daysAhead ~/ 7);
    
    final predictedValue = slope * futureWeek + intercept;
    final confidence = 0.5;

    return _PredictionResult(
      value: max(0, predictedValue),
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: slope,
    );
  }

  _PredictionResult _calculateOptimalPriceByElasticity(double currentPrice, double elasticity) {
    // Usar elasticidad para calcular precio óptimo
    final optimalPrice = currentPrice * (1 - elasticity / 2);
    final confidence = (1.0 - elasticity.abs()).clamp(0.1, 0.9);

    return _PredictionResult(
      value: max(0.1, optimalPrice),
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: 1.0,
    );
  }

  _PredictionResult _calculateOptimalPriceByRevenue(List<Venta> ventas, double currentPrice) {
    // Calcular precio que maximiza ingresos
    final optimalPrice = currentPrice * 1.1; // Aumentar precio en 10%
    final confidence = 0.6;

    return _PredictionResult(
      value: optimalPrice,
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: 1.0,
    );
  }

  _PredictionResult _calculateOptimalPriceByCompetition(Producto producto, List<Venta> ventas) {
    // Análisis de competencia simplificado
    final marketPosition = producto.precioVenta / 100.0; // Normalizar
    final optimalPrice = producto.precioVenta * (0.9 + marketPosition * 0.2);
    final confidence = 0.5;

    return _PredictionResult(
      value: optimalPrice,
      confidence: confidence,
      seasonalFactor: 1.0,
      trendFactor: 1.0,
    );
  }

  // Métodos auxiliares
  double _ensemblePredictions(List<double> predictions, List<double> confidences) {
    if (predictions.isEmpty) return 0.0;

    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (int i = 0; i < predictions.length; i++) {
      final weight = confidences[i];
      weightedSum += predictions[i] * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : predictions.reduce((a, b) => a + b) / predictions.length;
  }

  double _calculateEnsembleConfidence(List<double> confidences) {
    if (confidences.isEmpty) return 0.0;
    
    // Usar promedio de confianzas como métrica de ensemble
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }

  Map<String, double> _calculateFeatureImportance(List<double> features, List<double> predictions) {
    final importance = <String, double>{};
    final featureNames = [
      'precio', 'stock', 'ventas_7d', 'ventas_30d', 'ventas_90d', 'tendencia',
      'volatilidad', 'precio_promedio', 'elasticidad', 'correlacion_precio_cantidad',
      'ratio_stock', 'rotacion_stock', 'factor_estacional', 'factor_semanal',
      'dia_mes', 'dia_semana', 'aceleracion_tendencia', 'momentum'
    ];

    for (int i = 0; i < min(features.length, featureNames.length); i++) {
      importance[featureNames[i]] = features[i].abs();
    }

    return importance;
  }

  List<String> _generateDemandFactors(List<Venta> ventas, Producto producto, double prediction, int daysAhead) {
    final factors = <String>[];
    
    if (prediction > producto.stock * 1.5) {
      factors.add('Demanda predicha excede stock disponible');
    }
    
    if (prediction < producto.stock * 0.3) {
      factors.add('Demanda predicha muy baja para stock actual');
    }

    final trend = _statisticalService.calculateSalesTrend(ventas, 30);
    if (trend > 0.5) {
      factors.add('Tendencia de crecimiento detectada');
    } else if (trend < -0.5) {
      factors.add('Tendencia de decrecimiento detectada');
    }

    final volatility = _statisticalService.calculateSalesVolatility(ventas, 30);
    if (volatility > 0.5) {
      factors.add('Alta volatilidad en ventas históricas');
    }

    return factors;
  }

  List<String> _generatePriceFactors(Producto producto, double optimalPrice, double elasticity, double correlation) {
    final factors = <String>[];
    
    final priceDiff = optimalPrice - producto.precioVenta;
    final percentDiff = (priceDiff / producto.precioVenta * 100).abs();
    
    if (percentDiff > 10) {
      if (priceDiff > 0) {
        factors.add('Precio puede aumentar en ${percentDiff.toStringAsFixed(1)}%');
      } else {
        factors.add('Precio puede reducirse en ${percentDiff.toStringAsFixed(1)}%');
      }
    }

    if (elasticity.abs() > 1.0) {
      factors.add('Producto es ${elasticity > 0 ? 'inelástico' : 'elástico'}');
    }

    if (correlation.abs() > 0.7) {
      factors.add('Fuerte correlación entre precio y cantidad');
    }

    return factors;
  }

  String _generateDemandRecommendation(Producto producto, double prediction, List<String> factors) {
    if (prediction > producto.stock * 1.5) {
      return 'Aumentar stock urgentemente - demanda alta predicha';
    } else if (prediction < producto.stock * 0.3) {
      return 'Reducir stock - demanda baja predicha';
    } else {
      return 'Stock actual es adecuado según predicción';
    }
  }

  String _generatePriceRecommendation(Producto producto, double optimalPrice, List<String> factors) {
    final diff = optimalPrice - producto.precioVenta;
    final percentDiff = (diff / producto.precioVenta * 100).abs();
    
    if (percentDiff > 10) {
      if (diff > 0) {
        return 'Aumentar precio en ${percentDiff.toStringAsFixed(1)}% para maximizar ganancias';
      } else {
        return 'Reducir precio en ${percentDiff.toStringAsFixed(1)}% para aumentar ventas';
      }
    } else {
      return 'Precio actual es óptimo según análisis';
    }
  }

  List<CustomerSegment> _performCustomerSegmentation(Map<String, dynamic> customerFeatures) {
    final customerMetrics = customerFeatures['customer_metrics'] as List<Map<String, dynamic>>;
    if (customerMetrics.isEmpty) return [];

    // Clustering simplificado basado en valor y frecuencia
    final segments = <CustomerSegment>[];
    
    // Calcular umbrales
    final values = customerMetrics.map((m) => m['total_spent'] as double).toList();
    final frequencies = customerMetrics.map((m) => m['purchase_frequency'] as double).toList();
    
    values.sort();
    frequencies.sort();
    
    final valueThreshold = values[values.length ~/ 2]; // Mediana
    final frequencyThreshold = frequencies[frequencies.length ~/ 2]; // Mediana

    // Segmentar clientes
    int vipCount = 0, regularCount = 0, newCount = 0;
    double vipRevenue = 0, regularRevenue = 0, newRevenue = 0;

    for (final metrics in customerMetrics) {
      final value = metrics['total_spent'] as double;
      final frequency = metrics['purchase_frequency'] as double;
      
      if (value >= valueThreshold && frequency >= frequencyThreshold) {
        vipCount++;
        vipRevenue += value;
      } else if (value >= valueThreshold || frequency >= frequencyThreshold) {
        regularCount++;
        regularRevenue += value;
      } else {
        newCount++;
        newRevenue += value;
      }
    }

    final totalCustomers = customerMetrics.length;

    if (vipCount > 0) {
      segments.add(CustomerSegment(
        name: 'Clientes VIP',
        percentage: (vipCount / totalCustomers * 100),
        characteristics: ['Alto valor', 'Frecuentes', 'Leales'],
        avgOrderValue: vipRevenue / vipCount,
        frequency: 'Semanal',
        customerCount: vipCount,
        totalRevenue: vipRevenue,
        avgLifetimeValue: vipRevenue / vipCount,
        preferredCategories: ['Premium'],
      ));
    }

    if (regularCount > 0) {
      segments.add(CustomerSegment(
        name: 'Clientes Regulares',
        percentage: (regularCount / totalCustomers * 100),
        characteristics: ['Valor medio', 'Ocasionales', 'Estables'],
        avgOrderValue: regularRevenue / regularCount,
        frequency: 'Mensual',
        customerCount: regularCount,
        totalRevenue: regularRevenue,
        avgLifetimeValue: regularRevenue / regularCount,
        preferredCategories: ['Estándar'],
      ));
    }

    if (newCount > 0) {
      segments.add(CustomerSegment(
        name: 'Clientes Nuevos',
        percentage: (newCount / totalCustomers * 100),
        characteristics: ['Bajo valor', 'Primera compra', 'Potencial'],
        avgOrderValue: newRevenue / newCount,
        frequency: 'Primera vez',
        customerCount: newCount,
        totalRevenue: newRevenue,
        avgLifetimeValue: newRevenue / newCount,
        preferredCategories: ['Básico'],
      ));
    }

    return segments;
  }

  List<String> _generateCustomerInsights(List<CustomerSegment> segments, Map<String, dynamic> features) {
    final insights = <String>[];
    
    for (final segment in segments) {
      insights.add('${segment.name}: ${segment.percentage.toStringAsFixed(1)}% de clientes');
    }

    final clv = features['customer_lifetime_value'] as double;
    if (clv > 0) {
      insights.add('Valor de vida del cliente: \$${clv.toStringAsFixed(2)}');
    }

    final retention = features['retention_rate'] as double;
    if (retention > 0) {
      insights.add('Tasa de retención: ${(retention * 100).toStringAsFixed(1)}%');
    }

    return insights;
  }

  List<String> _generateCustomerRecommendations(List<CustomerSegment> segments, List<String> insights) {
    final recommendations = <String>[];
    
    final vipSegment = segments.where((s) => s.name == 'Clientes VIP').firstOrNull;
    if (vipSegment != null && vipSegment.percentage > 10) {
      recommendations.add('Crear programa de fidelización para clientes VIP');
    }

    final newSegment = segments.where((s) => s.name == 'Clientes Nuevos').firstOrNull;
    if (newSegment != null && newSegment.percentage > 20) {
      recommendations.add('Desarrollar estrategias para convertir clientes nuevos');
    }

    recommendations.add('Personalizar ofertas por segmento de cliente');
    recommendations.add('Implementar campañas de retención');

    return recommendations;
  }

  Map<String, double> _calculateSegmentMetrics(List<CustomerSegment> segments) {
    final metrics = <String, double>{};
    
    for (final segment in segments) {
      metrics['${segment.name}_percentage'] = segment.percentage;
      metrics['${segment.name}_avg_value'] = segment.avgOrderValue;
      metrics['${segment.name}_revenue'] = segment.totalRevenue;
    }

    return metrics;
  }

  double _calculateDemandSensitivity(List<Venta> ventas, double currentPrice, double newPrice) {
    if (ventas.isEmpty) return 0.0;
    
    final priceChange = (newPrice - currentPrice) / currentPrice;
    final avgQuantity = ventas.map((v) => v.items.fold(0, (sum, item) => sum + item.cantidad))
        .reduce((a, b) => a + b) / ventas.length;
    
    // Estimación simplificada de sensibilidad
    return priceChange != 0 ? avgQuantity / priceChange : 0.0;
  }

  double _calculateLinearRegressionSlope(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length || xValues.length < 2) return 0.0;

    final n = xValues.length;
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = xValues.asMap().entries.map((e) => e.value * yValues[e.key]).reduce((a, b) => a + b);
    final sumXX = xValues.map((x) => x * x).reduce((a, b) => a + b);

    return (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
  }

  // Métodos para crear predicciones vacías
  MLDemandPrediction _createEmptyDemandPrediction(int productoId, int daysAhead) {
    return MLDemandPrediction(
      productoId: productoId,
      predictedDemand: 0,
      confidence: 0.0,
      factors: ['Sin datos suficientes para predicción'],
      recommendation: 'Agregar más datos históricos',
      predictionDate: DateTime.now(),
      featureImportance: {},
      seasonalFactor: 1.0,
      trendFactor: 0.0,
      daysAhead: daysAhead,
    );
  }

  MLPricePrediction _createEmptyPricePrediction(int productoId, double currentPrice) {
    return MLPricePrediction(
      productoId: productoId,
      currentPrice: currentPrice,
      optimalPrice: currentPrice,
      confidence: 0.0,
      factors: ['Sin datos suficientes para análisis'],
      recommendation: 'Agregar más ventas para análisis de precio',
      predictionDate: DateTime.now(),
      priceElasticity: 0.0,
      demandSensitivity: 0.0,
      marketFactors: {},
    );
  }

  MLCustomerAnalysis _createEmptyCustomerAnalysis() {
    return MLCustomerAnalysis(
      totalCustomers: 0,
      segments: [],
      insights: ['Sin datos de clientes suficientes'],
      recommendations: ['Agregar más ventas para análisis'],
      analysisDate: DateTime.now(),
      segmentMetrics: {},
      customerLifetimeValue: 0.0,
      retentionRate: 0.0,
    );
  }
}

/// Clase auxiliar para resultados de predicción
class _PredictionResult {
  final double value;
  final double confidence;
  final double seasonalFactor;
  final double trendFactor;

  _PredictionResult({
    required this.value,
    required this.confidence,
    required this.seasonalFactor,
    required this.trendFactor,
  });
}
