import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../system/logging_service.dart';
import '../auth/supabase_auth_service.dart';
import 'personalization_service.dart';

/// Servicio para manejar el estado persistente del feedback de recomendaciones ML
/// Implementa feedback único por recomendación con deshacer en ventana de 30 segundos
class FeedbackStateService {
  static final FeedbackStateService _instance = FeedbackStateService._internal();
  factory FeedbackStateService() => _instance;
  FeedbackStateService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();

  // Claves para almacenamiento local
  static const String _feedbackHistoryKey = 'ml_feedback_history';
  static const String _pendingUndoKey = 'ml_pending_undo';
  static const String _userFeedbackStatsKey = 'ml_user_feedback_stats';

  // Ventana de tiempo para deshacer feedback (30 segundos)
  static const Duration _undoWindow = Duration(seconds: 30);

  /// Genera un ID único para una recomendación basado en su contenido y contexto
  String generateRecommendationId(MLRecommendation recommendation) {
    // Crear hash único basado en contenido, tipo y contexto
    final contentHash = recommendation.title.hashCode;
    final typeHash = recommendation.type.name.hashCode;
    final contextHash = recommendation.description.hashCode;
    
    // Incluir fecha para permitir recomendaciones similares en días diferentes
    final dateString = DateTime.now().toIso8601String().substring(0, 10);
    final dateHash = dateString.hashCode;
    
    // Combinar todos los hashes para crear ID único
    final combinedHash = contentHash ^ typeHash ^ contextHash ^ dateHash;
    
    return '${recommendation.type.name}_${combinedHash.abs()}_$dateString';
  }

  /// Verifica si el usuario ya dio feedback a una recomendación específica
  Future<bool> hasUserGivenFeedback(String recommendationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackHistory = prefs.getStringList(_feedbackHistoryKey) ?? [];
      
      // Verificar si el ID está en el historial
      return feedbackHistory.contains(recommendationId);
    } catch (e) {
      LoggingService.error('Error verificando feedback previo: $e');
      return false;
    }
  }

  /// Registra que el usuario dio feedback a una recomendación
  Future<void> recordFeedbackGiven(String recommendationId, bool isPositive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Agregar al historial local
      final feedbackHistory = prefs.getStringList(_feedbackHistoryKey) ?? [];
      if (!feedbackHistory.contains(recommendationId)) {
        feedbackHistory.add(recommendationId);
        await prefs.setStringList(_feedbackHistoryKey, feedbackHistory);
      }

      // Guardar feedback con timestamp para deshacer
      final feedbackData = {
        'recommendationId': recommendationId,
        'isPositive': isPositive,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'canUndo': true,
      };
      
      await prefs.setString(_pendingUndoKey, jsonEncode(feedbackData));

      // Actualizar estadísticas del usuario
      await _updateUserFeedbackStats(isPositive);

      // Si es usuario autenticado, sincronizar con Supabase
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _syncFeedbackToSupabase(recommendationId, isPositive);
      }

      LoggingService.info('✅ Feedback registrado: $recommendationId (${isPositive ? 'positivo' : 'negativo'})');
    } catch (e) {
      LoggingService.error('Error registrando feedback: $e');
    }
  }

  /// Permite deshacer el último feedback si está dentro de la ventana de 30 segundos
  Future<bool> undoLastFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUndoData = prefs.getString(_pendingUndoKey);
      
      if (pendingUndoData == null) {
        LoggingService.info('No hay feedback pendiente para deshacer');
        return false;
      }

      final feedbackData = jsonDecode(pendingUndoData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(feedbackData['timestamp']);
      final now = DateTime.now();
      
      // Verificar si está dentro de la ventana de 30 segundos
      if (now.difference(timestamp) > _undoWindow) {
        LoggingService.info('Ventana de deshacer expirada');
        await prefs.remove(_pendingUndoKey);
        return false;
      }

      // Remover del historial
      final feedbackHistory = prefs.getStringList(_feedbackHistoryKey) ?? [];
      final recommendationId = feedbackData['recommendationId'] as String;
      feedbackHistory.remove(recommendationId);
      await prefs.setStringList(_feedbackHistoryKey, feedbackHistory);

      // Limpiar datos de deshacer
      await prefs.remove(_pendingUndoKey);

      // Actualizar estadísticas
      final isPositive = feedbackData['isPositive'] as bool;
      await _updateUserFeedbackStats(!isPositive); // Invertir estadística

      // Si es usuario autenticado, sincronizar con Supabase
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _syncUndoToSupabase(recommendationId);
      }

      LoggingService.info('✅ Feedback deshecho: $recommendationId');
      return true;
    } catch (e) {
      LoggingService.error('Error deshaciendo feedback: $e');
      return false;
    }
  }

  /// Verifica si hay un feedback pendiente de deshacer
  Future<bool> hasPendingUndo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUndoData = prefs.getString(_pendingUndoKey);
      
      if (pendingUndoData == null) return false;

      final feedbackData = jsonDecode(pendingUndoData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(feedbackData['timestamp']);
      final now = DateTime.now();
      
      // Verificar si está dentro de la ventana de 30 segundos
      return now.difference(timestamp) <= _undoWindow;
    } catch (e) {
      LoggingService.error('Error verificando feedback pendiente: $e');
      return false;
    }
  }

  /// Obtiene el tiempo restante para deshacer feedback
  Future<Duration?> getRemainingUndoTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingUndoData = prefs.getString(_pendingUndoKey);
      
      if (pendingUndoData == null) return null;

      final feedbackData = jsonDecode(pendingUndoData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(feedbackData['timestamp']);
      final now = DateTime.now();
      final elapsed = now.difference(timestamp);
      
      if (elapsed > _undoWindow) return null;
      
      return _undoWindow - elapsed;
    } catch (e) {
      LoggingService.error('Error obteniendo tiempo restante: $e');
      return null;
    }
  }

  /// Obtiene estadísticas del usuario sobre feedback
  Future<Map<String, dynamic>> getUserFeedbackStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsData = prefs.getString(_userFeedbackStatsKey);
      
      if (statsData == null) {
        return {
          'totalFeedback': 0,
          'positiveFeedback': 0,
          'negativeFeedback': 0,
          'lastFeedbackDate': null,
        };
      }

      return jsonDecode(statsData) as Map<String, dynamic>;
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

  /// Limpia el historial de feedback (útil para testing o reset)
  Future<void> clearFeedbackHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_feedbackHistoryKey);
      await prefs.remove(_pendingUndoKey);
      await prefs.remove(_userFeedbackStatsKey);
      
      LoggingService.info('✅ Historial de feedback limpiado');
    } catch (e) {
      LoggingService.error('Error limpiando historial: $e');
    }
  }

  /// Actualiza las estadísticas del usuario
  Future<void> _updateUserFeedbackStats(bool isPositive) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsData = prefs.getString(_userFeedbackStatsKey);
      
      Map<String, dynamic> stats;
      if (statsData != null) {
        stats = jsonDecode(statsData) as Map<String, dynamic>;
      } else {
        stats = {
          'totalFeedback': 0,
          'positiveFeedback': 0,
          'negativeFeedback': 0,
          'lastFeedbackDate': null,
        };
      }

      stats['totalFeedback'] = (stats['totalFeedback'] as int) + 1;
      if (isPositive) {
        stats['positiveFeedback'] = (stats['positiveFeedback'] as int) + 1;
      } else {
        stats['negativeFeedback'] = (stats['negativeFeedback'] as int) + 1;
      }
      stats['lastFeedbackDate'] = DateTime.now().toIso8601String();

      await prefs.setString(_userFeedbackStatsKey, jsonEncode(stats));
    } catch (e) {
      LoggingService.error('Error actualizando estadísticas: $e');
    }
  }

  /// Sincroniza feedback con Supabase para usuarios autenticados
  Future<void> _syncFeedbackToSupabase(String recommendationId, bool isPositive) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        LoggingService.warning('⚠️ Usuario no autenticado, saltando sincronización');
        return;
      }
      
      LoggingService.info('🔄 Sincronizando feedback con Supabase: $recommendationId');
      
      await Supabase.instance.client
        .from('user_feedback_history')
        .insert({
          'user_id': userId,
          'recommendation_id': recommendationId,
          'feedback_type': isPositive ? 'positive' : 'negative',
          'timestamp': DateTime.now().toIso8601String(),
        });
        
      LoggingService.info('✅ Feedback sincronizado con Supabase exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando feedback con Supabase: $e');
      // No rethrow para evitar interrumpir el flujo local
    }
  }

  /// Sincroniza deshacer con Supabase para usuarios autenticados
  Future<void> _syncUndoToSupabase(String recommendationId) async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        LoggingService.warning('⚠️ Usuario no autenticado, saltando sincronización de deshacer');
        return;
      }
      
      LoggingService.info('🔄 Sincronizando deshacer con Supabase: $recommendationId');
      
      await Supabase.instance.client
        .from('user_feedback_history')
        .delete()
        .eq('user_id', userId)
        .eq('recommendation_id', recommendationId);
        
      LoggingService.info('✅ Deshacer sincronizado con Supabase exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando deshacer con Supabase: $e');
      // No rethrow para evitar interrumpir el flujo local
    }
  }
}
