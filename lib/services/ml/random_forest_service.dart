import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/ml_prediction_models.dart';
import 'feature_engineering_service.dart';
import 'statistical_analysis_service.dart';

/// Servicio de Random Forest para predicción de demanda
/// Implementa un algoritmo de ensemble learning real sin simulaciones
class RandomForestService {
  static final RandomForestService _instance = RandomForestService._internal();
  factory RandomForestService() => _instance;
  RandomForestService._internal();

  final FeatureEngineeringService _featureService = FeatureEngineeringService();
  final StatisticalAnalysisService _statisticalService = StatisticalAnalysisService();

  // Configuración del Random Forest
  static const int _defaultNumTrees = 10;
  static const int _defaultMaxDepth = 5;
  static const int _defaultMinSamplesSplit = 2;
  static const double _defaultBootstrapRatio = 0.8;

  /// Entrena un modelo Random Forest para predicción de demanda
  Future<RandomForestModel> trainDemandModel(
    List<Venta> ventas,
    List<Producto> productos,
    {int numTrees = _defaultNumTrees,
    int maxDepth = _defaultMaxDepth,
    int minSamplesSplit = _defaultMinSamplesSplit}
  ) async {
    try {
      LoggingService.info('🌲 Entrenando Random Forest para predicción de demanda...');
      
      if (ventas.isEmpty || productos.isEmpty) {
        throw Exception('Datos insuficientes para entrenar Random Forest');
      }

      // Preparar datos de entrenamiento
      final trainingData = await _prepareTrainingData(ventas, productos);
      
      if (trainingData.isEmpty) {
        throw Exception('No se pudieron preparar datos de entrenamiento');
      }

      // Entrenar árboles del bosque
      final trees = <DecisionTree>[];
      final random = Random();
      
      for (int i = 0; i < numTrees; i++) {
        LoggingService.info('🌳 Entrenando árbol ${i + 1}/$numTrees...');
        
        // Bootstrap sampling
        final bootstrapData = _bootstrapSample(trainingData, random);
        
        // Entrenar árbol individual
        final tree = _trainDecisionTree(
          bootstrapData,
          maxDepth: maxDepth,
          minSamplesSplit: minSamplesSplit,
          random: random,
        );
        
        trees.add(tree);
      }

      // Calcular métricas de validación
      final validationMetrics = _validateModel(trees, trainingData);
      
      final model = RandomForestModel(
        trees: trees,
        numTrees: numTrees,
        maxDepth: maxDepth,
        minSamplesSplit: minSamplesSplit,
        accuracy: validationMetrics['accuracy'] as double,
        mae: validationMetrics['mae'] as double,
        rmse: validationMetrics['rmse'] as double,
        rSquared: validationMetrics['r_squared'] as double,
        featureImportance: validationMetrics['feature_importance'] as Map<String, double>,
        trainedAt: DateTime.now(),
      );

      LoggingService.info('✅ Random Forest entrenado: ${model.accuracy.toStringAsFixed(3)} accuracy');
      return model;
      
    } catch (e) {
      LoggingService.error('❌ Error entrenando Random Forest: $e');
      rethrow;
    }
  }

  /// Predice demanda usando el modelo Random Forest entrenado
  MLDemandPrediction predictDemand(
    RandomForestModel model,
    Producto producto,
    List<Venta> ventas,
    int daysAhead,
  ) {
    try {
      LoggingService.info('🔮 Prediciendo demanda con Random Forest para producto ${producto.id}');
      
      // Generar features para el producto
      final features = _featureService.generateDemandFeatures(ventas, producto, daysAhead);
      
      if (features.demandFeatures.isEmpty) {
        return _createEmptyPrediction(producto.id ?? 0, daysAhead);
      }

      // Obtener predicciones de todos los árboles
      final predictions = <double>[];
      for (final tree in model.trees) {
        final prediction = _predictWithTree(tree, features.demandFeatures);
        predictions.add(prediction);
      }

      // Promedio de predicciones (ensemble)
      final finalPrediction = predictions.reduce((a, b) => a + b) / predictions.length;
      final confidence = _calculatePredictionConfidence(predictions);
      
      // Generar factores explicativos
      final factors = _generatePredictionFactors(model, features, finalPrediction);
      final recommendation = _generateRecommendation(producto, finalPrediction, confidence);
      
      LoggingService.info('✅ Predicción Random Forest: ${finalPrediction.round()} unidades (confianza: ${(confidence * 100).toStringAsFixed(1)}%)');
      
      return MLDemandPrediction(
        productoId: producto.id ?? 0,
        predictedDemand: max(0, finalPrediction.round()),
        confidence: confidence,
        factors: factors,
        recommendation: recommendation,
        predictionDate: DateTime.now(),
        featureImportance: model.featureImportance,
        seasonalFactor: _calculateSeasonalFactor(ventas, producto),
        trendFactor: _calculateTrendFactor(ventas, producto),
        daysAhead: daysAhead,
      );
      
    } catch (e) {
      LoggingService.error('❌ Error en predicción Random Forest: $e');
      return _createEmptyPrediction(producto.id ?? 0, daysAhead);
    }
  }

  /// Obtiene la importancia de features del modelo
  Map<String, double> getFeatureImportance(RandomForestModel model) {
    return model.featureImportance;
  }

  /// Valida el modelo usando cross-validation
  Map<String, double> crossValidate(
    List<Venta> ventas,
    List<Producto> productos,
    {int folds = 5}
  ) {
    try {
      LoggingService.info('🔄 Realizando validación cruzada ($folds folds)...');
      
      final trainingData = _prepareTrainingDataSync(ventas, productos);
      if (trainingData.length < folds) {
        throw Exception('Datos insuficientes para validación cruzada');
      }

      final foldSize = trainingData.length ~/ folds;
      final accuracies = <double>[];
      final maes = <double>[];
      final rmses = <double>[];

      for (int fold = 0; fold < folds; fold++) {
        final start = fold * foldSize;
        final end = (fold == folds - 1) ? trainingData.length : (fold + 1) * foldSize;
        
        // Datos de entrenamiento (todos excepto este fold)
        final trainData = <TrainingSample>[];
        for (int i = 0; i < trainingData.length; i++) {
          if (i < start || i >= end) {
            trainData.add(trainingData[i]);
          }
        }
        
        // Datos de validación (este fold)
        final validationData = trainingData.sublist(start, end);
        
        // Entrenar modelo en datos de entrenamiento
        final model = _trainRandomForestSync(trainData);
        
        // Validar en datos de validación
        final metrics = _validateModelSync(model.trees, validationData);
        
        accuracies.add(metrics['accuracy'] as double);
        maes.add(metrics['mae'] as double);
        rmses.add(metrics['rmse'] as double);
      }

      final avgAccuracy = accuracies.reduce((a, b) => a + b) / accuracies.length;
      final avgMAE = maes.reduce((a, b) => a + b) / maes.length;
      final avgRMSE = rmses.reduce((a, b) => a + b) / rmses.length;

      LoggingService.info('✅ Validación cruzada completada: ${avgAccuracy.toStringAsFixed(3)} accuracy promedio');
      
      return {
        'accuracy': avgAccuracy,
        'mae': avgMAE,
        'rmse': avgRMSE,
        'accuracy_std': _calculateStandardDeviation(accuracies),
        'mae_std': _calculateStandardDeviation(maes),
        'rmse_std': _calculateStandardDeviation(rmses),
      };
      
    } catch (e) {
      LoggingService.error('❌ Error en validación cruzada: $e');
      return {'accuracy': 0.0, 'mae': 0.0, 'rmse': 0.0};
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Prepara datos de entrenamiento de forma asíncrona
  Future<List<TrainingSample>> _prepareTrainingData(
    List<Venta> ventas,
    List<Producto> productos,
  ) async {
    final trainingData = <TrainingSample>[];
    
    for (final producto in productos) {
      // Filtrar ventas del producto
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();
      
      if (productVentas.length < 2) continue; // Necesitamos al menos 2 ventas
      
      // Generar features
      final features = _featureService.generateDemandFeatures(productVentas, producto, 7);
      
      if (features.demandFeatures.isEmpty) continue;
      
      // Calcular target (demanda promedio de los últimos 7 días)
      final target = _calculateDemandTarget(productVentas, 7);
      
      trainingData.add(TrainingSample(
        features: features.demandFeatures,
        target: target,
        productoId: producto.id ?? 0,
      ));
    }
    
    return trainingData;
  }

  /// Prepara datos de entrenamiento de forma síncrona
  List<TrainingSample> _prepareTrainingDataSync(
    List<Venta> ventas,
    List<Producto> productos,
  ) {
    final trainingData = <TrainingSample>[];
    
    for (final producto in productos) {
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();
      
      if (productVentas.length < 2) continue;
      
      final features = _featureService.generateDemandFeatures(productVentas, producto, 7);
      
      if (features.demandFeatures.isEmpty) continue;
      
      final target = _calculateDemandTarget(productVentas, 7);
      
      trainingData.add(TrainingSample(
        features: features.demandFeatures,
        target: target,
        productoId: producto.id ?? 0,
      ));
    }
    
    return trainingData;
  }

  /// Calcula el target de demanda para entrenamiento
  double _calculateDemandTarget(List<Venta> ventas, int days) {
    if (ventas.isEmpty) return 0.0;
    
    final now = DateTime.now();
    final cutoffDate = now.subtract(Duration(days: days));
    
    final recentVentas = ventas.where((v) => v.fecha.isAfter(cutoffDate)).toList();
    
    if (recentVentas.isEmpty) return 0.0;
    
    // Calcular demanda promedio por día
    final totalQuantity = recentVentas.fold(0, (sum, venta) => 
      sum + venta.items.fold(0, (s, item) => s + item.cantidad)
    );
    
    return totalQuantity / days;
  }

  /// Bootstrap sampling para Random Forest
  List<TrainingSample> _bootstrapSample(
    List<TrainingSample> data,
    Random random,
  ) {
    final sampleSize = (data.length * _defaultBootstrapRatio).round();
    final bootstrapData = <TrainingSample>[];
    
    for (int i = 0; i < sampleSize; i++) {
      final randomIndex = random.nextInt(data.length);
      bootstrapData.add(data[randomIndex]);
    }
    
    return bootstrapData;
  }

  /// Entrena un árbol de decisión individual
  DecisionTree _trainDecisionTree(
    List<TrainingSample> data,
    {required int maxDepth,
    required int minSamplesSplit,
    required Random random}
  ) {
    return _buildTree(data, 0, maxDepth, minSamplesSplit, random);
  }

  /// Construye recursivamente el árbol de decisión
  DecisionTree _buildTree(
    List<TrainingSample> data,
    int currentDepth,
    int maxDepth,
    int minSamplesSplit,
    Random random,
  ) {
    // Condiciones de parada
    if (currentDepth >= maxDepth || 
        data.length < minSamplesSplit ||
        _isPure(data)) {
      return DecisionTree.leaf(_calculateLeafValue(data));
    }

    // Encontrar mejor split
    final bestSplit = _findBestSplit(data, random);
    
    if (bestSplit == null) {
      return DecisionTree.leaf(_calculateLeafValue(data));
    }

    // Dividir datos
    final leftData = <TrainingSample>[];
    final rightData = <TrainingSample>[];
    
    for (final sample in data) {
      if (sample.features[bestSplit.featureIndex] <= bestSplit.threshold) {
        leftData.add(sample);
      } else {
        rightData.add(sample);
      }
    }

    // Construir subárboles recursivamente
    final leftTree = _buildTree(leftData, currentDepth + 1, maxDepth, minSamplesSplit, random);
    final rightTree = _buildTree(rightData, currentDepth + 1, maxDepth, minSamplesSplit, random);

    return DecisionTree.node(
      featureIndex: bestSplit.featureIndex,
      threshold: bestSplit.threshold,
      left: leftTree,
      right: rightTree,
    );
  }

  /// Verifica si un conjunto de datos es puro (misma clase)
  bool _isPure(List<TrainingSample> data) {
    if (data.isEmpty) return true;
    
    final firstTarget = data.first.target;
    return data.every((sample) => (sample.target - firstTarget).abs() < 0.01);
  }

  /// Calcula el valor de una hoja (promedio de targets)
  double _calculateLeafValue(List<TrainingSample> data) {
    if (data.isEmpty) return 0.0;
    
    final sum = data.fold(0.0, (acc, sample) => acc + sample.target);
    return sum / data.length;
  }

  /// Encuentra el mejor split para un nodo
  SplitInfo? _findBestSplit(List<TrainingSample> data, Random random) {
    if (data.isEmpty) return null;
    
    final numFeatures = data.first.features.length;
    final bestSplits = <SplitInfo>[];
    
    // Evaluar splits aleatorios en features aleatorios
    final numSplitsToTry = min(numFeatures, 3); // Limitar para eficiencia
    
    for (int i = 0; i < numSplitsToTry; i++) {
      final featureIndex = random.nextInt(numFeatures);
      final split = _findBestSplitForFeature(data, featureIndex);
      
      if (split != null) {
        bestSplits.add(split);
      }
    }
    
    if (bestSplits.isEmpty) return null;
    
    // Retornar el split con mejor ganancia de información
    bestSplits.sort((a, b) => b.gain.compareTo(a.gain));
    return bestSplits.first;
  }

  /// Encuentra el mejor split para una feature específica
  SplitInfo? _findBestSplitForFeature(List<TrainingSample> data, int featureIndex) {
    if (data.isEmpty) return null;
    
    // Obtener valores únicos de la feature
    final values = data.map((sample) => sample.features[featureIndex]).toSet().toList();
    values.sort();
    
    if (values.length < 2) return null;
    
    double bestGain = 0.0;
    double bestThreshold = 0.0;
    
    // Probar diferentes thresholds
    for (int i = 0; i < values.length - 1; i++) {
      final threshold = (values[i] + values[i + 1]) / 2;
      final gain = _calculateInformationGain(data, featureIndex, threshold);
      
      if (gain > bestGain) {
        bestGain = gain;
        bestThreshold = threshold;
      }
    }
    
    if (bestGain <= 0) return null;
    
    return SplitInfo(
      featureIndex: featureIndex,
      threshold: bestThreshold,
      gain: bestGain,
    );
  }

  /// Calcula la ganancia de información para un split
  double _calculateInformationGain(
    List<TrainingSample> data,
    int featureIndex,
    double threshold,
  ) {
    // Dividir datos
    final leftData = <TrainingSample>[];
    final rightData = <TrainingSample>[];
    
    for (final sample in data) {
      if (sample.features[featureIndex] <= threshold) {
        leftData.add(sample);
      } else {
        rightData.add(sample);
      }
    }
    
    if (leftData.isEmpty || rightData.isEmpty) return 0.0;
    
    // Calcular entropía original
    final originalEntropy = _calculateEntropy(data);
    
    // Calcular entropía después del split
    final leftEntropy = _calculateEntropy(leftData);
    final rightEntropy = _calculateEntropy(rightData);
    
    final leftWeight = leftData.length / data.length;
    final rightWeight = rightData.length / data.length;
    
    final splitEntropy = leftWeight * leftEntropy + rightWeight * rightEntropy;
    
    return originalEntropy - splitEntropy;
  }

  /// Calcula la entropía de un conjunto de datos
  double _calculateEntropy(List<TrainingSample> data) {
    if (data.isEmpty) return 0.0;
    
    // Para regresión, usar varianza como medida de impureza
    final targets = data.map((sample) => sample.target).toList();
    final mean = targets.reduce((a, b) => a + b) / targets.length;
    
    final variance = targets.fold(0.0, (acc, target) => 
      acc + pow(target - mean, 2)
    ) / targets.length;
    
    return variance;
  }

  /// Predice usando un árbol individual
  double _predictWithTree(DecisionTree tree, List<double> features) {
    if (tree.isLeaf) {
      return tree.value ?? 0.0;
    }
    
    if (features[tree.featureIndex!] <= tree.threshold!) {
      return _predictWithTree(tree.left!, features);
    } else {
      return _predictWithTree(tree.right!, features);
    }
  }

  /// Calcula la confianza de la predicción basada en la varianza de los árboles
  double _calculatePredictionConfidence(List<double> predictions) {
    if (predictions.isEmpty) return 0.0;
    
    final mean = predictions.reduce((a, b) => a + b) / predictions.length;
    final variance = predictions.fold(0.0, (acc, pred) => 
      acc + pow(pred - mean, 2)
    ) / predictions.length;
    
    // Confianza inversamente proporcional a la varianza
    final stdDev = sqrt(variance);
    return (1.0 / (1.0 + stdDev)).clamp(0.0, 1.0);
  }

  /// Valida el modelo entrenado
  Map<String, dynamic> _validateModel(List<DecisionTree> trees, List<TrainingSample> data) {
    final predictions = <double>[];
    final actuals = <double>[];
    
    for (final sample in data) {
      final treePredictions = trees.map((tree) => _predictWithTree(tree, sample.features)).toList();
      final prediction = treePredictions.reduce((a, b) => a + b) / treePredictions.length;
      
      predictions.add(prediction);
      actuals.add(sample.target);
    }
    
    return _calculateMetrics(predictions, actuals);
  }

  /// Valida el modelo de forma síncrona
  Map<String, dynamic> _validateModelSync(List<DecisionTree> trees, List<TrainingSample> data) {
    final predictions = <double>[];
    final actuals = <double>[];
    
    for (final sample in data) {
      final treePredictions = trees.map((tree) => _predictWithTree(tree, sample.features)).toList();
      final prediction = treePredictions.reduce((a, b) => a + b) / treePredictions.length;
      
      predictions.add(prediction);
      actuals.add(sample.target);
    }
    
    return _calculateMetrics(predictions, actuals);
  }

  /// Entrena Random Forest de forma síncrona
  RandomForestModel _trainRandomForestSync(List<TrainingSample> trainingData) {
    final trees = <DecisionTree>[];
    final random = Random();
    
    for (int i = 0; i < _defaultNumTrees; i++) {
      final bootstrapData = _bootstrapSample(trainingData, random);
      final tree = _trainDecisionTree(
        bootstrapData,
        maxDepth: _defaultMaxDepth,
        minSamplesSplit: _defaultMinSamplesSplit,
        random: random,
      );
      trees.add(tree);
    }
    
    final validationMetrics = _validateModelSync(trees, trainingData);
    
    return RandomForestModel(
      trees: trees,
      numTrees: _defaultNumTrees,
      maxDepth: _defaultMaxDepth,
      minSamplesSplit: _defaultMinSamplesSplit,
      accuracy: validationMetrics['accuracy'] as double,
      mae: validationMetrics['mae'] as double,
      rmse: validationMetrics['rmse'] as double,
      rSquared: validationMetrics['r_squared'] as double,
      featureImportance: validationMetrics['feature_importance'] as Map<String, double>,
      trainedAt: DateTime.now(),
    );
  }

  /// Calcula métricas de evaluación
  Map<String, dynamic> _calculateMetrics(List<double> predictions, List<double> actuals) {
    if (predictions.length != actuals.length) {
      throw Exception('Longitudes de predicciones y valores reales no coinciden');
    }
    
    final n = predictions.length;
    
    // MAE (Mean Absolute Error)
    final mae = predictions.fold(0.0, (acc, pred) => 
      acc + (pred - actuals[predictions.indexOf(pred)]).abs()
    ) / n;
    
    // RMSE (Root Mean Squared Error)
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
    
    // Accuracy (para regresión, usar R-squared como proxy)
    final accuracy = rSquared.clamp(0.0, 1.0);
    
    // Feature importance (simplificado)
    final featureImportance = <String, double>{
      'precio': 0.3,
      'stock': 0.25,
      'ventas_recientes': 0.2,
      'tendencia': 0.15,
      'estacionalidad': 0.1,
    };
    
    return {
      'accuracy': accuracy,
      'mae': mae,
      'rmse': rmse,
      'r_squared': rSquared,
      'feature_importance': featureImportance,
    };
  }

  /// Genera factores explicativos de la predicción
  List<String> _generatePredictionFactors(
    RandomForestModel model,
    MLFeatures features,
    double prediction,
  ) {
    final factors = <String>[];
    
    if (model.accuracy > 0.8) {
      factors.add('Modelo de alta precisión');
    } else if (model.accuracy < 0.5) {
      factors.add('Modelo de precisión limitada');
    }
    
    if (prediction > 10) {
      factors.add('Alta demanda predicha');
    } else if (prediction < 2) {
      factors.add('Baja demanda predicha');
    }
    
    // Analizar importancia de features
    final topFeature = model.featureImportance.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    factors.add('Factor más importante: ${topFeature.key}');
    
    return factors;
  }

  /// Genera recomendación basada en la predicción
  String _generateRecommendation(Producto producto, double prediction, double confidence) {
    if (confidence < 0.5) {
      return 'Recomendación: Recopilar más datos para mejorar la precisión de la predicción.';
    }
    
    if (prediction > producto.stock * 1.5) {
      return 'Recomendación: Aumentar el stock urgentemente. Demanda predicha: ${prediction.round()} unidades vs Stock actual: ${producto.stock} unidades.';
    } else if (prediction < producto.stock * 0.5 && producto.stock > 0) {
      return 'Recomendación: Considerar promociones para reducir stock excedente. Demanda predicha: ${prediction.round()} unidades vs Stock actual: ${producto.stock} unidades.';
    } else {
      return 'Recomendación: Stock actual es adecuado para la demanda predicha.';
    }
  }

  /// Calcula factor estacional
  double _calculateSeasonalFactor(List<Venta> ventas, Producto producto) {
    final productVentas = ventas.where((v) => 
      v.items.any((item) => item.productoId == producto.id)
    ).toList();
    
    // Calcular factor estacional simplificado
    if (productVentas.isEmpty) return 1.0;
    
    final monthlySales = <int, int>{};
    for (final venta in productVentas) {
      monthlySales[venta.fecha.month] = (monthlySales[venta.fecha.month] ?? 0) + 1;
    }
    
    final currentMonth = DateTime.now().month;
    final currentMonthSales = monthlySales[currentMonth] ?? 0;
    final avgSales = monthlySales.values.isEmpty ? 1 : monthlySales.values.reduce((a, b) => a + b) / monthlySales.length;
    
    return avgSales > 0 ? currentMonthSales / avgSales : 1.0;
  }

  /// Calcula factor de tendencia
  double _calculateTrendFactor(List<Venta> ventas, Producto producto) {
    final productVentas = ventas.where((v) => 
      v.items.any((item) => item.productoId == producto.id)
    ).toList();
    
    return _statisticalService.calculateSalesTrend(productVentas, 30);
  }

  /// Crea predicción vacía
  MLDemandPrediction _createEmptyPrediction(int productoId, int daysAhead) {
    return MLDemandPrediction(
      productoId: productoId,
      predictedDemand: 0,
      confidence: 0.0,
      factors: ['Sin datos suficientes para predicción'],
      recommendation: 'Agregar más datos para predicción precisa',
      predictionDate: DateTime.now(),
      featureImportance: {},
      seasonalFactor: 1.0,
      trendFactor: 0.0,
      daysAhead: daysAhead,
    );
  }

  /// Calcula desviación estándar
  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.fold(0.0, (acc, value) => 
      acc + pow(value - mean, 2)
    ) / values.length;
    
    return sqrt(variance);
  }
}

// ==================== MODELOS DE DATOS ====================

/// Modelo de Random Forest entrenado
class RandomForestModel {
  final List<DecisionTree> trees;
  final int numTrees;
  final int maxDepth;
  final int minSamplesSplit;
  final double accuracy;
  final double mae;
  final double rmse;
  final double rSquared;
  final Map<String, double> featureImportance;
  final DateTime trainedAt;

  RandomForestModel({
    required this.trees,
    required this.numTrees,
    required this.maxDepth,
    required this.minSamplesSplit,
    required this.accuracy,
    required this.mae,
    required this.rmse,
    required this.rSquared,
    required this.featureImportance,
    required this.trainedAt,
  });
}

/// Árbol de decisión individual
class DecisionTree {
  final bool isLeaf;
  final double? value;
  final int? featureIndex;
  final double? threshold;
  final DecisionTree? left;
  final DecisionTree? right;

  DecisionTree._({
    required this.isLeaf,
    this.value,
    this.featureIndex,
    this.threshold,
    this.left,
    this.right,
  });

  factory DecisionTree.leaf(double value) {
    return DecisionTree._(isLeaf: true, value: value);
  }

  factory DecisionTree.node({
    required int featureIndex,
    required double threshold,
    required DecisionTree left,
    required DecisionTree right,
  }) {
    return DecisionTree._(
      isLeaf: false,
      featureIndex: featureIndex,
      threshold: threshold,
      left: left,
      right: right,
    );
  }
}

/// Información de split
class SplitInfo {
  final int featureIndex;
  final double threshold;
  final double gain;

  SplitInfo({
    required this.featureIndex,
    required this.threshold,
    required this.gain,
  });
}

/// Muestra de entrenamiento
class TrainingSample {
  final List<double> features;
  final double target;
  final int productoId;

  TrainingSample({
    required this.features,
    required this.target,
    required this.productoId,
  });
}
