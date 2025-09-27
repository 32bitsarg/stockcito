import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../system/logging_service.dart';
import '../auth/supabase_auth_service.dart';
import 'personalization_service.dart';
import 'feedback_state_service.dart';

/// Servicio de feedback para capturar interacciones del usuario con recomendaciones ML
/// Implementa feedback loop para mejorar continuamente las recomendaciones
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  final PersonalizationService _personalizationService = PersonalizationService();
  final FeedbackStateService _feedbackStateService = FeedbackStateService();

  // Claves para almacenar feedback
  static const String _interactionHistoryKey = 'ml_interaction_history';
  static const String _abTestResultsKey = 'ml_ab_test_results';

  /// Registra una interacción del usuario con una recomendación
  Future<void> recordInteraction({
    required String recommendationId,
    required InteractionType interactionType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      LoggingService.info('📊 Registrando interacción: $interactionType para recomendación $recommendationId');
      
      final interaction = MLInteraction(
        recommendationId: recommendationId,
        interactionType: interactionType,
        timestamp: DateTime.now(),
        userId: _authService.currentUserId,
        metadata: metadata ?? {},
      );
      
      // Guardar interacción localmente
      await _saveInteractionLocally(interaction);
      
      // Si es usuario autenticado, enviar a Supabase
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _saveInteractionToSupabase(interaction);
      }
      
      // Actualizar análisis de comportamiento
      await _updateBehaviorAnalysis(interaction);
      
      LoggingService.info('✅ Interacción registrada correctamente');
      
    } catch (e) {
      LoggingService.error('❌ Error registrando interacción: $e');
    }
  }

  /// Registra feedback explícito del usuario
  Future<void> recordExplicitFeedback({
    required String recommendationId,
    required double rating, // 1-5
    required FeedbackType feedbackType,
    String? comment,
    bool? wasHelpful,
    bool? wasAccurate,
  }) async {
    try {
      LoggingService.info('⭐ Registrando feedback explícito: $rating estrellas para $recommendationId');
      
      // Registrar feedback en el servicio de personalización
      await _personalizationService.recordFeedback(
        recommendationId: recommendationId,
        feedbackType: feedbackType,
        rating: rating,
        comment: comment,
      );
      
      // Registrar interacción adicional
      await recordInteraction(
        recommendationId: recommendationId,
        interactionType: InteractionType.feedback_given,
        metadata: {
          'rating': rating,
          'comment': comment,
          'was_helpful': wasHelpful,
          'was_accurate': wasAccurate,
        },
      );
      
      LoggingService.info('✅ Feedback explícito registrado');
      
    } catch (e) {
      LoggingService.error('❌ Error registrando feedback explícito: $e');
    }
  }

  /// Verifica si el usuario ya dio feedback a una recomendación
  Future<bool> hasUserGivenFeedback(MLRecommendation recommendation) async {
    try {
      final recommendationId = _feedbackStateService.generateRecommendationId(recommendation);
      return await _feedbackStateService.hasUserGivenFeedback(recommendationId);
    } catch (e) {
      LoggingService.error('Error verificando feedback previo: $e');
      return false;
    }
  }

  /// Registra feedback único del usuario (like/dislike) con verificación de unicidad
  Future<bool> recordUniqueFeedback({
    required MLRecommendation recommendation,
    required bool isPositive,
  }) async {
    try {
      final recommendationId = _feedbackStateService.generateRecommendationId(recommendation);
      
      // Verificar si ya dio feedback
      final hasGivenFeedback = await _feedbackStateService.hasUserGivenFeedback(recommendationId);
      if (hasGivenFeedback) {
        LoggingService.info('Usuario ya dio feedback a esta recomendación: $recommendationId');
        return false;
      }

      // Registrar feedback en el estado
      await _feedbackStateService.recordFeedbackGiven(recommendationId, isPositive);

      // Registrar en el servicio de personalización
      await _personalizationService.recordFeedback(
        recommendationId: recommendationId,
        feedbackType: isPositive ? FeedbackType.demand : FeedbackType.demand, // Usar tipo por defecto
        rating: isPositive ? 5.0 : 1.0,
        comment: null,
      );

      // Registrar interacción adicional
      await recordInteraction(
        recommendationId: recommendationId,
        interactionType: InteractionType.feedback_given,
        metadata: {
          'feedback_type': isPositive ? 'positive' : 'negative',
          'recommendation_type': recommendation.type.name,
          'is_unique_feedback': true,
        },
      );

      LoggingService.info('✅ Feedback único registrado: $recommendationId (${isPositive ? 'positivo' : 'negativo'})');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error registrando feedback único: $e');
      return false;
    }
  }

  /// Permite deshacer el último feedback si está dentro de la ventana de tiempo
  Future<bool> undoLastFeedback() async {
    try {
      final success = await _feedbackStateService.undoLastFeedback();
      if (success) {
        LoggingService.info('✅ Último feedback deshecho correctamente');
      }
      return success;
    } catch (e) {
      LoggingService.error('❌ Error deshaciendo feedback: $e');
      return false;
    }
  }

  /// Verifica si hay un feedback pendiente de deshacer
  Future<bool> hasPendingUndo() async {
    try {
      return await _feedbackStateService.hasPendingUndo();
    } catch (e) {
      LoggingService.error('Error verificando feedback pendiente: $e');
      return false;
    }
  }

  /// Obtiene el tiempo restante para deshacer feedback
  Future<Duration?> getRemainingUndoTime() async {
    try {
      return await _feedbackStateService.getRemainingUndoTime();
    } catch (e) {
      LoggingService.error('Error obteniendo tiempo restante: $e');
      return null;
    }
  }

  /// Obtiene estadísticas del usuario sobre feedback
  Future<Map<String, dynamic>> getUserFeedbackStats() async {
    try {
      return await _feedbackStateService.getUserFeedbackStats();
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas: $e');
      return {
        'totalFeedback': 0,
        'positiveFeedback': 0,
        'negativeFeedback': 0,
        'lastFeedbackDate': null,
      };
    }
  }

  /// Registra resultado de A/B testing
  Future<void> recordABTestResult({
    required String testId,
    required String variant,
    required bool wasSuccessful,
    Map<String, dynamic>? metrics,
  }) async {
    try {
      LoggingService.info('🧪 Registrando resultado A/B test: $testId - $variant');
      
      final abTestResult = ABTestResult(
        testId: testId,
        variant: variant,
        wasSuccessful: wasSuccessful,
        timestamp: DateTime.now(),
        userId: _authService.currentUserId,
        metrics: metrics ?? {},
      );
      
      // Guardar resultado localmente
      await _saveABTestResultLocally(abTestResult);
      
      // Si es usuario autenticado, enviar a Supabase
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _saveABTestResultToSupabase(abTestResult);
      }
      
      LoggingService.info('✅ Resultado A/B test registrado');
      
    } catch (e) {
      LoggingService.error('❌ Error registrando resultado A/B test: $e');
    }
  }

  /// Obtiene estadísticas de feedback del usuario
  Future<Map<String, dynamic>> getFeedbackStats() async {
    try {
      final interactions = await _getInteractionHistory();
      final abTestResults = await _getABTestResults();
      
      // Calcular estadísticas de interacciones
      final totalInteractions = interactions.length;
      final clickThroughRate = _calculateClickThroughRate(interactions);
      final avgRating = _calculateAverageRating(interactions);
      final mostInteractedType = _getMostInteractedType(interactions);
      
      // Calcular estadísticas de A/B testing
      final totalABTests = abTestResults.length;
      final successRate = _calculateABTestSuccessRate(abTestResults);
      
      return {
        'total_interactions': totalInteractions,
        'click_through_rate': clickThroughRate,
        'average_rating': avgRating,
        'most_interacted_type': mostInteractedType,
        'total_ab_tests': totalABTests,
        'ab_test_success_rate': successRate,
        'last_interaction': interactions.isNotEmpty 
            ? interactions.last.timestamp.toIso8601String()
            : null,
        'feedback_quality_score': _calculateFeedbackQualityScore(interactions),
      };
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de feedback: $e');
      return {};
    }
  }

  /// Obtiene recomendaciones para mejorar el feedback
  Future<List<String>> getFeedbackImprovementRecommendations() async {
    try {
      final stats = await getFeedbackStats();
      final recommendations = <String>[];
      
      final clickThroughRate = stats['click_through_rate'] as double? ?? 0.0;
      final avgRating = stats['average_rating'] as double? ?? 0.0;
      final totalInteractions = stats['total_interactions'] as int? ?? 0;
      
      if (clickThroughRate < 0.3) {
        recommendations.add('Mejorar la relevancia de las recomendaciones (CTR bajo: ${(clickThroughRate * 100).toStringAsFixed(1)}%)');
      }
      
      if (avgRating < 3.0) {
        recommendations.add('Mejorar la precisión de las predicciones (Rating promedio: ${avgRating.toStringAsFixed(1)})');
      }
      
      if (totalInteractions < 10) {
        recommendations.add('Incentivar más interacciones con las recomendaciones');
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('El feedback del usuario es positivo. Continuar con la estrategia actual.');
      }
      
      return recommendations;
    } catch (e) {
      LoggingService.error('Error obteniendo recomendaciones de mejora: $e');
      return ['Error obteniendo recomendaciones'];
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Guarda interacción localmente
  Future<void> _saveInteractionLocally(MLInteraction interaction) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactionHistory = await _getInteractionHistory();
      
      interactionHistory.add(interaction);
      
      // Mantener solo los últimos 200 interacciones
      if (interactionHistory.length > 200) {
        interactionHistory.removeRange(0, interactionHistory.length - 200);
      }
      
      final interactionJson = interactionHistory.map((i) => i.toJson()).toList();
      await prefs.setString(_interactionHistoryKey, jsonEncode(interactionJson));
    } catch (e) {
      LoggingService.error('Error guardando interacción localmente: $e');
    }
  }

  /// Guarda resultado A/B test localmente
  Future<void> _saveABTestResultLocally(ABTestResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final abTestResults = await _getABTestResults();
      
      abTestResults.add(result);
      
      // Mantener solo los últimos 50 resultados
      if (abTestResults.length > 50) {
        abTestResults.removeRange(0, abTestResults.length - 50);
      }
      
      final abTestJson = abTestResults.map((r) => r.toJson()).toList();
      await prefs.setString(_abTestResultsKey, jsonEncode(abTestJson));
    } catch (e) {
      LoggingService.error('Error guardando resultado A/B test localmente: $e');
    }
  }

  /// Guarda interacción en Supabase
  Future<void> _saveInteractionToSupabase(MLInteraction interaction) async {
    try {
      // Implementar cuando tengamos la tabla de interacciones en Supabase
      LoggingService.info('Interacción guardada en Supabase (implementar tabla)');
    } catch (e) {
      LoggingService.error('Error guardando interacción en Supabase: $e');
    }
  }

  /// Guarda resultado A/B test en Supabase
  Future<void> _saveABTestResultToSupabase(ABTestResult result) async {
    try {
      // Implementar cuando tengamos la tabla de A/B tests en Supabase
      LoggingService.info('Resultado A/B test guardado en Supabase (implementar tabla)');
    } catch (e) {
      LoggingService.error('Error guardando resultado A/B test en Supabase: $e');
    }
  }

  /// Actualiza análisis de comportamiento
  Future<void> _updateBehaviorAnalysis(MLInteraction interaction) async {
    try {
      // Analizar patrones de comportamiento
      final interactionHistory = await _getInteractionHistory();
      
      // Detectar patrones de uso
      final recentInteractions = interactionHistory.where((i) => 
        DateTime.now().difference(i.timestamp).inDays < 7
      ).toList();
      
      if (recentInteractions.length > 10) {
        LoggingService.info('Usuario activo: ${recentInteractions.length} interacciones en la última semana');
      }
      
      // Detectar preferencias de tipo de recomendación
      final typePreferences = <InteractionType, int>{};
      for (final interaction in recentInteractions) {
        typePreferences[interaction.interactionType] = 
            (typePreferences[interaction.interactionType] ?? 0) + 1;
      }
      
      final mostPreferredType = typePreferences.entries.isNotEmpty
          ? typePreferences.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null;
      
      if (mostPreferredType != null) {
        LoggingService.info('Tipo de interacción preferido: ${mostPreferredType.name}');
      }
      
    } catch (e) {
      LoggingService.error('Error actualizando análisis de comportamiento: $e');
    }
  }

  /// Obtiene historial de interacciones
  Future<List<MLInteraction>> _getInteractionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final interactionJson = prefs.getString(_interactionHistoryKey);
      
      if (interactionJson != null) {
        final interactionList = jsonDecode(interactionJson) as List;
        return interactionList.map((json) => MLInteraction.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      LoggingService.error('Error obteniendo historial de interacciones: $e');
      return [];
    }
  }

  /// Obtiene resultados de A/B tests
  Future<List<ABTestResult>> _getABTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final abTestJson = prefs.getString(_abTestResultsKey);
      
      if (abTestJson != null) {
        final abTestList = jsonDecode(abTestJson) as List;
        return abTestList.map((json) => ABTestResult.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      LoggingService.error('Error obteniendo resultados de A/B tests: $e');
      return [];
    }
  }

  /// Calcula tasa de clics
  double _calculateClickThroughRate(List<MLInteraction> interactions) {
    if (interactions.isEmpty) return 0.0;
    
    final clicks = interactions.where((i) => i.interactionType == InteractionType.clicked).length;
    final views = interactions.where((i) => i.interactionType == InteractionType.viewed).length;
    
    return views > 0 ? clicks / views : 0.0;
  }

  /// Calcula rating promedio
  double _calculateAverageRating(List<MLInteraction> interactions) {
    final ratingInteractions = interactions.where((i) => 
      i.metadata.containsKey('rating')
    ).toList();
    
    if (ratingInteractions.isEmpty) return 0.0;
    
    final totalRating = ratingInteractions.fold(0.0, (sum, i) => 
      sum + (i.metadata['rating'] as num).toDouble()
    );
    
    return totalRating / ratingInteractions.length;
  }

  /// Obtiene tipo más interactuado
  String? _getMostInteractedType(List<MLInteraction> interactions) {
    if (interactions.isEmpty) return null;
    
    final typeCounts = <InteractionType, int>{};
    for (final interaction in interactions) {
      typeCounts[interaction.interactionType] = 
          (typeCounts[interaction.interactionType] ?? 0) + 1;
    }
    
    final mostInteracted = typeCounts.entries.isNotEmpty
        ? typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : null;
    
    return mostInteracted?.name;
  }

  /// Calcula tasa de éxito de A/B tests
  double _calculateABTestSuccessRate(List<ABTestResult> results) {
    if (results.isEmpty) return 0.0;
    
    final successfulTests = results.where((r) => r.wasSuccessful).length;
    return successfulTests / results.length;
  }

  /// Calcula score de calidad del feedback
  double _calculateFeedbackQualityScore(List<MLInteraction> interactions) {
    if (interactions.isEmpty) return 0.0;
    
    double score = 0.0;
    
    // Puntos por interacciones
    score += interactions.length * 0.1;
    
    // Puntos por ratings altos
    final ratingInteractions = interactions.where((i) => 
      i.metadata.containsKey('rating')
    ).toList();
    
    if (ratingInteractions.isNotEmpty) {
      final avgRating = _calculateAverageRating(ratingInteractions);
      score += avgRating * 2;
    }
    
    // Puntos por comentarios
    final commentInteractions = interactions.where((i) => 
      i.metadata.containsKey('comment') && 
      (i.metadata['comment'] as String).isNotEmpty
    ).length;
    
    score += commentInteractions * 5;
    
    return (score / 100).clamp(0.0, 1.0);
  }
}

// ==================== MODELOS DE DATOS ====================

/// Tipo de interacción del usuario
enum InteractionType {
  viewed,        // Usuario vio la recomendación
  clicked,        // Usuario hizo clic en la recomendación
  dismissed,      // Usuario descartó la recomendación
  feedback_given, // Usuario dio feedback explícito
  action_taken,   // Usuario tomó la acción recomendada
}

/// Interacción del usuario con recomendación ML
class MLInteraction {
  final String recommendationId;
  final InteractionType interactionType;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> metadata;

  MLInteraction({
    required this.recommendationId,
    required this.interactionType,
    required this.timestamp,
    this.userId,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'recommendationId': recommendationId,
      'interactionType': interactionType.name,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }

  factory MLInteraction.fromJson(Map<String, dynamic> json) {
    return MLInteraction(
      recommendationId: json['recommendationId'],
      interactionType: InteractionType.values.firstWhere(
        (e) => e.name == json['interactionType'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      metadata: Map<String, dynamic>.from(json['metadata']),
    );
  }
}

/// Resultado de A/B test
class ABTestResult {
  final String testId;
  final String variant;
  final bool wasSuccessful;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> metrics;

  ABTestResult({
    required this.testId,
    required this.variant,
    required this.wasSuccessful,
    required this.timestamp,
    this.userId,
    required this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'variant': variant,
      'wasSuccessful': wasSuccessful,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metrics': metrics,
    };
  }

  factory ABTestResult.fromJson(Map<String, dynamic> json) {
    return ABTestResult(
      testId: json['testId'],
      variant: json['variant'],
      wasSuccessful: json['wasSuccessful'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      metrics: Map<String, dynamic>.from(json['metrics']),
    );
  }
}
