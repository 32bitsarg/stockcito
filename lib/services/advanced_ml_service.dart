import 'dart:math';
import 'datos/datos.dart';
import 'package:ricitosdebb/services/ml_persistence_service.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/models/venta.dart';

class AdvancedMLService {
  static final AdvancedMLService _instance = AdvancedMLService._internal();
  factory AdvancedMLService() => _instance;
  AdvancedMLService._internal();

  final DatosService _datosService = DatosService();
  final MLPersistenceService _persistenceService = MLPersistenceService();
  
  // Datos de entrenamiento persistentes
  List<Map<String, dynamic>> _trainingData = [];
  Map<String, Map<String, dynamic>> _trainedModels = {};

  /// Entrena un modelo de regresión lineal para predicción de demanda
  Future<Map<String, dynamic>> trainDemandPredictionModel(int productoId) async {
    try {
      LoggingService.info('Entrenando modelo de predicción de demanda para producto $productoId');
      
      // Obtener datos históricos
      final ventas = await _getProductSalesHistory(productoId);
      if (ventas.length < 10) {
        throw Exception('Datos insuficientes para entrenar modelo (mínimo 10 ventas)');
      }

      // Preparar features y targets
      final features = <List<double>>[];
      final targets = <double>[];
      
      for (int i = 7; i < ventas.length; i++) {
        final feature = _extractDemandFeatures(ventas, i);
        final target = _calculateDemandTarget(ventas, i);
        
        features.add(feature);
        targets.add(target);
      }

      // Entrenar modelo de regresión lineal
      final model = _trainLinearRegression(features, targets);
      
      // Guardar modelo entrenado
      _trainedModels['demand_$productoId'] = model;
      
      // Guardar en Supabase
      await _persistenceService.saveMLModel(model, 'demand_$productoId');
      
      // Guardar datos de entrenamiento
      for (int i = 0; i < features.length; i++) {
        final trainingData = {
          'features': features[i],
          'target': targets[i],
          'timestamp': DateTime.now().toIso8601String(),
        };
        await _persistenceService.saveTrainingData(trainingData);
      }
      
      LoggingService.info('Modelo de demanda entrenado y guardado en Firebase para producto $productoId');
      return model;
      
    } catch (e) {
      LoggingService.error('Error entrenando modelo de demanda: $e');
      rethrow;
    }
  }

  /// Entrena un modelo de clustering para segmentación de clientes
  Future<Map<String, dynamic>> trainCustomerSegmentationModel() async {
    try {
      LoggingService.info('Entrenando modelo de segmentación de clientes');
      
      final ventas = await _datosService.getAllVentas();
      final clientes = await _datosService.getAllClientes();
      
      if (ventas.length < 20) {
        throw Exception('Datos insuficientes para segmentación (mínimo 20 ventas)');
      }

      // Preparar datos de clientes
      final customerFeatures = <List<double>>[];
      final customerIds = <int>[];
      
      for (final cliente in clientes) {
        final features = _extractCustomerFeatures(cliente, ventas);
        customerFeatures.add(features);
        if (cliente.id != null) {
          customerIds.add(cliente.id!);
        }
      }

      // Entrenar clustering K-means
      final model = _trainKMeansClustering(customerFeatures, 3); // 3 segmentos
      
      // Guardar modelo entrenado
      _trainedModels['customer_segmentation'] = model;
      
      // Guardar en Supabase
      await _persistenceService.saveMLModel(model, 'customer_segmentation');
      
      LoggingService.info('Modelo de segmentación de clientes entrenado y guardado en Supabase');
      return model;
      
    } catch (e) {
      LoggingService.error('Error entrenando modelo de segmentación: $e');
      rethrow;
    }
  }

  /// Predice demanda usando modelo entrenado
  Future<Map<String, dynamic>> predictDemand(int productoId, int daysAhead) async {
    try {
      // Inicializar persistencia si no está inicializada
      if (_trainingData.isEmpty) {
        await loadTrainingData();
      }
      
      // Obtener o entrenar modelo
      Map<String, dynamic> model = _trainedModels['demand_$productoId'] ?? 
                     await trainDemandPredictionModel(productoId);
      
      // Obtener datos recientes
      final ventas = await _getProductSalesHistory(productoId);
      if (ventas.isEmpty) {
        return {
          'value': 0,
          'confidence': 0.0,
          'factors': ['Sin datos históricos'],
        };
      }

      // Preparar features para predicción
      final features = _extractDemandFeatures(ventas, ventas.length - 1);
      
      // Hacer predicción
      final prediction = _predictWithModel(model, features);
      
      // Calcular confianza basada en la calidad del modelo
      final confidence = _calculateModelConfidence(model, features);
      
      // Generar factores explicativos
      final factors = _generatePredictionFactors(model, features, prediction);
      
      // Crear predicción
      final mlPrediction = {
        'value': prediction,
        'confidence': confidence,
        'factors': factors,
      };
      
      // Guardar predicción en Supabase
      await _persistenceService.savePrediction(mlPrediction, productoId.toString());
      
      return mlPrediction;
      
    } catch (e) {
      LoggingService.error('Error prediciendo demanda: $e');
      return {
        'value': 0,
        'confidence': 0.0,
        'factors': ['Error en predicción'],
      };
    }
  }

  /// Segmenta clientes usando modelo entrenado
  Future<List<CustomerSegment>> segmentCustomers() async {
    try {
      // Obtener o entrenar modelo
      Map<String, dynamic> model = _trainedModels['customer_segmentation'] ?? 
                     await trainCustomerSegmentationModel();
      
      final clientes = await _datosService.getAllClientes();
      final ventas = await _datosService.getAllVentas();
      
      final segments = <CustomerSegment>[];
      
      for (final cliente in clientes) {
        final features = _extractCustomerFeatures(cliente, ventas);
        final segmentId = _predictSegment(model, features);
        
        // Agregar cliente al segmento correspondiente
        if (segmentId < segments.length) {
          segments[segmentId].customers.add(cliente);
        } else {
          segments.add(CustomerSegment(
            id: segmentId,
            name: 'Segmento ${segmentId + 1}',
            customers: [cliente],
            characteristics: _getSegmentCharacteristics(segmentId),
          ));
        }
      }
      
      return segments;
      
    } catch (e) {
      LoggingService.error('Error segmentando clientes: $e');
      return [];
    }
  }

  /// Entrena un modelo de regresión lineal
  Map<String, dynamic> _trainLinearRegression(List<List<double>> features, List<double> targets) {
    final n = features.length;
    final m = features[0].length;
    
    // Normalizar features
    final normalizedFeatures = _normalizeFeatures(features);
    
    // Inicializar pesos aleatoriamente
    final weights = List.generate(m + 1, (i) => Random().nextDouble() * 0.1);
    
    // Entrenar con descenso de gradiente
    const learningRate = 0.01;
    const epochs = 1000;
    
    for (int epoch = 0; epoch < epochs; epoch++) {
      double totalError = 0.0;
      
      for (int i = 0; i < n; i++) {
        // Calcular predicción
        double prediction = weights[0]; // bias
        for (int j = 0; j < m; j++) {
          prediction += weights[j + 1] * normalizedFeatures[i][j];
        }
        
        // Calcular error
        final error = prediction - targets[i];
        totalError += error * error;
        
        // Actualizar pesos
        weights[0] -= learningRate * error; // bias
        for (int j = 0; j < m; j++) {
          weights[j + 1] -= learningRate * error * normalizedFeatures[i][j];
        }
      }
      
      // Parar si el error es muy pequeño
      if (totalError / n < 0.001) break;
    }
    
    return {
      'type': 'linearRegression',
      'weights': weights,
      'featureMeans': _calculateMeans(features),
      'featureStds': _calculateStds(features),
      'accuracy': _calculateAccuracy(normalizedFeatures, targets, weights),
    };
  }

  /// Entrena clustering K-means
  Map<String, dynamic> _trainKMeansClustering(List<List<double>> features, int k) {
    final n = features.length;
    final m = features[0].length;
    
    // Normalizar features
    final normalizedFeatures = _normalizeFeatures(features);
    
    // Inicializar centroides aleatoriamente
    final centroids = List.generate(k, (i) => 
      List.generate(m, (j) => Random().nextDouble()));
    
    // Iterar hasta convergencia
    for (int iteration = 0; iteration < 100; iteration++) {
      final clusters = List.generate(n, (i) => 0);
      
      // Asignar puntos a clusters más cercanos
      for (int i = 0; i < n; i++) {
        double minDistance = double.infinity;
        int closestCluster = 0;
        
        for (int j = 0; j < k; j++) {
          final distance = _calculateDistance(normalizedFeatures[i], centroids[j]);
          if (distance < minDistance) {
            minDistance = distance;
            closestCluster = j;
          }
        }
        
        clusters[i] = closestCluster;
      }
      
      // Actualizar centroides
      final newCentroids = List.generate(k, (i) => List.generate(m, (j) => 0.0));
      final clusterCounts = List.generate(k, (i) => 0);
      
      for (int i = 0; i < n; i++) {
        final cluster = clusters[i];
        clusterCounts[cluster]++;
        for (int j = 0; j < m; j++) {
          newCentroids[cluster][j] += normalizedFeatures[i][j];
        }
      }
      
      // Calcular promedios
      bool converged = true;
      for (int i = 0; i < k; i++) {
        if (clusterCounts[i] > 0) {
          for (int j = 0; j < m; j++) {
            newCentroids[i][j] /= clusterCounts[i];
          }
          
          // Verificar convergencia
          final distance = _calculateDistance(centroids[i], newCentroids[i]);
          if (distance > 0.001) converged = false;
        }
      }
      
      centroids.setAll(0, newCentroids);
      
      if (converged) break;
    }
    
    return {
      'type': 'kMeans',
      'centroids': centroids,
      'featureMeans': _calculateMeans(features),
      'featureStds': _calculateStds(features),
      'accuracy': _calculateClusteringAccuracy(normalizedFeatures, centroids),
    };
  }

  /// Extrae features para predicción de demanda
  List<double> _extractDemandFeatures(List<Venta> ventas, int index) {
    final now = ventas[index].fecha;
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));
    
    // Ventas últimos 7 días
    final ventas7Dias = ventas.where((v) => v.fecha.isAfter(last7Days)).length;
    
    // Ventas últimos 30 días
    final ventas30Dias = ventas.where((v) => v.fecha.isAfter(last30Days)).length;
    
    // Día de la semana (0-6)
    final diaSemana = now.weekday / 7.0;
    
    // Mes (0-11)
    final mes = now.month / 12.0;
    
    // Tendencia (crecimiento semanal)
    final tendencia = ventas30Dias > 0 ? ventas7Dias / (ventas30Dias / 4.0) : 1.0;
    
    return [
      ventas7Dias.toDouble(),
      ventas30Dias.toDouble(),
      diaSemana,
      mes,
      tendencia,
    ];
  }

  /// Calcula target para entrenamiento de demanda
  double _calculateDemandTarget(List<Venta> ventas, int index) {
    // Demanda de los próximos 7 días
    final startDate = ventas[index].fecha;
    final endDate = startDate.add(const Duration(days: 7));
    
    final futureVentas = ventas.where((v) => 
      v.fecha.isAfter(startDate) && v.fecha.isBefore(endDate)).length;
    
    return futureVentas.toDouble();
  }

  /// Extrae features para segmentación de clientes
  List<double> _extractCustomerFeatures(dynamic cliente, List<Venta> ventas) {
    // Buscar ventas por nombre de cliente (ya que Venta no tiene clienteId)
    final clienteVentas = ventas.where((v) => v.cliente == cliente.nombre).toList();
    
    // Frecuencia de compra (ventas por mes)
    final frecuencia = clienteVentas.length / 12.0;
    
    // Valor promedio de compra
    final valorPromedio = clienteVentas.isNotEmpty 
        ? clienteVentas.map((v) => v.total).reduce((a, b) => a + b) / clienteVentas.length
        : 0.0;
    
    // Días desde última compra
    final ultimaCompra = clienteVentas.isNotEmpty
        ? clienteVentas.map((v) => v.fecha).reduce((a, b) => a.isAfter(b) ? a : b)
        : DateTime.now().subtract(const Duration(days: 365));
    
    final diasUltimaCompra = DateTime.now().difference(ultimaCompra).inDays / 365.0;
    
    return [
      frecuencia,
      valorPromedio / 1000.0, // Normalizar
      diasUltimaCompra,
    ];
  }

  /// Normaliza features para entrenamiento
  List<List<double>> _normalizeFeatures(List<List<double>> features) {
    if (features.isEmpty) return features;
    
    final m = features[0].length;
    final normalized = <List<double>>[];
    
    for (int j = 0; j < m; j++) {
      final column = features.map((f) => f[j]).toList();
      final mean = column.reduce((a, b) => a + b) / column.length;
      final std = sqrt(column.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / column.length);
      
      for (int i = 0; i < features.length; i++) {
        if (i >= normalized.length) normalized.add(List.filled(m, 0.0));
        normalized[i][j] = std > 0 ? (features[i][j] - mean) / std : 0.0;
      }
    }
    
    return normalized;
  }

  /// Calcula medias de features
  List<double> _calculateMeans(List<List<double>> features) {
    if (features.isEmpty) return [];
    
    final m = features[0].length;
    final means = <double>[];
    
    for (int j = 0; j < m; j++) {
      final column = features.map((f) => f[j]).toList();
      means.add(column.reduce((a, b) => a + b) / column.length);
    }
    
    return means;
  }

  /// Calcula desviaciones estándar de features
  List<double> _calculateStds(List<List<double>> features) {
    if (features.isEmpty) return [];
    
    final m = features[0].length;
    final stds = <double>[];
    
    for (int j = 0; j < m; j++) {
      final column = features.map((f) => f[j]).toList();
      final mean = column.reduce((a, b) => a + b) / column.length;
      final variance = column.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / column.length;
      stds.add(sqrt(variance));
    }
    
    return stds;
  }

  /// Calcula distancia euclidiana
  double _calculateDistance(List<double> a, List<double> b) {
    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow(a[i] - b[i], 2);
    }
    return sqrt(sum);
  }

  /// Predice usando modelo entrenado
  double _predictWithModel(Map<String, dynamic> model, List<double> features) {
    if (model['type'] == 'linearRegression' && model['weights'] != null) {
      // Normalizar features
      final normalized = <double>[];
      final featureStds = List<double>.from(model['featureStds'] ?? []);
      final featureMeans = List<double>.from(model['featureMeans'] ?? []);
      
      for (int i = 0; i < features.length; i++) {
        final normalizedValue = featureStds[i] > 0 
            ? (features[i] - featureMeans[i]) / featureStds[i]
            : 0.0;
        normalized.add(normalizedValue);
      }
      
      // Calcular predicción
      final weights = List<double>.from(model['weights'] ?? []);
      double prediction = weights[0]; // bias
      for (int i = 0; i < normalized.length; i++) {
        prediction += weights[i + 1] * normalized[i];
      }
      
      return prediction;
    }
    
    return 0.0;
  }

  /// Predice segmento de cliente
  int _predictSegment(Map<String, dynamic> model, List<double> features) {
    if (model['type'] == 'kMeans' && model['centroids'] != null) {
      // Normalizar features
      final normalized = <double>[];
      final featureStds = List<double>.from(model['featureStds'] ?? []);
      final featureMeans = List<double>.from(model['featureMeans'] ?? []);
      
      for (int i = 0; i < features.length; i++) {
        final normalizedValue = featureStds[i] > 0 
            ? (features[i] - featureMeans[i]) / featureStds[i]
            : 0.0;
        normalized.add(normalizedValue);
      }
      
      // Encontrar centroide más cercano
      double minDistance = double.infinity;
      int closestCentroid = 0;
      
      final centroids = List<List<double>>.from(model['centroids'] ?? []);
      for (int i = 0; i < centroids.length; i++) {
        final distance = _calculateDistance(normalized, centroids[i]);
        if (distance < minDistance) {
          minDistance = distance;
          closestCentroid = i;
        }
      }
      
      return closestCentroid;
    }
    
    return 0;
  }

  /// Calcula confianza del modelo
  double _calculateModelConfidence(Map<String, dynamic> model, List<double> features) {
    // Basado en la precisión del modelo y la calidad de los datos
    double confidence = (model['accuracy'] ?? 0.0).toDouble();
    
    // Ajustar por calidad de features
    final featureQuality = features.every((f) => f.isFinite && !f.isNaN) ? 1.0 : 0.5;
    confidence *= featureQuality;
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Genera factores explicativos para predicción
  List<String> _generatePredictionFactors(Map<String, dynamic> model, List<double> features, double prediction) {
    final factors = <String>[];
    
    final accuracy = (model['accuracy'] ?? 0.0).toDouble();
    if (accuracy > 0.8) {
      factors.add('Modelo de alta precisión (${(accuracy * 100).toStringAsFixed(1)}%)');
    }
    
    if (features[0] > 5) { // Ventas últimos 7 días
      factors.add('Alta actividad reciente');
    }
    
    if (features[4] > 1.2) { // Tendencia
      factors.add('Tendencia alcista detectada');
    }
    
    return factors;
  }

  /// Obtiene características del segmento
  List<String> _getSegmentCharacteristics(int segmentId) {
    switch (segmentId) {
      case 0:
        return ['Alto valor', 'Frecuentes', 'Leales'];
      case 1:
        return ['Valor medio', 'Ocasionales', 'Estables'];
      case 2:
        return ['Bajo valor', 'Primera compra', 'Potencial'];
      default:
        return ['Segmento personalizado'];
    }
  }

  /// Calcula precisión del modelo de regresión
  double _calculateAccuracy(List<List<double>> features, List<double> targets, List<double> weights) {
    double totalError = 0.0;
    
    for (int i = 0; i < features.length; i++) {
      double prediction = weights[0]; // bias
      for (int j = 0; j < features[i].length; j++) {
        prediction += weights[j + 1] * features[i][j];
      }
      
      final error = (prediction - targets[i]).abs();
      totalError += error;
    }
    
    final avgError = totalError / features.length;
    final maxTarget = targets.reduce((a, b) => a > b ? a : b);
    
    return (1.0 - (avgError / maxTarget)).clamp(0.0, 1.0);
  }

  /// Calcula precisión del clustering
  double _calculateClusteringAccuracy(List<List<double>> features, List<List<double>> centroids) {
    double totalDistance = 0.0;
    
    for (final feature in features) {
      double minDistance = double.infinity;
      for (final centroid in centroids) {
        final distance = _calculateDistance(feature, centroid);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      totalDistance += minDistance;
    }
    
    final avgDistance = totalDistance / features.length;
    return (1.0 - avgDistance).clamp(0.0, 1.0);
  }

  /// Obtiene historial de ventas de un producto
  Future<List<Venta>> _getProductSalesHistory(int productoId) async {
    final allVentas = await _datosService.getAllVentas();
    return allVentas.where((venta) => 
      venta.items.any((item) => item.productoId == productoId)
    ).toList();
  }

  /// Guarda datos de entrenamiento en Firebase
  Future<void> saveTrainingData() async {
    try {
      await _persistenceService.initialize();
      for (final data in _trainingData) {
        await _persistenceService.saveTrainingData(data);
      }
      LoggingService.info('Datos de entrenamiento ML guardados en Firebase');
    } catch (e) {
      LoggingService.error('Error guardando datos de entrenamiento: $e');
    }
  }

  /// Carga datos de entrenamiento desde Supabase
  Future<void> loadTrainingData() async {
    try {
      await _persistenceService.initialize();
      _trainingData = await _persistenceService.loadTrainingData();
      
      // Cargar modelos entrenados
      await _loadTrainedModels();
      
      LoggingService.info('${_trainingData.length} datos de entrenamiento ML cargados desde Supabase');
    } catch (e) {
      LoggingService.error('Error cargando datos de entrenamiento: $e');
    }
  }

  /// Carga modelos entrenados desde Supabase
  Future<void> _loadTrainedModels() async {
    try {
      // Cargar modelo de segmentación de clientes
      final customerModel = await _persistenceService.loadMLModel('customer_segmentation');
      if (customerModel != null) {
        _trainedModels['customer_segmentation'] = customerModel;
        LoggingService.info('Modelo de segmentación de clientes cargado desde Supabase');
      }
      
      // Cargar modelos de demanda (se cargarán bajo demanda)
      LoggingService.info('Modelos ML cargados desde Supabase');
    } catch (e) {
      LoggingService.error('Error cargando modelos ML: $e');
    }
  }
}

// Modelos de datos para ML avanzado
class MLTrainingData {
  final List<double> features;
  final double target;
  final DateTime timestamp;

  MLTrainingData({
    required this.features,
    required this.target,
    required this.timestamp,
  });
}

class MLModel {
  final MLModelType type;
  final List<double>? weights;
  final List<List<double>>? centroids;
  final List<double> featureMeans;
  final List<double> featureStds;
  final double accuracy;

  MLModel({
    required this.type,
    this.weights,
    this.centroids,
    required this.featureMeans,
    required this.featureStds,
    required this.accuracy,
  });
}

enum MLModelType {
  linearRegression,
  kMeans,
}

class MLPrediction {
  final double value;
  final double confidence;
  final List<String> factors;

  MLPrediction({
    required this.value,
    required this.confidence,
    required this.factors,
  });
}

class CustomerSegment {
  final int id;
  final String name;
  final List<dynamic> customers;
  final List<String> characteristics;

  CustomerSegment({
    required this.id,
    required this.name,
    required this.customers,
    required this.characteristics,
  });
}
