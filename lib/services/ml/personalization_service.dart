import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/logging_service.dart';
import '../auth/supabase_auth_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../models/ml_prediction_models.dart';
import 'random_forest_service.dart';
import 'elastic_net_service.dart';
import 'kmeans_service.dart';
import 'ml_data_validation_service.dart';

/// Servicio de personalización para adaptar modelos ML a usuarios individuales
/// Implementa capa de personalización y feedback loop
class PersonalizationService {
  static final PersonalizationService _instance = PersonalizationService._internal();
  factory PersonalizationService() => _instance;
  PersonalizationService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  final RandomForestService _randomForestService = RandomForestService();
  final ElasticNetService _elasticNetService = ElasticNetService();
  final KMeansService _kmeansService = KMeansService();
  final MLDataValidationService _validationService = MLDataValidationService();

  // Claves para almacenar datos de personalización
  static const String _userPreferencesKey = 'user_ml_preferences';
  static const String _feedbackHistoryKey = 'user_feedback_history';
  static const String _personalizationWeightsKey = 'personalization_weights';

  /// Genera recomendaciones personalizadas para el usuario
  Future<List<MLRecommendation>> generatePersonalizedRecommendations({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
  }) async {
    try {
      LoggingService.info('🎯 Generando recomendaciones personalizadas...');
      
      // Validar datos antes de generar recomendaciones
      final demandValidation = _validationService.validateDemandTrainingData(ventas, productos);
      final priceValidation = _validationService.validatePriceTrainingData(ventas, productos);
      final customerValidation = _validationService.validateCustomerSegmentationData(ventas, clientes);
      
      // Si no hay datos suficientes, retornar recomendaciones básicas
      if (!demandValidation.isValid && !priceValidation.isValid && !customerValidation.isValid) {
        LoggingService.warning('⚠️ Datos insuficientes para recomendaciones personalizadas');
        return _generateBasicRecommendations(productos, ventas, clientes);
      }
      
      final recommendations = <MLRecommendation>[];
      
      // 1. Predicciones de demanda personalizadas (solo si hay datos suficientes)
      if (demandValidation.isValid) {
        final demandRecommendations = await _generateDemandRecommendations(productos, ventas);
        recommendations.addAll(demandRecommendations);
      }
      
      // 2. Optimización de precios personalizada (solo si hay datos suficientes)
      if (priceValidation.isValid) {
        final priceRecommendations = await _generatePriceRecommendations(productos, ventas);
        recommendations.addAll(priceRecommendations);
      }
      
      // 3. Análisis de clientes personalizado (solo si hay datos suficientes)
      if (customerValidation.isValid) {
        final customerRecommendations = await _generateCustomerRecommendations(ventas, clientes);
        recommendations.addAll(customerRecommendations);
      }
      
      // Si no se generaron recomendaciones, usar básicas
      if (recommendations.isEmpty) {
        return _generateBasicRecommendations(productos, ventas, clientes);
      }
      
      // 4. Aplicar personalización basada en feedback histórico
      final personalizedRecommendations = await _applyPersonalization(recommendations);
      
      // 5. Ordenar por relevancia personalizada
      personalizedRecommendations.sort((a, b) => b.priority.compareTo(a.priority));
      
      LoggingService.info('✅ ${personalizedRecommendations.length} recomendaciones personalizadas generadas');
      return personalizedRecommendations;
      
    } catch (e) {
      LoggingService.error('❌ Error generando recomendaciones personalizadas: $e');
      return [];
    }
  }

  /// Genera recomendaciones básicas cuando no hay datos suficientes para ML
  List<MLRecommendation> _generateBasicRecommendations(
    List<Producto> productos, 
    List<Venta> ventas, 
    List<Cliente> clientes
  ) {
    final recommendations = <MLRecommendation>[];
    
    // Recomendación básica de inventario
    if (productos.isNotEmpty) {
      recommendations.add(MLRecommendation(
        id: 'basic_inventory_${DateTime.now().millisecondsSinceEpoch}',
        type: RecommendationType.demand,
        title: '📦 Gestión de Inventario',
        description: 'Mantén un registro detallado de tus productos para obtener mejores predicciones',
        priority: 7,
        confidence: 0.8,
        factors: ['Inventario', 'Productos'],
        actionRequired: 'Agrega más productos y registra sus ventas',
        createdAt: DateTime.now(),
      ));
    }
    
    // Recomendación básica de ventas
    if (ventas.isEmpty) {
      recommendations.add(MLRecommendation(
        id: 'basic_sales_${DateTime.now().millisecondsSinceEpoch}',
        type: RecommendationType.demand,
        title: '💰 Registra tus Ventas',
        description: 'Cada venta registrada mejora las predicciones de demanda',
        priority: 9,
        confidence: 0.9,
        factors: ['Ventas', 'Historial'],
        actionRequired: 'Comienza registrando tus primeras ventas',
        createdAt: DateTime.now(),
      ));
    }
    
    // Recomendación básica de clientes
    if (clientes.length < 3) {
      recommendations.add(MLRecommendation(
        id: 'basic_customers_${DateTime.now().millisecondsSinceEpoch}',
        type: RecommendationType.customer,
        title: '👥 Registra tus Clientes',
        description: 'Con más clientes podrás obtener segmentaciones personalizadas',
        priority: 6,
        confidence: 0.8,
        factors: ['Clientes', 'Segmentación'],
        actionRequired: 'Agrega información de tus clientes',
        createdAt: DateTime.now(),
      ));
    }
    
    LoggingService.info('✅ ${recommendations.length} recomendaciones básicas generadas');
    return recommendations;
  }

  /// Registra feedback del usuario sobre una recomendación
  Future<void> recordFeedback({
    required String recommendationId,
    required FeedbackType feedbackType,
    required double rating, // 1-5
    String? comment,
  }) async {
    try {
      LoggingService.info('📝 Registrando feedback para recomendación $recommendationId');
      
      final feedback = MLFeedback(
        recommendationId: recommendationId,
        feedbackType: feedbackType,
        rating: rating,
        comment: comment,
        timestamp: DateTime.now(),
        userId: _authService.currentUserId,
      );
      
      // Guardar feedback localmente
      await _saveFeedbackLocally(feedback);
      
      // Actualizar pesos de personalización
      await _updatePersonalizationWeights(feedback);
      
      // Si es usuario autenticado, enviar a Supabase
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _saveFeedbackToSupabase(feedback);
      }
      
      LoggingService.info('✅ Feedback registrado correctamente');
      
    } catch (e) {
      LoggingService.error('❌ Error registrando feedback: $e');
    }
  }

  /// Obtiene insights personalizados del usuario
  Future<MLInsights> generatePersonalizedInsights({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
  }) async {
    try {
      LoggingService.info('🔍 Generando insights personalizados...');
      
      // Obtener preferencias del usuario
      final userPreferences = await _getUserPreferences();
      
      // Generar insights básicos
      final basicInsights = await _generateBasicInsights(productos, ventas, clientes);
      
      // Personalizar insights basado en historial
      final personalizedInsights = await _personalizeInsights(basicInsights, userPreferences);
      
      LoggingService.info('✅ Insights personalizados generados');
      return personalizedInsights;
      
    } catch (e) {
      LoggingService.error('❌ Error generando insights personalizados: $e');
      return MLInsights.empty();
    }
  }

  /// Obtiene estadísticas de personalización del usuario
  Future<Map<String, dynamic>> getPersonalizationStats() async {
    try {
      final preferences = await _getUserPreferences();
      final feedbackHistory = await _getFeedbackHistory();
      final weights = await _getPersonalizationWeights();
      
      return {
        'user_preferences': preferences,
        'total_feedback': feedbackHistory.length,
        'avg_rating': _calculateAverageRating(feedbackHistory),
        'personalization_weights': weights,
        'personalization_score': _calculatePersonalizationScore(weights),
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de personalización: $e');
      return {};
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Genera recomendaciones de demanda personalizadas
  Future<List<MLRecommendation>> _generateDemandRecommendations(
    List<Producto> productos,
    List<Venta> ventas,
  ) async {
    final recommendations = <MLRecommendation>[];
    
    try {
      // Entrenar modelo Random Forest personalizado
      final model = await _randomForestService.trainDemandModel(ventas, productos);
      
      for (final producto in productos.take(5)) { // Top 5 productos
        final prediction = _randomForestService.predictDemand(model, producto, ventas, 7);
        
        if (prediction.confidence > 0.6) {
          recommendations.add(MLRecommendation(
            id: 'demand_${producto.id}',
            type: RecommendationType.demand,
            title: _generateDemandTitle(producto, prediction),
            description: prediction.recommendation,
            priority: _calculateDemandPriority(prediction),
            confidence: prediction.confidence,
            factors: prediction.factors,
            actionRequired: _determineDemandAction(prediction, producto),
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      LoggingService.error('Error generando recomendaciones de demanda: $e');
    }
    
    return recommendations;
  }

  /// Genera recomendaciones de precio personalizadas
  Future<List<MLRecommendation>> _generatePriceRecommendations(
    List<Producto> productos,
    List<Venta> ventas,
  ) async {
    final recommendations = <MLRecommendation>[];
    
    try {
      // Entrenar modelo Elastic Net personalizado
      final model = await _elasticNetService.trainPriceModel(ventas, productos);
      
      for (final producto in productos.take(3)) { // Top 3 productos
        final prediction = _elasticNetService.predictOptimalPrice(model, producto, ventas);
        
        if (prediction.confidence > 0.6) {
          final priceDiff = prediction.optimalPrice - prediction.currentPrice;
          final percentDiff = (priceDiff / prediction.currentPrice * 100).abs();
          
          if (percentDiff > 5) { // Solo si hay diferencia significativa
            recommendations.add(MLRecommendation(
              id: 'price_${producto.id}',
              type: RecommendationType.pricing,
              title: _generatePriceTitle(producto, prediction),
              description: prediction.recommendation,
              priority: _calculatePricePriority(prediction, percentDiff),
              confidence: prediction.confidence,
              factors: prediction.factors,
              actionRequired: _determinePriceAction(prediction),
              createdAt: DateTime.now(),
            ));
          }
        }
      }
    } catch (e) {
      LoggingService.error('Error generando recomendaciones de precio: $e');
    }
    
    return recommendations;
  }

  /// Genera recomendaciones de clientes personalizadas
  Future<List<MLRecommendation>> _generateCustomerRecommendations(
    List<Venta> ventas,
    List<Cliente> clientes,
  ) async {
    final recommendations = <MLRecommendation>[];
    
    try {
      if (clientes.length < 10) return recommendations; // Necesitamos suficientes clientes
      
      // Entrenar modelo K-means personalizado
      final model = await _kmeansService.trainCustomerSegmentationModel(ventas, clientes);
      
      // Analizar patrones de clientes
      final analysis = _kmeansService.analyzeCustomerPatterns(model, ventas, clientes);
      
      // Generar recomendaciones basadas en segmentos
      for (final segment in analysis.segments) {
        if (segment.percentage > 10) { // Solo segmentos significativos
          recommendations.add(MLRecommendation(
            id: 'customer_${segment.name}',
            type: RecommendationType.customer,
            title: _generateCustomerTitle(segment),
            description: _generateCustomerDescription(segment),
            priority: _calculateCustomerPriority(segment),
            confidence: 0.8, // Alta confianza para segmentación
            factors: segment.characteristics,
            actionRequired: _determineCustomerAction(segment),
            createdAt: DateTime.now(),
          ));
        }
      }
    } catch (e) {
      LoggingService.error('Error generando recomendaciones de clientes: $e');
    }
    
    return recommendations;
  }

  /// Aplica personalización basada en feedback histórico
  Future<List<MLRecommendation>> _applyPersonalization(List<MLRecommendation> recommendations) async {
    try {
      final weights = await _getPersonalizationWeights();
      final feedbackHistory = await _getFeedbackHistory();
      
      for (final recommendation in recommendations) {
        // Ajustar prioridad basada en feedback histórico
        final historicalRating = _getHistoricalRating(recommendation.type, feedbackHistory);
        recommendation.priority = (recommendation.priority * historicalRating).round();
        
        // Ajustar confianza basada en personalización
        final personalizationFactor = weights[recommendation.type.name] ?? 1.0;
        recommendation.confidence = (recommendation.confidence * personalizationFactor).clamp(0.0, 1.0);
      }
      
      return recommendations;
    } catch (e) {
      LoggingService.error('Error aplicando personalización: $e');
      return recommendations;
    }
  }

  /// Genera insights básicos
  Future<MLInsights> _generateBasicInsights(
    List<Producto> productos,
    List<Venta> ventas,
    List<Cliente> clientes,
  ) async {
    final insights = <String>[];
    final metrics = <String, dynamic>{};
    
    // Insights de productos
    final totalProducts = productos.length;
    final lowStockProducts = productos.where((p) => p.stock < 5).length;
    final highValueProducts = productos.where((p) => p.precioVenta > 100).length;
    
    insights.add('Tienes $totalProducts productos en tu inventario');
    if (lowStockProducts > 0) {
      insights.add('$lowStockProducts productos tienen stock bajo (< 5 unidades)');
    }
    if (highValueProducts > 0) {
      insights.add('$highValueProducts productos de alto valor (> \$100)');
    }
    
    // Insights de ventas
    final totalSales = ventas.length;
    final totalRevenue = ventas.fold(0.0, (sum, v) => sum + v.total);
    final avgOrderValue = totalSales > 0 ? totalRevenue / totalSales : 0.0;
    
    insights.add('Total de ventas: $totalSales');
    insights.add('Ingresos totales: \$${totalRevenue.toStringAsFixed(2)}');
    insights.add('Valor promedio por orden: \$${avgOrderValue.toStringAsFixed(2)}');
    
    // Insights de clientes
    final totalCustomers = clientes.length;
    final customersWithContact = clientes.where((c) => 
      c.telefono.isNotEmpty || c.email.isNotEmpty
    ).length;
    
    insights.add('Total de clientes: $totalCustomers');
    insights.add('Clientes con información de contacto: $customersWithContact');
    
    metrics['total_products'] = totalProducts;
    metrics['low_stock_products'] = lowStockProducts;
    metrics['high_value_products'] = highValueProducts;
    metrics['total_sales'] = totalSales;
    metrics['total_revenue'] = totalRevenue;
    metrics['avg_order_value'] = avgOrderValue;
    metrics['total_customers'] = totalCustomers;
    metrics['customers_with_contact'] = customersWithContact;
    
    return MLInsights(
      insights: insights,
      metrics: metrics,
      generatedAt: DateTime.now(),
      confidence: 0.9,
    );
  }

  /// Personaliza insights basado en preferencias del usuario
  Future<MLInsights> _personalizeInsights(MLInsights basicInsights, Map<String, dynamic> preferences) async {
    final personalizedInsights = <String>[];
    
    // Agregar insights personalizados basados en preferencias
    if (preferences['focus_on_inventory'] == true) {
      personalizedInsights.add('💡 Enfoque recomendado: Optimizar gestión de inventario');
    }
    
    if (preferences['focus_on_pricing'] == true) {
      personalizedInsights.add('💰 Enfoque recomendado: Análisis de precios dinámicos');
    }
    
    if (preferences['focus_on_customers'] == true) {
      personalizedInsights.add('👥 Enfoque recomendado: Segmentación de clientes');
    }
    
    // Combinar insights básicos y personalizados
    final allInsights = [...basicInsights.insights, ...personalizedInsights];
    
    return MLInsights(
      insights: allInsights,
      metrics: basicInsights.metrics,
      generatedAt: DateTime.now(),
      confidence: basicInsights.confidence,
    );
  }

  /// Guarda feedback localmente
  Future<void> _saveFeedbackLocally(MLFeedback feedback) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackHistory = await _getFeedbackHistory();
      
      feedbackHistory.add(feedback);
      
      // Mantener solo los últimos 100 feedbacks
      if (feedbackHistory.length > 100) {
        feedbackHistory.removeRange(0, feedbackHistory.length - 100);
      }
      
      final feedbackJson = feedbackHistory.map((f) => f.toJson()).toList();
      await prefs.setString(_feedbackHistoryKey, jsonEncode(feedbackJson));
    } catch (e) {
      LoggingService.error('Error guardando feedback localmente: $e');
    }
  }

  /// Actualiza pesos de personalización basado en feedback
  Future<void> _updatePersonalizationWeights(MLFeedback feedback) async {
    try {
      final weights = await _getPersonalizationWeights();
      final typeKey = feedback.feedbackType.name;
      
      // Ajustar peso basado en rating (1-5)
      final adjustmentFactor = (feedback.rating - 3) / 2; // -1 a +1
      final currentWeight = weights[typeKey] ?? 1.0;
      final newWeight = (currentWeight + adjustmentFactor * 0.1).clamp(0.5, 2.0);
      
      weights[typeKey] = newWeight;
      
      // Guardar pesos actualizados
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_personalizationWeightsKey, jsonEncode(weights));
    } catch (e) {
      LoggingService.error('Error actualizando pesos de personalización: $e');
    }
  }

  /// Guarda feedback en Supabase
  Future<void> _saveFeedbackToSupabase(MLFeedback feedback) async {
    try {
      // Implementar cuando tengamos la tabla de feedback en Supabase
      LoggingService.info('Feedback guardado en Supabase (implementar tabla)');
    } catch (e) {
      LoggingService.error('Error guardando feedback en Supabase: $e');
    }
  }

  /// Obtiene preferencias del usuario
  Future<Map<String, dynamic>> _getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_userPreferencesKey);
      
      if (preferencesJson != null) {
        return Map<String, dynamic>.from(jsonDecode(preferencesJson));
      }
      
      // Preferencias por defecto
      return {
        'focus_on_inventory': true,
        'focus_on_pricing': true,
        'focus_on_customers': true,
        'notification_frequency': 'daily',
        'recommendation_limit': 5,
      };
    } catch (e) {
      LoggingService.error('Error obteniendo preferencias del usuario: $e');
      return {};
    }
  }

  /// Obtiene historial de feedback
  Future<List<MLFeedback>> _getFeedbackHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackJson = prefs.getString(_feedbackHistoryKey);
      
      if (feedbackJson != null) {
        final feedbackList = jsonDecode(feedbackJson) as List;
        return feedbackList.map((json) => MLFeedback.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      LoggingService.error('Error obteniendo historial de feedback: $e');
      return [];
    }
  }

  /// Obtiene pesos de personalización
  Future<Map<String, double>> _getPersonalizationWeights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final weightsJson = prefs.getString(_personalizationWeightsKey);
      
      if (weightsJson != null) {
        final weightsMap = jsonDecode(weightsJson) as Map<String, dynamic>;
        return weightsMap.map((key, value) => MapEntry(key, value as double));
      }
      
      // Pesos por defecto
      return {
        'demand': 1.0,
        'pricing': 1.0,
        'customer': 1.0,
      };
    } catch (e) {
      LoggingService.error('Error obteniendo pesos de personalización: $e');
      return {};
    }
  }

  /// Calcula rating histórico para un tipo de recomendación
  double _getHistoricalRating(RecommendationType type, List<MLFeedback> feedbackHistory) {
    final relevantFeedback = feedbackHistory.where((f) => f.feedbackType == type).toList();
    
    if (relevantFeedback.isEmpty) return 1.0;
    
    final avgRating = relevantFeedback.fold(0.0, (sum, f) => sum + f.rating) / relevantFeedback.length;
    return (avgRating / 5.0).clamp(0.5, 2.0); // Normalizar a 0.5-2.0
  }

  /// Calcula promedio de rating
  double _calculateAverageRating(List<MLFeedback> feedbackHistory) {
    if (feedbackHistory.isEmpty) return 0.0;
    
    return feedbackHistory.fold(0.0, (sum, f) => sum + f.rating) / feedbackHistory.length;
  }

  /// Calcula score de personalización
  double _calculatePersonalizationScore(Map<String, double> weights) {
    if (weights.isEmpty) return 0.0;
    
    final totalWeight = weights.values.fold(0.0, (sum, weight) => sum + weight);
    final avgWeight = totalWeight / weights.length;
    
    return (avgWeight - 0.5) / 1.5; // Normalizar a 0-1
  }

  // ==================== MÉTODOS DE GENERACIÓN DE CONTENIDO ====================

  String _generateDemandTitle(Producto producto, MLDemandPrediction prediction) {
    if (prediction.predictedDemand > producto.stock * 1.5) {
      return 'Aumentar stock de ${producto.nombre}';
    } else if (prediction.predictedDemand < producto.stock * 0.5) {
      return 'Reducir stock de ${producto.nombre}';
    } else {
      return 'Optimizar ${producto.nombre}';
    }
  }

  String _generatePriceTitle(Producto producto, MLPricePrediction prediction) {
    final diff = prediction.optimalPrice - prediction.currentPrice;
    if (diff > 0) {
      return 'Aumentar precio de ${producto.nombre}';
    } else {
      return 'Reducir precio de ${producto.nombre}';
    }
  }

  String _generateCustomerTitle(CustomerSegment segment) {
    return 'Estrategia para ${segment.name}';
  }

  String _generateCustomerDescription(CustomerSegment segment) {
    return 'Desarrollar estrategias específicas para el ${segment.name} (${segment.percentage.toStringAsFixed(1)}% de clientes)';
  }

  int _calculateDemandPriority(MLDemandPrediction prediction) {
    return (prediction.confidence * 100).round();
  }

  int _calculatePricePriority(MLPricePrediction prediction, double percentDiff) {
    return ((prediction.confidence * percentDiff) / 10).round();
  }

  int _calculateCustomerPriority(CustomerSegment segment) {
    return (segment.percentage * 2).round();
  }

  String _determineDemandAction(MLDemandPrediction prediction, Producto producto) {
    if (prediction.predictedDemand > producto.stock * 1.5) {
      return 'Aumentar stock urgentemente';
    } else if (prediction.predictedDemand < producto.stock * 0.5) {
      return 'Considerar promociones';
    } else {
      return 'Monitorear tendencias';
    }
  }

  String _determinePriceAction(MLPricePrediction prediction) {
    final diff = prediction.optimalPrice - prediction.currentPrice;
    if (diff > 0) {
      return 'Aumentar precio gradualmente';
    } else {
      return 'Reducir precio para estimular demanda';
    }
  }

  String _determineCustomerAction(CustomerSegment segment) {
    if (segment.name.contains('VIP')) {
      return 'Programa de fidelización exclusivo';
    } else if (segment.name.contains('Inactivos')) {
      return 'Campaña de reenganche';
    } else {
      return 'Estrategia personalizada';
    }
  }
}

// ==================== MODELOS DE DATOS ====================

/// Tipo de recomendación
enum RecommendationType {
  demand,
  pricing,
  customer,
}

/// Tipo de feedback
enum FeedbackType {
  demand,
  pricing,
  customer,
}

/// Recomendación ML personalizada
class MLRecommendation {
  final String id;
  final RecommendationType type;
  final String title;
  final String description;
  int priority;
  double confidence;
  final List<String> factors;
  final String actionRequired;
  final DateTime createdAt;

  MLRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.confidence,
    required this.factors,
    required this.actionRequired,
    required this.createdAt,
  });
}

/// Feedback del usuario
class MLFeedback {
  final String recommendationId;
  final FeedbackType feedbackType;
  final double rating;
  final String? comment;
  final DateTime timestamp;
  final String? userId;

  MLFeedback({
    required this.recommendationId,
    required this.feedbackType,
    required this.rating,
    this.comment,
    required this.timestamp,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'feedbackType': feedbackType.name,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
    };
  }

  factory MLFeedback.fromJson(Map<String, dynamic> json) {
    return MLFeedback(
      recommendationId: json['recommendationId'],
      feedbackType: FeedbackType.values.firstWhere(
        (e) => e.name == json['feedbackType'],
      ),
      rating: json['rating'].toDouble(),
      comment: json['comment'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
    );
  }
}

/// Insights ML personalizados
class MLInsights {
  final List<String> insights;
  final Map<String, dynamic> metrics;
  final DateTime generatedAt;
  final double confidence;

  MLInsights({
    required this.insights,
    required this.metrics,
    required this.generatedAt,
    required this.confidence,
  });

  factory MLInsights.empty() {
    return MLInsights(
      insights: ['Sin datos suficientes para generar insights'],
      metrics: {},
      generatedAt: DateTime.now(),
      confidence: 0.0,
    );
  }
}
