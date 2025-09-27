
/// Modelo para predicción de demanda ML
class MLDemandPrediction {
  final int productoId;
  final int predictedDemand;
  final double confidence;
  final List<String> factors;
  final String recommendation;
  final DateTime predictionDate;
  final Map<String, double> featureImportance;
  final double seasonalFactor;
  final double trendFactor;
  final int daysAhead;

  MLDemandPrediction({
    required this.productoId,
    required this.predictedDemand,
    required this.confidence,
    required this.factors,
    required this.recommendation,
    required this.predictionDate,
    required this.featureImportance,
    required this.seasonalFactor,
    required this.trendFactor,
    required this.daysAhead,
  });

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'predictedDemand': predictedDemand,
      'confidence': confidence,
      'factors': factors,
      'recommendation': recommendation,
      'predictionDate': predictionDate.toIso8601String(),
      'featureImportance': featureImportance,
      'seasonalFactor': seasonalFactor,
      'trendFactor': trendFactor,
      'daysAhead': daysAhead,
    };
  }

  factory MLDemandPrediction.fromMap(Map<String, dynamic> map) {
    return MLDemandPrediction(
      productoId: map['productoId'] ?? 0,
      predictedDemand: map['predictedDemand'] ?? 0,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      factors: List<String>.from(map['factors'] ?? []),
      recommendation: map['recommendation'] ?? '',
      predictionDate: DateTime.parse(map['predictionDate'] ?? DateTime.now().toIso8601String()),
      featureImportance: Map<String, double>.from(map['featureImportance'] ?? {}),
      seasonalFactor: map['seasonalFactor']?.toDouble() ?? 1.0,
      trendFactor: map['trendFactor']?.toDouble() ?? 1.0,
      daysAhead: map['daysAhead'] ?? 7,
    );
  }
}

/// Modelo para predicción de precios ML
class MLPricePrediction {
  final int productoId;
  final double currentPrice;
  final double optimalPrice;
  final double confidence;
  final List<String> factors;
  final String recommendation;
  final DateTime predictionDate;
  final double priceElasticity;
  final double demandSensitivity;
  final Map<String, double> marketFactors;

  MLPricePrediction({
    required this.productoId,
    required this.currentPrice,
    required this.optimalPrice,
    required this.confidence,
    required this.factors,
    required this.recommendation,
    required this.predictionDate,
    required this.priceElasticity,
    required this.demandSensitivity,
    required this.marketFactors,
  });

  Map<String, dynamic> toMap() {
    return {
      'productoId': productoId,
      'currentPrice': currentPrice,
      'optimalPrice': optimalPrice,
      'confidence': confidence,
      'factors': factors,
      'recommendation': recommendation,
      'predictionDate': predictionDate.toIso8601String(),
      'priceElasticity': priceElasticity,
      'demandSensitivity': demandSensitivity,
      'marketFactors': marketFactors,
    };
  }

  factory MLPricePrediction.fromMap(Map<String, dynamic> map) {
    return MLPricePrediction(
      productoId: map['productoId'] ?? 0,
      currentPrice: map['currentPrice']?.toDouble() ?? 0.0,
      optimalPrice: map['optimalPrice']?.toDouble() ?? 0.0,
      confidence: map['confidence']?.toDouble() ?? 0.0,
      factors: List<String>.from(map['factors'] ?? []),
      recommendation: map['recommendation'] ?? '',
      predictionDate: DateTime.parse(map['predictionDate'] ?? DateTime.now().toIso8601String()),
      priceElasticity: map['priceElasticity']?.toDouble() ?? 0.0,
      demandSensitivity: map['demandSensitivity']?.toDouble() ?? 0.0,
      marketFactors: Map<String, double>.from(map['marketFactors'] ?? {}),
    );
  }
}

/// Modelo para análisis de clientes ML
class MLCustomerAnalysis {
  final int totalCustomers;
  final List<CustomerSegment> segments;
  final List<String> insights;
  final List<String> recommendations;
  final DateTime analysisDate;
  final Map<String, double> segmentMetrics;
  final double customerLifetimeValue;
  final double retentionRate;

  MLCustomerAnalysis({
    required this.totalCustomers,
    required this.segments,
    required this.insights,
    required this.recommendations,
    required this.analysisDate,
    required this.segmentMetrics,
    required this.customerLifetimeValue,
    required this.retentionRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalCustomers': totalCustomers,
      'segments': segments.map((s) => s.toMap()).toList(),
      'insights': insights,
      'recommendations': recommendations,
      'analysisDate': analysisDate.toIso8601String(),
      'segmentMetrics': segmentMetrics,
      'customerLifetimeValue': customerLifetimeValue,
      'retentionRate': retentionRate,
    };
  }

  factory MLCustomerAnalysis.fromMap(Map<String, dynamic> map) {
    return MLCustomerAnalysis(
      totalCustomers: map['totalCustomers'] ?? 0,
      segments: (map['segments'] as List<dynamic>?)
          ?.map((s) => CustomerSegment.fromMap(s))
          .toList() ?? [],
      insights: List<String>.from(map['insights'] ?? []),
      recommendations: List<String>.from(map['recommendations'] ?? []),
      analysisDate: DateTime.parse(map['analysisDate'] ?? DateTime.now().toIso8601String()),
      segmentMetrics: Map<String, double>.from(map['segmentMetrics'] ?? {}),
      customerLifetimeValue: map['customerLifetimeValue']?.toDouble() ?? 0.0,
      retentionRate: map['retentionRate']?.toDouble() ?? 0.0,
    );
  }
}

/// Modelo para segmento de cliente
class CustomerSegment {
  final String name;
  final double percentage;
  final List<String> characteristics;
  final double avgOrderValue;
  final String frequency;
  final int customerCount;
  final double totalRevenue;
  final double avgLifetimeValue;
  final List<String> preferredCategories;

  CustomerSegment({
    required this.name,
    required this.percentage,
    required this.characteristics,
    required this.avgOrderValue,
    required this.frequency,
    required this.customerCount,
    required this.totalRevenue,
    required this.avgLifetimeValue,
    required this.preferredCategories,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
      'characteristics': characteristics,
      'avgOrderValue': avgOrderValue,
      'frequency': frequency,
      'customerCount': customerCount,
      'totalRevenue': totalRevenue,
      'avgLifetimeValue': avgLifetimeValue,
      'preferredCategories': preferredCategories,
    };
  }

  factory CustomerSegment.fromMap(Map<String, dynamic> map) {
    return CustomerSegment(
      name: map['name'] ?? '',
      percentage: map['percentage']?.toDouble() ?? 0.0,
      characteristics: List<String>.from(map['characteristics'] ?? []),
      avgOrderValue: map['avgOrderValue']?.toDouble() ?? 0.0,
      frequency: map['frequency'] ?? '',
      customerCount: map['customerCount'] ?? 0,
      totalRevenue: map['totalRevenue']?.toDouble() ?? 0.0,
      avgLifetimeValue: map['avgLifetimeValue']?.toDouble() ?? 0.0,
      preferredCategories: List<String>.from(map['preferredCategories'] ?? []),
    );
  }
}

/// Modelo para features de ML
class MLFeatures {
  final List<double> demandFeatures;
  final List<double> priceFeatures;
  final Map<String, dynamic> customerFeatures;
  final Map<String, double> marketFeatures;
  final DateTime featureDate;

  MLFeatures({
    required this.demandFeatures,
    required this.priceFeatures,
    required this.customerFeatures,
    required this.marketFeatures,
    required this.featureDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'demandFeatures': demandFeatures,
      'priceFeatures': priceFeatures,
      'customerFeatures': customerFeatures,
      'marketFeatures': marketFeatures,
      'featureDate': featureDate.toIso8601String(),
    };
  }

  factory MLFeatures.fromMap(Map<String, dynamic> map) {
    return MLFeatures(
      demandFeatures: List<double>.from(map['demandFeatures'] ?? []),
      priceFeatures: List<double>.from(map['priceFeatures'] ?? []),
      customerFeatures: Map<String, dynamic>.from(map['customerFeatures'] ?? {}),
      marketFeatures: Map<String, double>.from(map['marketFeatures'] ?? {}),
      featureDate: DateTime.parse(map['featureDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Modelo para métricas de ML
class MLMetrics {
  final double accuracy;
  final double precision;
  final double recall;
  final double f1Score;
  final double mae; // Mean Absolute Error
  final double rmse; // Root Mean Square Error
  final DateTime evaluationDate;

  MLMetrics({
    required this.accuracy,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.mae,
    required this.rmse,
    required this.evaluationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'accuracy': accuracy,
      'precision': precision,
      'recall': recall,
      'f1Score': f1Score,
      'mae': mae,
      'rmse': rmse,
      'evaluationDate': evaluationDate.toIso8601String(),
    };
  }

  factory MLMetrics.fromMap(Map<String, dynamic> map) {
    return MLMetrics(
      accuracy: map['accuracy']?.toDouble() ?? 0.0,
      precision: map['precision']?.toDouble() ?? 0.0,
      recall: map['recall']?.toDouble() ?? 0.0,
      f1Score: map['f1Score']?.toDouble() ?? 0.0,
      mae: map['mae']?.toDouble() ?? 0.0,
      rmse: map['rmse']?.toDouble() ?? 0.0,
      evaluationDate: DateTime.parse(map['evaluationDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}
