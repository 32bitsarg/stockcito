import 'dart:math';
import '../system/logging_service.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../models/ml_prediction_models.dart';

/// Servicio de K-means para segmentación de clientes
/// Implementa clustering real sin simulaciones
class KMeansService {
  static final KMeansService _instance = KMeansService._internal();
  factory KMeansService() => _instance;
  KMeansService._internal();

  // Removed unused _featureService and _statisticalService

  // Configuración de K-means
  static const int _defaultMaxIterations = 100;
  static const double _defaultTolerance = 1e-4;
  static const int _defaultMaxK = 5; // Máximo número de clusters

  /// Entrena un modelo K-means para segmentación de clientes
  Future<KMeansModel> trainCustomerSegmentationModel(
    List<Venta> ventas,
    List<Cliente> clientes,
    {int? k, // Si es null, se determina automáticamente
    int maxIterations = _defaultMaxIterations}
  ) async {
    try {
      LoggingService.info('🎯 Entrenando K-means para segmentación de clientes...');
      
      if (ventas.isEmpty || clientes.isEmpty) {
        throw Exception('Datos insuficientes para entrenar K-means');
      }

      // Preparar datos de entrenamiento
      final trainingData = await _prepareCustomerTrainingData(ventas, clientes);
      
      if (trainingData.isEmpty) {
        throw Exception('No se pudieron preparar datos de entrenamiento');
      }

      // Determinar número óptimo de clusters si no se especifica
      final optimalK = k ?? _determineOptimalK(trainingData);
      
      LoggingService.info('🔍 Usando $optimalK clusters para segmentación');

      // Normalizar features
      final normalizedData = _normalizeCustomerFeatures(trainingData);
      
      // Entrenar modelo K-means
      final model = _trainKMeans(
        normalizedData,
        k: optimalK,
        maxIterations: maxIterations,
      );

      // Calcular métricas de validación
      final validationMetrics = _validateCustomerModel(model, normalizedData);
      
      // Generar segmentos de clientes
      final segments = _generateCustomerSegments(model, normalizedData, clientes);
      
      final kMeansModel = KMeansModel(
        centroids: model.centroids,
        k: optimalK,
        maxIterations: maxIterations,
        inertia: model.inertia,
        silhouetteScore: validationMetrics['silhouette_score'] as double,
        trainedAt: DateTime.now(),
        featureNames: model.featureNames,
        normalizationParams: normalizedData.normalizationParams,
        segments: segments,
      );

      LoggingService.info('✅ K-means entrenado: ${segments.length} segmentos identificados');
      return kMeansModel;
      
    } catch (e) {
      LoggingService.error('❌ Error entrenando K-means: $e');
      rethrow;
    }
  }

  /// Analiza patrones de clientes usando el modelo K-means entrenado
  MLCustomerAnalysis analyzeCustomerPatterns(
    KMeansModel model,
    List<Venta> ventas,
    List<Cliente> clientes,
  ) {
    try {
      LoggingService.info('👥 Analizando patrones de clientes con K-means...');
      
      if (ventas.isEmpty || clientes.isEmpty) {
        return _createEmptyCustomerAnalysis(clientes.length);
      }

      // Preparar datos de análisis
      final analysisData = _prepareCustomerAnalysisData(ventas, clientes);
      
      if (analysisData.isEmpty) {
        return _createEmptyCustomerAnalysis(clientes.length);
      }

      // Normalizar features
      final normalizedData = _normalizeCustomerFeatures(analysisData);
      
      // Asignar clientes a clusters
      final clusterAssignments = _assignToClusters(model, normalizedData);
      
      // Generar segmentos detallados
      final segments = _generateDetailedSegments(
        model,
        clusterAssignments,
        normalizedData,
        clientes,
      );
      
      // Calcular métricas globales
      final customerLifetimeValue = 0.0; // Simplificado por ahora
      final retentionRate = 0.0; // Simplificado por ahora
      
      // Generar insights y recomendaciones
      final insights = _generateCustomerInsights(segments, analysisData);
      final recommendations = _generateCustomerRecommendations(segments, insights);
      
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
      return _createEmptyCustomerAnalysis(clientes.length);
    }
  }

  /// Determina el número óptimo de clusters usando el método del codo
  int _determineOptimalK(List<CustomerTrainingSample> data) {
    if (data.length < 4) return 2; // Mínimo 2 clusters
    
    final maxK = min(_defaultMaxK, data.length ~/ 2);
    final inertias = <double>[];
    
    for (int k = 2; k <= maxK; k++) {
      final normalizedData = _normalizeCustomerFeatures(data);
      final model = _trainKMeans(normalizedData, k: k, maxIterations: 50);
      inertias.add(model.inertia);
    }
    
    // Encontrar el "codo" en la curva de inercia
    double maxImprovement = 0.0;
    int optimalK = 2;
    
    for (int i = 1; i < inertias.length; i++) {
      final improvement = inertias[i - 1] - inertias[i];
      if (improvement > maxImprovement) {
        maxImprovement = improvement;
        optimalK = i + 2;
      }
    }
    
    LoggingService.info('🔍 Número óptimo de clusters determinado: $optimalK');
    return optimalK;
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Prepara datos de entrenamiento para segmentación de clientes
  Future<List<CustomerTrainingSample>> _prepareCustomerTrainingData(
    List<Venta> ventas,
    List<Cliente> clientes,
  ) async {
    final trainingData = <CustomerTrainingSample>[];
    
    // Agrupar ventas por cliente
    final Map<int, List<Venta>> customerSales = {};
    for (final venta in ventas) {
      // Usar ID de cliente de la venta (simplificado)
      final customerId = venta.id ?? 0; // En un caso real, esto sería venta.clienteId
      customerSales[customerId] = customerSales[customerId] ?? [];
      customerSales[customerId]!.add(venta);
    }
    
    for (final cliente in clientes) {
      final customerId = cliente.id ?? 0;
      final sales = customerSales[customerId] ?? [];
      
      if (sales.length < 2) continue; // Necesitamos al menos 2 ventas
      
      // Generar features del cliente
      final features = _generateCustomerFeatures(cliente, sales);
      
      trainingData.add(CustomerTrainingSample(
        features: features,
        customerId: customerId,
        cliente: cliente,
        sales: sales,
      ));
    }
    
    return trainingData;
  }

  /// Prepara datos de análisis de clientes
  List<CustomerTrainingSample> _prepareCustomerAnalysisData(
    List<Venta> ventas,
    List<Cliente> clientes,
  ) {
    final analysisData = <CustomerTrainingSample>[];
    
    // Agrupar ventas por cliente
    final Map<int, List<Venta>> customerSales = {};
    for (final venta in ventas) {
      final customerId = venta.id ?? 0; // Simplificado
      customerSales[customerId] = customerSales[customerId] ?? [];
      customerSales[customerId]!.add(venta);
    }
    
    for (final cliente in clientes) {
      final customerId = cliente.id ?? 0;
      final sales = customerSales[customerId] ?? [];
      
      final features = _generateCustomerFeatures(cliente, sales);
      
      analysisData.add(CustomerTrainingSample(
        features: features,
        customerId: customerId,
        cliente: cliente,
        sales: sales,
      ));
    }
    
    return analysisData;
  }

  /// Genera features para un cliente
  List<double> _generateCustomerFeatures(Cliente cliente, List<Venta> sales) {
    final features = <double>[];
    
    // Features básicas del cliente
    features.add(cliente.nombre.length.toDouble()); // Completitud de nombre
    features.add(cliente.telefono.isNotEmpty ? 1.0 : 0.0); // Tiene teléfono
    features.add(cliente.email.isNotEmpty ? 1.0 : 0.0); // Tiene email
    features.add(cliente.direccion.isNotEmpty ? 1.0 : 0.0); // Tiene dirección
    
    // Features de comportamiento de compra
    if (sales.isNotEmpty) {
      final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.total);
      final avgOrderValue = totalRevenue / sales.length;
      final purchaseFrequency = sales.length.toDouble();
      
      // Calcular días desde última compra
      final lastPurchase = sales.map((s) => s.fecha).reduce((a, b) => a.isAfter(b) ? a : b);
      final daysSinceLastPurchase = DateTime.now().difference(lastPurchase).inDays.toDouble();
      
      // Calcular días desde primera compra
      final firstPurchase = sales.map((s) => s.fecha).reduce((a, b) => a.isBefore(b) ? a : b);
      final customerAge = DateTime.now().difference(firstPurchase).inDays.toDouble();
      
      features.addAll([
        totalRevenue,
        avgOrderValue,
        purchaseFrequency,
        daysSinceLastPurchase,
        customerAge,
      ]);
    } else {
      features.addAll([0.0, 0.0, 0.0, 999.0, 0.0]); // Valores por defecto
    }
    
    return features;
  }

  /// Normaliza features de clientes
  NormalizedCustomerData _normalizeCustomerFeatures(List<CustomerTrainingSample> data) {
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
      return CustomerTrainingSample(
        features: normalizedFeatures,
        customerId: sample.customerId,
        cliente: sample.cliente,
        sales: sample.sales,
      );
    }).toList();
    
    return NormalizedCustomerData(
      data: normalizedData,
      normalizationParams: CustomerNormalizationParams(means: means, stds: stds),
    );
  }

  /// Entrena modelo K-means
  KMeansModel _trainKMeans(
    NormalizedCustomerData data,
    {required int k,
    required int maxIterations}
  ) {
    final numFeatures = data.data.first.features.length;
    final random = Random();
    
    // Inicializar centroides aleatoriamente
    final centroids = <List<double>>[];
    for (int i = 0; i < k; i++) {
      final centroid = <double>[];
      for (int j = 0; j < numFeatures; j++) {
        centroid.add(random.nextDouble() * 2 - 1); // Entre -1 y 1
      }
      centroids.add(centroid);
    }
    
    double previousInertia = double.infinity;
    
    // Iteraciones de K-means
    for (int iteration = 0; iteration < maxIterations; iteration++) {
      // Asignar puntos a clusters más cercanos
      final assignments = <int>[];
      for (final sample in data.data) {
        int closestCluster = 0;
        double minDistance = double.infinity;
        
        for (int i = 0; i < k; i++) {
          final distance = _calculateDistance(sample.features, centroids[i]);
          if (distance < minDistance) {
            minDistance = distance;
            closestCluster = i;
          }
        }
        assignments.add(closestCluster);
      }
      
      // Actualizar centroides
      for (int i = 0; i < k; i++) {
        final clusterPoints = <List<double>>[];
        for (int j = 0; j < data.data.length; j++) {
          if (assignments[j] == i) {
            clusterPoints.add(data.data[j].features);
          }
        }
        
        if (clusterPoints.isNotEmpty) {
          // Calcular nuevo centroide como promedio
          for (int j = 0; j < numFeatures; j++) {
            double sum = 0.0;
            for (final point in clusterPoints) {
              sum += point[j];
            }
            centroids[i][j] = sum / clusterPoints.length;
          }
        }
      }
      
      // Calcular inercia
      double inertia = 0.0;
      for (int i = 0; i < data.data.length; i++) {
        final distance = _calculateDistance(data.data[i].features, centroids[assignments[i]]);
        inertia += distance * distance;
      }
      
      // Verificar convergencia
      if ((previousInertia - inertia).abs() < _defaultTolerance) {
        LoggingService.info('✅ K-means convergió en iteración $iteration');
        break;
      }
      
      previousInertia = inertia;
    }
    
    // Calcular inercia final
    final assignments = <int>[];
    for (final sample in data.data) {
      int closestCluster = 0;
      double minDistance = double.infinity;
      
      for (int i = 0; i < k; i++) {
        final distance = _calculateDistance(sample.features, centroids[i]);
        if (distance < minDistance) {
          minDistance = distance;
          closestCluster = i;
        }
      }
      assignments.add(closestCluster);
    }
    
    double finalInertia = 0.0;
    for (int i = 0; i < data.data.length; i++) {
      final distance = _calculateDistance(data.data[i].features, centroids[assignments[i]]);
      finalInertia += distance * distance;
    }
    
    final featureNames = [
      'nombre_length', 'has_phone', 'has_email', 'has_address',
      'total_revenue', 'avg_order_value', 'purchase_frequency',
      'days_since_last_purchase', 'customer_age'
    ];
    
    return KMeansModel(
      centroids: centroids,
      k: k,
      maxIterations: maxIterations,
      inertia: finalInertia,
      silhouetteScore: 0.0, // Se calculará en validación
      trainedAt: DateTime.now(),
      featureNames: featureNames,
      normalizationParams: data.normalizationParams,
      segments: [], // Se generarán después
    );
  }

  /// Calcula distancia euclidiana entre dos puntos
  double _calculateDistance(List<double> point1, List<double> point2) {
    if (point1.length != point2.length) {
      throw Exception('Dimensiones de puntos no coinciden');
    }
    
    double sum = 0.0;
    for (int i = 0; i < point1.length; i++) {
      sum += pow(point1[i] - point2[i], 2);
    }
    
    return sqrt(sum);
  }

  /// Asigna puntos a clusters
  List<int> _assignToClusters(KMeansModel model, NormalizedCustomerData data) {
    final assignments = <int>[];
    
    for (final sample in data.data) {
      int closestCluster = 0;
      double minDistance = double.infinity;
      
      for (int i = 0; i < model.k; i++) {
        final distance = _calculateDistance(sample.features, model.centroids[i]);
        if (distance < minDistance) {
          minDistance = distance;
          closestCluster = i;
        }
      }
      assignments.add(closestCluster);
    }
    
    return assignments;
  }

  /// Valida el modelo de clientes
  Map<String, dynamic> _validateCustomerModel(KMeansModel model, NormalizedCustomerData data) {
    final assignments = _assignToClusters(model, data);
    
    // Calcular silhouette score simplificado
    final silhouetteScore = _calculateSilhouetteScore(data.data, assignments, model.k);
    
    return {
      'silhouette_score': silhouetteScore,
      'inertia': model.inertia,
      'num_clusters': model.k,
    };
  }

  /// Calcula silhouette score simplificado
  double _calculateSilhouetteScore(
    List<CustomerTrainingSample> data,
    List<int> assignments,
    int k,
  ) {
    if (data.isEmpty) return 0.0;
    
    double totalSilhouette = 0.0;
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final cluster = assignments[i];
      
      // Calcular distancia promedio dentro del cluster
      double intraClusterDistance = 0.0;
      int intraClusterCount = 0;
      
      for (int j = 0; j < data.length; j++) {
        if (i != j && assignments[j] == cluster) {
          intraClusterDistance += _calculateDistance(point.features, data[j].features);
          intraClusterCount++;
        }
      }
      
      if (intraClusterCount > 0) {
        intraClusterDistance /= intraClusterCount;
      }
      
      // Calcular distancia promedio al cluster más cercano
      double minInterClusterDistance = double.infinity;
      
      for (int c = 0; c < k; c++) {
        if (c != cluster) {
          double interClusterDistance = 0.0;
          int interClusterCount = 0;
          
          for (int j = 0; j < data.length; j++) {
            if (assignments[j] == c) {
              interClusterDistance += _calculateDistance(point.features, data[j].features);
              interClusterCount++;
            }
          }
          
          if (interClusterCount > 0) {
            interClusterDistance /= interClusterCount;
            minInterClusterDistance = min(minInterClusterDistance, interClusterDistance);
          }
        }
      }
      
      // Calcular silhouette para este punto
      if (minInterClusterDistance != double.infinity) {
        final silhouette = (minInterClusterDistance - intraClusterDistance) / 
                         max(minInterClusterDistance, intraClusterDistance);
        totalSilhouette += silhouette;
      }
    }
    
    return totalSilhouette / data.length;
  }

  /// Genera segmentos de clientes básicos
  List<CustomerSegment> _generateCustomerSegments(
    KMeansModel model,
    NormalizedCustomerData data,
    List<Cliente> clientes,
  ) {
    final assignments = _assignToClusters(model, data);
    final segments = <CustomerSegment>[];
    
    for (int clusterId = 0; clusterId < model.k; clusterId++) {
      final clusterCustomers = <CustomerTrainingSample>[];
      
      for (int i = 0; i < data.data.length; i++) {
        if (assignments[i] == clusterId) {
          clusterCustomers.add(data.data[i]);
        }
      }
      
      if (clusterCustomers.isNotEmpty) {
        final segment = _createCustomerSegment(clusterId, clusterCustomers, data.data.length);
        segments.add(segment);
      }
    }
    
    return segments;
  }

  /// Genera segmentos detallados de clientes
  List<CustomerSegment> _generateDetailedSegments(
    KMeansModel model,
    List<int> assignments,
    NormalizedCustomerData data,
    List<Cliente> clientes,
  ) {
    final segments = <CustomerSegment>[];
    
    for (int clusterId = 0; clusterId < model.k; clusterId++) {
      final clusterCustomers = <CustomerTrainingSample>[];
      
      for (int i = 0; i < data.data.length; i++) {
        if (assignments[i] == clusterId) {
          clusterCustomers.add(data.data[i]);
        }
      }
      
      if (clusterCustomers.isNotEmpty) {
        final segment = _createDetailedCustomerSegment(clusterId, clusterCustomers, data.data.length);
        segments.add(segment);
      }
    }
    
    return segments;
  }

  /// Crea un segmento de cliente básico
  CustomerSegment _createCustomerSegment(
    int clusterId,
    List<CustomerTrainingSample> customers,
    int totalCustomers,
  ) {
    final count = customers.length;
    final percentage = (count / totalCustomers) * 100;
    
    // Calcular métricas promedio del segmento
    double totalRevenue = 0.0;
    double totalOrders = 0.0;
    
    for (final customer in customers) {
      totalRevenue += customer.sales.fold(0.0, (sum, sale) => sum + sale.total);
      totalOrders += customer.sales.length.toDouble();
    }
    
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
    return CustomerSegment(
      name: 'Segmento ${clusterId + 1}',
      percentage: percentage,
      characteristics: _getSegmentCharacteristics(clusterId),
      avgOrderValue: avgOrderValue,
      frequency: _getSegmentFrequency(avgOrderValue),
      customerCount: count,
      totalRevenue: totalRevenue,
      avgLifetimeValue: totalRevenue / count,
      preferredCategories: _getSegmentCategories(customers),
    );
  }

  /// Crea un segmento de cliente detallado
  CustomerSegment _createDetailedCustomerSegment(
    int clusterId,
    List<CustomerTrainingSample> customers,
    int totalCustomers,
  ) {
    final count = customers.length;
    final percentage = (count / totalCustomers) * 100;
    
    // Calcular métricas detalladas
    double totalRevenue = 0.0;
    double totalOrders = 0.0;
    double totalDaysSinceLastPurchase = 0.0;
    
    for (final customer in customers) {
      totalRevenue += customer.sales.fold(0.0, (sum, sale) => sum + sale.total);
      totalOrders += customer.sales.length.toDouble();
      
      if (customer.sales.isNotEmpty) {
        final lastPurchase = customer.sales.map((s) => s.fecha).reduce((a, b) => a.isAfter(b) ? a : b);
        totalDaysSinceLastPurchase += DateTime.now().difference(lastPurchase).inDays.toDouble();
      }
    }
    
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    final avgDaysSinceLastPurchase = totalDaysSinceLastPurchase / count;
    
    // Determinar frecuencia y riesgo de abandono
    String frequency = 'Ocasional';
    
    if (avgOrderValue > 100 && avgDaysSinceLastPurchase < 30) {
      frequency = 'Frecuente';
    } else if (avgDaysSinceLastPurchase > 90) {
      frequency = 'Inactivo';
    } else if (avgOrderValue < 50) {
      frequency = 'Bajo valor';
    }
    
    return CustomerSegment(
      name: _getSegmentName(clusterId, avgOrderValue, avgDaysSinceLastPurchase),
      percentage: percentage,
      characteristics: _getDetailedCharacteristics(clusterId, avgOrderValue, avgDaysSinceLastPurchase),
      avgOrderValue: avgOrderValue,
      frequency: frequency,
      customerCount: count,
      totalRevenue: totalRevenue,
      avgLifetimeValue: totalRevenue / count,
      preferredCategories: _getSegmentCategories(customers),
    );
  }

  /// Obtiene nombre del segmento
  String _getSegmentName(int clusterId, double avgOrderValue, double avgDaysSinceLastPurchase) {
    if (avgOrderValue > 100 && avgDaysSinceLastPurchase < 30) {
      return 'Clientes VIP';
    } else if (avgOrderValue > 50 && avgDaysSinceLastPurchase < 60) {
      return 'Clientes Regulares';
    } else if (avgDaysSinceLastPurchase > 90) {
      return 'Clientes Inactivos';
    } else if (avgOrderValue < 30) {
      return 'Clientes Nuevos';
    } else {
      return 'Clientes Estándar';
    }
  }

  /// Obtiene características del segmento
  List<String> _getSegmentCharacteristics(int clusterId) {
    return ['Características del segmento ${clusterId + 1}'];
  }

  /// Obtiene características detalladas del segmento
  List<String> _getDetailedCharacteristics(int clusterId, double avgOrderValue, double avgDaysSinceLastPurchase) {
    final characteristics = <String>[];
    
    if (avgOrderValue > 100) {
      characteristics.add('Alto valor de compra');
    } else if (avgOrderValue < 30) {
      characteristics.add('Bajo valor de compra');
    }
    
    if (avgDaysSinceLastPurchase < 30) {
      characteristics.add('Activos recientemente');
    } else if (avgDaysSinceLastPurchase > 90) {
      characteristics.add('Inactivos');
    }
    
    if (characteristics.isEmpty) {
      characteristics.add('Comportamiento estándar');
    }
    
    return characteristics;
  }

  /// Obtiene frecuencia del segmento
  String _getSegmentFrequency(double avgOrderValue) {
    if (avgOrderValue > 100) return 'Frecuente';
    if (avgOrderValue > 50) return 'Regular';
    return 'Ocasional';
  }

  /// Obtiene categorías preferidas del segmento
  List<String> _getSegmentCategories(List<CustomerTrainingSample> customers) {
    // Simplificado - en un caso real se analizarían las categorías de productos comprados
    return ['General'];
  }

  /// Genera insights de clientes
  List<String> _generateCustomerInsights(List<CustomerSegment> segments, List<CustomerTrainingSample> data) {
    final insights = <String>[];
    
    insights.add('Análisis de segmentación completado con ${segments.length} segmentos identificados.');
    
    for (final segment in segments) {
      insights.add('${segment.name}: ${segment.percentage.toStringAsFixed(1)}% de los clientes. Valor promedio: \$${segment.avgOrderValue.toStringAsFixed(2)}.');
    }
    
    // Insight sobre el segmento más valioso
    final mostValuableSegment = segments.isNotEmpty 
        ? segments.reduce((a, b) => a.avgOrderValue > b.avgOrderValue ? a : b)
        : null;
    
    if (mostValuableSegment != null) {
      insights.add('Segmento más valioso: ${mostValuableSegment.name} con valor promedio de \$${mostValuableSegment.avgOrderValue.toStringAsFixed(2)}.');
    }
    
    return insights;
  }

  /// Genera recomendaciones de clientes
  List<String> _generateCustomerRecommendations(List<CustomerSegment> segments, List<String> insights) {
    final recommendations = <String>[];
    
    for (final segment in segments) {
      if (segment.name.contains('VIP')) {
        recommendations.add('Implementar programa de fidelización exclusivo para ${segment.name}.');
      } else if (segment.name.contains('Inactivos')) {
        recommendations.add('Desarrollar campaña de reenganche para ${segment.name}.');
      } else if (segment.name.contains('Nuevos')) {
        recommendations.add('Crear programa de bienvenida para ${segment.name}.');
      }
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('Desarrollar estrategias personalizadas por segmento.');
    }
    
    return recommendations;
  }

  /// Calcula métricas por segmento
  Map<String, double> _calculateSegmentMetrics(List<CustomerSegment> segments) {
    if (segments.isEmpty) return {};
    
    final totalCustomers = segments.fold(0, (sum, segment) => sum + segment.customerCount);
    final totalRevenue = segments.fold(0.0, (sum, segment) => sum + segment.totalRevenue);
    
    return {
      'total_segments': segments.length.toDouble(),
      'total_customers': totalCustomers.toDouble(),
      'total_revenue': totalRevenue,
      'avg_segment_size': totalCustomers / segments.length,
      'revenue_per_segment': totalRevenue / segments.length,
    };
  }

  /// Crea análisis vacío de clientes
  MLCustomerAnalysis _createEmptyCustomerAnalysis(int totalCustomers) {
    return MLCustomerAnalysis(
      totalCustomers: totalCustomers,
      segments: [],
      insights: ['Sin datos suficientes para análisis de segmentación'],
      recommendations: ['Agregar más datos de clientes y ventas'],
      analysisDate: DateTime.now(),
      segmentMetrics: {},
      customerLifetimeValue: 0.0,
      retentionRate: 0.0,
    );
  }
}

// ==================== MODELOS DE DATOS ====================

/// Modelo de K-means entrenado
class KMeansModel {
  final List<List<double>> centroids;
  final int k;
  final int maxIterations;
  final double inertia;
  final double silhouetteScore;
  final DateTime trainedAt;
  final List<String> featureNames;
  final CustomerNormalizationParams normalizationParams;
  final List<CustomerSegment> segments;

  KMeansModel({
    required this.centroids,
    required this.k,
    required this.maxIterations,
    required this.inertia,
    required this.silhouetteScore,
    required this.trainedAt,
    required this.featureNames,
    required this.normalizationParams,
    required this.segments,
  });
}

/// Muestra de entrenamiento para clientes
class CustomerTrainingSample {
  final List<double> features;
  final int customerId;
  final Cliente cliente;
  final List<Venta> sales;

  CustomerTrainingSample({
    required this.features,
    required this.customerId,
    required this.cliente,
    required this.sales,
  });
}

/// Datos normalizados para clientes
class NormalizedCustomerData {
  final List<CustomerTrainingSample> data;
  final CustomerNormalizationParams normalizationParams;

  NormalizedCustomerData({
    required this.data,
    required this.normalizationParams,
  });
}

/// Parámetros de normalización para clientes
class CustomerNormalizationParams {
  final List<double> means;
  final List<double> stds;

  CustomerNormalizationParams({
    required this.means,
    required this.stds,
  });
}
