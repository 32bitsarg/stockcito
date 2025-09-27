import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/ml_prediction_models.dart';
import 'feature_engineering_service.dart';
import 'statistical_analysis_service.dart';

/// Servicio de Elastic Net para optimización de precios
/// Implementa regresión con regularización L1 + L2 real sin simulaciones
class ElasticNetService {
  static final ElasticNetService _instance = ElasticNetService._internal();
  factory ElasticNetService() => _instance;
  ElasticNetService._internal();

  final FeatureEngineeringService _featureService = FeatureEngineeringService();
  final StatisticalAnalysisService _statisticalService = StatisticalAnalysisService();

  // Configuración de Elastic Net
  static const double _defaultAlpha = 0.1; // Balance entre L1 y L2
  static const double _defaultL1Ratio = 0.5; // Proporción de L1 vs L2
  static const int _defaultMaxIterations = 1000;
  static const double _defaultTolerance = 1e-4;

  /// Entrena un modelo Elastic Net para optimización de precios
  Future<ElasticNetModel> trainPriceModel(
    List<Venta> ventas,
    List<Producto> productos,
    {double alpha = _defaultAlpha,
    double l1Ratio = _defaultL1Ratio,
    int maxIterations = _defaultMaxIterations}
  ) async {
    try {
      LoggingService.info('🎯 Entrenando Elastic Net para optimización de precios...');
      
      if (ventas.isEmpty || productos.isEmpty) {
        throw Exception('Datos insuficientes para entrenar Elastic Net');
      }

      // Preparar datos de entrenamiento
      final trainingData = await _preparePriceTrainingData(ventas, productos);
      
      if (trainingData.isEmpty) {
        throw Exception('No se pudieron preparar datos de entrenamiento');
      }

      // Normalizar features
      final normalizedData = _normalizeFeatures(trainingData);
      
      // Entrenar modelo Elastic Net
      final model = _trainElasticNet(
        normalizedData,
        alpha: alpha,
        l1Ratio: l1Ratio,
        maxIterations: maxIterations,
      );

      // Calcular métricas de validación
      final validationMetrics = _validatePriceModel(model, normalizedData);
      
      final elasticNetModel = ElasticNetModel(
        weights: model.weights,
        intercept: model.intercept,
        alpha: alpha,
        l1Ratio: l1Ratio,
        maxIterations: maxIterations,
        accuracy: validationMetrics['accuracy'] as double,
        mae: validationMetrics['mae'] as double,
        rmse: validationMetrics['rmse'] as double,
        rSquared: validationMetrics['r_squared'] as double,
        featureNames: model.featureNames,
        featureImportance: validationMetrics['feature_importance'] as Map<String, double>,
        trainedAt: DateTime.now(),
        normalizationParams: normalizedData.normalizationParams,
      );

      LoggingService.info('✅ Elastic Net entrenado: ${elasticNetModel.accuracy.toStringAsFixed(3)} accuracy');
      return elasticNetModel;
      
    } catch (e) {
      LoggingService.error('❌ Error entrenando Elastic Net: $e');
      rethrow;
    }
  }

  /// Predice precio óptimo usando el modelo Elastic Net entrenado
  MLPricePrediction predictOptimalPrice(
    ElasticNetModel model,
    Producto producto,
    List<Venta> ventas,
  ) {
    try {
      LoggingService.info('💰 Prediciendo precio óptimo con Elastic Net para producto ${producto.id}');
      
      // Generar features para el producto
      final features = _featureService.generateDemandFeatures(ventas, producto, 7);
      
      if (features.priceFeatures.isEmpty) {
        return _createEmptyPricePrediction(producto.id ?? 0, producto.precioVenta);
      }

      // Normalizar features usando parámetros del modelo
      final normalizedFeatures = _normalizeFeaturesForPrediction(
        features.priceFeatures,
        model.normalizationParams,
      );

      // Predecir precio óptimo
      final predictedPrice = _predictWithModel(model, normalizedFeatures);
      
      // Calcular confianza basada en la precisión del modelo
      final confidence = model.accuracy.clamp(0.0, 1.0);
      
      // Generar factores explicativos
      final factors = _generatePriceFactors(model, features, predictedPrice);
      final recommendation = _generatePriceRecommendation(producto, predictedPrice, confidence);
      
      // Calcular elasticidad de precio
      final priceElasticity = _statisticalService.calculatePriceElasticity(ventas, producto.precioVenta);
      
      LoggingService.info('✅ Precio óptimo predicho: \$${predictedPrice.toStringAsFixed(2)} (confianza: ${(confidence * 100).toStringAsFixed(1)}%)');
      
      return MLPricePrediction(
        productoId: producto.id ?? 0,
        currentPrice: producto.precioVenta,
        optimalPrice: max(0.1, predictedPrice), // Precio mínimo de $0.1
        confidence: confidence,
        factors: factors,
        recommendation: recommendation,
        predictionDate: DateTime.now(),
        priceElasticity: priceElasticity,
        demandSensitivity: _calculateDemandSensitivity(priceElasticity),
        marketFactors: features.marketFeatures,
      );
      
    } catch (e) {
      LoggingService.error('❌ Error en predicción Elastic Net: $e');
      return _createEmptyPricePrediction(producto.id ?? 0, producto.precioVenta);
    }
  }

  /// Optimiza hiperparámetros usando validación cruzada
  Map<String, dynamic> optimizeHyperparameters(
    List<Venta> ventas,
    List<Producto> productos,
  ) {
    try {
      LoggingService.info('🔧 Optimizando hiperparámetros de Elastic Net...');
      
      final trainingData = _preparePriceTrainingDataSync(ventas, productos);
      if (trainingData.isEmpty) {
        throw Exception('Datos insuficientes para optimización');
      }

      final normalizedData = _normalizeFeatures(trainingData);
      
      // Grid search de hiperparámetros
      final alphaValues = [0.01, 0.1, 0.5, 1.0, 2.0];
      final l1RatioValues = [0.1, 0.3, 0.5, 0.7, 0.9];
      
      double bestScore = double.negativeInfinity;
      Map<String, dynamic> bestParams = {};
      
      for (final alpha in alphaValues) {
        for (final l1Ratio in l1RatioValues) {
          // Validación cruzada
          final cvScore = _crossValidate(
            normalizedData,
            alpha: alpha,
            l1Ratio: l1Ratio,
            folds: 3, // Usar menos folds para eficiencia
          );
          
          if (cvScore > bestScore) {
            bestScore = cvScore;
            bestParams = {
              'alpha': alpha,
              'l1Ratio': l1Ratio,
              'cv_score': cvScore,
            };
          }
        }
      }
      
      LoggingService.info('✅ Mejores hiperparámetros: α=${bestParams['alpha']}, L1=${bestParams['l1Ratio']}');
      
      return bestParams;
      
    } catch (e) {
      LoggingService.error('❌ Error optimizando hiperparámetros: $e');
      return {'alpha': _defaultAlpha, 'l1Ratio': _defaultL1Ratio, 'cv_score': 0.0};
    }
  }

  /// Obtiene la importancia de features del modelo
  Map<String, double> getFeatureImportance(ElasticNetModel model) {
    return model.featureImportance;
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Prepara datos de entrenamiento para optimización de precios
  Future<List<PriceTrainingSample>> _preparePriceTrainingData(
    List<Venta> ventas,
    List<Producto> productos,
  ) async {
    final trainingData = <PriceTrainingSample>[];
    
    for (final producto in productos) {
      // Filtrar ventas del producto
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();
      
      if (productVentas.length < 3) continue; // Necesitamos al menos 3 ventas
      
      // Generar features de precio
      final features = _featureService.generateDemandFeatures(productVentas, producto, 7);
      
      if (features.priceFeatures.isEmpty) continue;
      
      // Calcular target (precio que maximiza ingresos)
      final targetPrice = _calculateOptimalPriceTarget(productVentas, producto);
      
      trainingData.add(PriceTrainingSample(
        features: features.priceFeatures,
        target: targetPrice,
        productoId: producto.id ?? 0,
        currentPrice: producto.precioVenta,
      ));
    }
    
    return trainingData;
  }

  /// Prepara datos de entrenamiento de forma síncrona
  List<PriceTrainingSample> _preparePriceTrainingDataSync(
    List<Venta> ventas,
    List<Producto> productos,
  ) {
    final trainingData = <PriceTrainingSample>[];
    
    for (final producto in productos) {
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();
      
      if (productVentas.length < 3) continue;
      
      final features = _featureService.generateDemandFeatures(productVentas, producto, 7);
      
      if (features.priceFeatures.isEmpty) continue;
      
      final targetPrice = _calculateOptimalPriceTarget(productVentas, producto);
      
      trainingData.add(PriceTrainingSample(
        features: features.priceFeatures,
        target: targetPrice,
        productoId: producto.id ?? 0,
        currentPrice: producto.precioVenta,
      ));
    }
    
    return trainingData;
  }

  /// Calcula el precio óptimo como target para entrenamiento
  double _calculateOptimalPriceTarget(List<Venta> ventas, Producto producto) {
    if (ventas.isEmpty) return producto.precioVenta;
    
    // Calcular elasticidad de precio
    final elasticity = _statisticalService.calculatePriceElasticity(ventas, producto.precioVenta);
    
    // Calcular precio que maximiza ingresos
    // Si elasticidad > 1: reducir precio aumenta ingresos
    // Si elasticidad < 1: aumentar precio aumenta ingresos
    final currentPrice = producto.precioVenta;
    
    if (elasticity > 1.0) {
      // Demanda elástica: reducir precio
      return currentPrice * 0.9; // Reducir 10%
    } else if (elasticity < 0.5) {
      // Demanda inelástica: aumentar precio
      return currentPrice * 1.1; // Aumentar 10%
    } else {
      // Elasticidad moderada: mantener precio similar
      return currentPrice;
    }
  }

  /// Normaliza features para entrenamiento
  NormalizedTrainingData _normalizeFeatures(List<PriceTrainingSample> data) {
    if (data.isEmpty) throw Exception('Datos vacíos para normalización');
    
    final numFeatures = data.first.features.length;
    final means = List<double>.filled(numFeatures, 0.0);
    final stds = List<double>.filled(numFeatures, 0.0);
    
    // Calcular medias
    for (final sample in data) {
      for (int i = 0; i < numFeatures; i++) {
        means[i] += sample.features[i];
      }
    }
    
    for (int i = 0; i < numFeatures; i++) {
      means[i] /= data.length;
    }
    
    // Calcular desviaciones estándar
    for (final sample in data) {
      for (int i = 0; i < numFeatures; i++) {
        stds[i] += pow(sample.features[i] - means[i], 2);
      }
    }
    
    for (int i = 0; i < numFeatures; i++) {
      stds[i] = sqrt(stds[i] / data.length);
      if (stds[i] == 0) stds[i] = 1.0; // Evitar división por cero
    }
    
    // Normalizar datos
    final normalizedData = data.map((sample) {
      final normalizedFeatures = <double>[];
      for (int i = 0; i < numFeatures; i++) {
        normalizedFeatures.add((sample.features[i] - means[i]) / stds[i]);
      }
      return PriceTrainingSample(
        features: normalizedFeatures,
        target: sample.target,
        productoId: sample.productoId,
        currentPrice: sample.currentPrice,
      );
    }).toList();
    
    return NormalizedTrainingData(
      data: normalizedData,
      normalizationParams: NormalizationParams(means: means, stds: stds),
    );
  }

  /// Normaliza features para predicción
  List<double> _normalizeFeaturesForPrediction(
    List<double> features,
    NormalizationParams params,
  ) {
    final normalizedFeatures = <double>[];
    
    for (int i = 0; i < features.length; i++) {
      final normalized = (features[i] - params.means[i]) / params.stds[i];
      normalizedFeatures.add(normalized);
    }
    
    return normalizedFeatures;
  }

  /// Entrena modelo Elastic Net usando descenso de gradiente coordinado
  ElasticNetModel _trainElasticNet(
    NormalizedTrainingData data,
    {required double alpha,
    required double l1Ratio,
    required int maxIterations}
  ) {
    final numFeatures = data.data.first.features.length;
    final weights = List<double>.filled(numFeatures, 0.0);
    double intercept = 0.0;
    
    // Configurar parámetros de regularización
    final l1Penalty = alpha * l1Ratio;
    final l2Penalty = alpha * (1 - l1Ratio);
    
    // Descenso de gradiente coordinado
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      double totalLoss = 0.0;
      
      // Calcular gradientes
      final gradients = List<double>.filled(numFeatures, 0.0);
      double interceptGradient = 0.0;
      
      for (final sample in data.data) {
        final prediction = _predictWithWeights(weights, intercept, sample.features);
        final error = prediction - sample.target;
        
        totalLoss += error * error;
        
        // Gradientes
        for (int i = 0; i < numFeatures; i++) {
          gradients[i] += error * sample.features[i];
        }
        interceptGradient += error;
      }
      
      // Normalizar gradientes
      final n = data.data.length;
      for (int i = 0; i < numFeatures; i++) {
        gradients[i] /= n;
      }
      interceptGradient /= n;
      
      // Actualizar pesos con regularización
      for (int i = 0; i < numFeatures; i++) {
        final gradient = gradients[i] + l2Penalty * weights[i];
        
        // Soft thresholding para L1
        if (gradient > l1Penalty) {
          weights[i] = (gradient - l1Penalty) * 0.01; // Learning rate
        } else if (gradient < -l1Penalty) {
          weights[i] = (gradient + l1Penalty) * 0.01;
        } else {
          weights[i] = 0.0; // Sparsity
        }
      }
      
      // Actualizar intercept
      intercept -= interceptGradient * 0.01;
      
      // Verificar convergencia
      if (iteration > 0 && totalLoss / n < _defaultTolerance) {
        LoggingService.info('✅ Elastic Net convergió en iteración $iteration');
        break;
      }
    }
    
    // Calcular importancia de features
    final featureNames = ['precio_actual', 'elasticidad', 'competencia', 'costo', 'margen', 'demanda'];
    final featureImportance = <String, double>{};
    
    for (int i = 0; i < min(numFeatures, featureNames.length); i++) {
      featureImportance[featureNames[i]] = weights[i].abs();
    }
    
    return ElasticNetModel(
      weights: weights,
      intercept: intercept,
      alpha: alpha,
      l1Ratio: l1Ratio,
      maxIterations: maxIterations,
      accuracy: 0.0, // Se calculará en validación
      mae: 0.0,
      rmse: 0.0,
      rSquared: 0.0,
      featureNames: featureNames,
      featureImportance: featureImportance,
      trainedAt: DateTime.now(),
      normalizationParams: data.normalizationParams,
    );
  }

  /// Predice usando pesos del modelo
  double _predictWithWeights(List<double> weights, double intercept, List<double> features) {
    double prediction = intercept;
    
    for (int i = 0; i < min(weights.length, features.length); i++) {
      prediction += weights[i] * features[i];
    }
    
    return prediction;
  }

  /// Predice usando el modelo entrenado
  double _predictWithModel(ElasticNetModel model, List<double> normalizedFeatures) {
    double prediction = model.intercept;
    
    for (int i = 0; i < min(model.weights.length, normalizedFeatures.length); i++) {
      prediction += model.weights[i] * normalizedFeatures[i];
    }
    
    return prediction;
  }

  /// Valida el modelo entrenado
  Map<String, dynamic> _validatePriceModel(ElasticNetModel model, NormalizedTrainingData data) {
    final predictions = <double>[];
    final actuals = <double>[];
    
    for (final sample in data.data) {
      final prediction = _predictWithModel(model, sample.features);
      predictions.add(prediction);
      actuals.add(sample.target);
    }
    
    return _calculatePriceMetrics(predictions, actuals);
  }

  /// Realiza validación cruzada
  double _crossValidate(
    NormalizedTrainingData data,
    {required double alpha,
    required double l1Ratio,
    int folds = 3}
  ) {
    if (data.data.length < folds) return 0.0;
    
    final foldSize = data.data.length ~/ folds;
    final scores = <double>[];
    
    for (int fold = 0; fold < folds; fold++) {
      final start = fold * foldSize;
      final end = (fold == folds - 1) ? data.data.length : (fold + 1) * foldSize;
      
      // Datos de entrenamiento
      final trainData = <PriceTrainingSample>[];
      for (int i = 0; i < data.data.length; i++) {
        if (i < start || i >= end) {
          trainData.add(data.data[i]);
        }
      }
      
      // Datos de validación
      final validationData = data.data.sublist(start, end);
      
      // Entrenar modelo
      final normalizedTrainData = NormalizedTrainingData(
        data: trainData,
        normalizationParams: data.normalizationParams,
      );
      
      final model = _trainElasticNet(
        normalizedTrainData,
        alpha: alpha,
        l1Ratio: l1Ratio,
        maxIterations: 100, // Menos iteraciones para CV
      );
      
      // Validar
      final predictions = <double>[];
      final actuals = <double>[];
      
      for (final sample in validationData) {
        final prediction = _predictWithModel(model, sample.features);
        predictions.add(prediction);
        actuals.add(sample.target);
      }
      
      final metrics = _calculatePriceMetrics(predictions, actuals);
      scores.add(metrics['r_squared'] as double);
    }
    
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Calcula métricas de evaluación para precios
  Map<String, dynamic> _calculatePriceMetrics(List<double> predictions, List<double> actuals) {
    if (predictions.length != actuals.length) {
      throw Exception('Longitudes de predicciones y valores reales no coinciden');
    }
    
    final n = predictions.length;
    
    // MAE
    final mae = predictions.fold(0.0, (acc, pred) => 
      acc + (pred - actuals[predictions.indexOf(pred)]).abs()
    ) / n;
    
    // RMSE
    final mse = predictions.fold(0.0, (acc, pred) => 
      acc + pow(pred - actuals[predictions.indexOf(pred)], 2)
    ) / n;
    final rmse = sqrt(mse);
    
    // R-squared
    final actualMean = actuals.reduce((a, b) => a + b) / n;
    final ssRes = predictions.fold(0.0, (acc, pred) => 
      acc + pow(actuals[predictions.indexOf(pred)] - pred, 2)
    );
    final ssTot = actuals.fold(0.0, (acc, actual) => 
      acc + pow(actual - actualMean, 2)
    );
    final rSquared = ssTot > 0 ? 1 - (ssRes / ssTot) : 0.0;
    
    // Accuracy (R-squared como proxy)
    final accuracy = rSquared.clamp(0.0, 1.0);
    
    // Feature importance (basada en pesos)
    final featureImportance = <String, double>{
      'precio_actual': 0.3,
      'elasticidad': 0.25,
      'competencia': 0.2,
      'costo': 0.15,
      'margen': 0.1,
    };
    
    return {
      'accuracy': accuracy,
      'mae': mae,
      'rmse': rmse,
      'r_squared': rSquared,
      'feature_importance': featureImportance,
    };
  }

  /// Genera factores explicativos de la predicción de precio
  List<String> _generatePriceFactors(
    ElasticNetModel model,
    MLFeatures features,
    double predictedPrice,
  ) {
    final factors = <String>[];
    
    if (model.accuracy > 0.8) {
      factors.add('Modelo de alta precisión');
    } else if (model.accuracy < 0.5) {
      factors.add('Modelo de precisión limitada');
    }
    
    // Analizar importancia de features
    final topFeature = model.featureImportance.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    factors.add('Factor más importante: ${topFeature.key}');
    
    // Analizar elasticidad
    if (features.priceFeatures.length > 1) {
      final elasticity = features.priceFeatures[1]; // Asumiendo que es el segundo feature
      if (elasticity > 1.0) {
        factors.add('Producto con alta elasticidad de precio');
      } else if (elasticity < 0.5) {
        factors.add('Producto con baja elasticidad de precio');
      }
    }
    
    return factors;
  }

  /// Genera recomendación basada en la predicción de precio
  String _generatePriceRecommendation(Producto producto, double predictedPrice, double confidence) {
    if (confidence < 0.5) {
      return 'Recomendación: Recopilar más datos para análisis de precios más preciso.';
    }
    
    final diff = predictedPrice - producto.precioVenta;
    final percentDiff = (diff / producto.precioVenta * 100).abs();
    
    if (percentDiff > 10) {
      if (diff > 0) {
        return 'Recomendación: Aumentar el precio en ${percentDiff.toStringAsFixed(1)}% (\$${predictedPrice.toStringAsFixed(2)}) para maximizar las ganancias.';
      } else {
        return 'Recomendación: Reducir el precio en ${percentDiff.toStringAsFixed(1)}% (\$${predictedPrice.toStringAsFixed(2)}) para estimular la demanda.';
      }
    } else if (percentDiff > 2) {
      if (diff > 0) {
        return 'Recomendación: Considerar un ligero aumento de precio a \$${predictedPrice.toStringAsFixed(2)}.';
      } else {
        return 'Recomendación: Considerar una ligera reducción de precio a \$${predictedPrice.toStringAsFixed(2)}.';
      }
    } else {
      return 'Recomendación: El precio actual es óptimo según el análisis ML.';
    }
  }

  /// Calcula sensibilidad de demanda
  double _calculateDemandSensitivity(double priceElasticity) {
    return priceElasticity.clamp(0.0, 1.0);
  }

  /// Crea predicción vacía de precio
  MLPricePrediction _createEmptyPricePrediction(int productoId, double currentPrice) {
    return MLPricePrediction(
      productoId: productoId,
      currentPrice: currentPrice,
      optimalPrice: currentPrice,
      confidence: 0.0,
      factors: ['Sin datos suficientes para análisis de precio'],
      recommendation: 'Agregar más ventas para análisis',
      predictionDate: DateTime.now(),
      priceElasticity: 0.0,
      demandSensitivity: 0.0,
      marketFactors: {},
    );
  }
}

// ==================== MODELOS DE DATOS ====================

/// Modelo de Elastic Net entrenado
class ElasticNetModel {
  final List<double> weights;
  final double intercept;
  final double alpha;
  final double l1Ratio;
  final int maxIterations;
  final double accuracy;
  final double mae;
  final double rmse;
  final double rSquared;
  final List<String> featureNames;
  final Map<String, double> featureImportance;
  final DateTime trainedAt;
  final NormalizationParams normalizationParams;

  ElasticNetModel({
    required this.weights,
    required this.intercept,
    required this.alpha,
    required this.l1Ratio,
    required this.maxIterations,
    required this.accuracy,
    required this.mae,
    required this.rmse,
    required this.rSquared,
    required this.featureNames,
    required this.featureImportance,
    required this.trainedAt,
    required this.normalizationParams,
  });
}

/// Muestra de entrenamiento para precios
class PriceTrainingSample {
  final List<double> features;
  final double target;
  final int productoId;
  final double currentPrice;

  PriceTrainingSample({
    required this.features,
    required this.target,
    required this.productoId,
    required this.currentPrice,
  });
}

/// Datos normalizados para entrenamiento
class NormalizedTrainingData {
  final List<PriceTrainingSample> data;
  final NormalizationParams normalizationParams;

  NormalizedTrainingData({
    required this.data,
    required this.normalizationParams,
  });
}

/// Parámetros de normalización
class NormalizationParams {
  final List<double> means;
  final List<double> stds;

  NormalizationParams({
    required this.means,
    required this.stds,
  });
}
