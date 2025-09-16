import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockcito/models/ai_recommendation.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio de caché para recomendaciones de IA
class AICacheService {
  static final AICacheService _instance = AICacheService._internal();
  factory AICacheService() => _instance;
  AICacheService._internal();

  static const String _cacheKey = 'ai_recommendations_cache';
  static const String _lastUpdateKey = 'ai_cache_last_update';
  static const Duration _cacheExpiry = Duration(hours: 6); // Caché válido por 6 horas

  List<AIRecommendation> _cachedRecommendations = [];
  DateTime? _lastUpdate;

  /// Inicializa el servicio de caché
  Future<void> initialize() async {
    try {
      await _loadCache();
      LoggingService.info('AICacheService inicializado');
    } catch (e) {
      LoggingService.error('Error inicializando AICacheService: $e');
    }
  }

  /// Carga el caché desde SharedPreferences
  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cacheJson = prefs.getString(_cacheKey);
      final String? lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (cacheJson != null) {
        final List<dynamic> recommendationsList = json.decode(cacheJson);
        _cachedRecommendations = recommendationsList
            .map((json) => AIRecommendation.fromMap(json))
            .toList();
      }

      if (lastUpdateStr != null) {
        _lastUpdate = DateTime.parse(lastUpdateStr);
      }

      LoggingService.info('Caché cargado: ${_cachedRecommendations.length} recomendaciones');
    } catch (e) {
      LoggingService.error('Error cargando caché: $e');
      _cachedRecommendations = [];
      _lastUpdate = null;
    }
  }

  /// Guarda el caché en SharedPreferences
  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheJson = json.encode(
        _cachedRecommendations.map((r) => r.toMap()).toList()
      );
      await prefs.setString(_cacheKey, cacheJson);
      await prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      LoggingService.info('Caché guardado');
    } catch (e) {
      LoggingService.error('Error guardando caché: $e');
    }
  }

  /// Verifica si el caché es válido
  bool get isCacheValid {
    if (_lastUpdate == null) return false;
    return DateTime.now().difference(_lastUpdate!) < _cacheExpiry;
  }

  /// Obtiene las recomendaciones del caché
  List<AIRecommendation> getCachedRecommendations() {
    return List.from(_cachedRecommendations);
  }

  /// Verifica si una recomendación ya existe en el caché
  bool recommendationExists(AIRecommendation recommendation) {
    return _cachedRecommendations.any((cached) => 
      cached.title == recommendation.title && 
      cached.message == recommendation.message &&
      cached.action == recommendation.action
    );
  }

  /// Agrega una nueva recomendación al caché si no existe
  Future<bool> addRecommendationIfNew(AIRecommendation recommendation) async {
    if (recommendationExists(recommendation)) {
      LoggingService.info('Recomendación duplicada ignorada: ${recommendation.title}');
      return false;
    }

    _cachedRecommendations.add(recommendation);
    await _saveCache();
    LoggingService.info('Nueva recomendación agregada al caché: ${recommendation.title}');
    return true;
  }

  /// Agrega múltiples recomendaciones al caché, filtrando duplicados
  Future<List<AIRecommendation>> addRecommendationsIfNew(List<AIRecommendation> recommendations) async {
    final List<AIRecommendation> newRecommendations = [];
    
    for (final recommendation in recommendations) {
      if (!recommendationExists(recommendation)) {
        _cachedRecommendations.add(recommendation);
        newRecommendations.add(recommendation);
      }
    }

    if (newRecommendations.isNotEmpty) {
      await _saveCache();
      LoggingService.info('${newRecommendations.length} nuevas recomendaciones agregadas al caché');
    } else {
      LoggingService.info('No hay recomendaciones nuevas para agregar');
    }

    return newRecommendations;
  }

  /// Actualiza el estado de una recomendación
  Future<void> updateRecommendationStatus(String recommendationId, RecommendationStatus newStatus) async {
    final index = _cachedRecommendations.indexWhere((r) => r.id == recommendationId);
    if (index != -1) {
      _cachedRecommendations[index] = _cachedRecommendations[index].copyWith(status: newStatus);
      await _saveCache();
      LoggingService.info('Estado de recomendación actualizado: $recommendationId -> $newStatus');
    }
  }

  /// Obtiene recomendaciones por estado
  List<AIRecommendation> getRecommendationsByStatus(RecommendationStatus status) {
    return _cachedRecommendations.where((r) => r.status == status).toList();
  }

  /// Obtiene recomendaciones por prioridad
  List<AIRecommendation> getRecommendationsByPriority(RecommendationPriority priority) {
    return _cachedRecommendations.where((r) => r.priority == priority).toList();
  }

  /// Obtiene recomendaciones por categoría
  List<AIRecommendation> getRecommendationsByCategory(String category) {
    return _cachedRecommendations.where((r) => r.category == category).toList();
  }

  /// Limpia recomendaciones descartadas o aplicadas (más de 7 días)
  Future<void> cleanOldRecommendations() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final initialCount = _cachedRecommendations.length;
    
    _cachedRecommendations.removeWhere((r) => 
      (r.status == RecommendationStatus.descartada || r.status == RecommendationStatus.aplicada) &&
      r.createdAt.isBefore(cutoffDate)
    );

    final removedCount = initialCount - _cachedRecommendations.length;
    if (removedCount > 0) {
      await _saveCache();
      LoggingService.info('$removedCount recomendaciones antiguas eliminadas del caché');
    }
  }

  /// Limpia todo el caché
  Future<void> clearCache() async {
    _cachedRecommendations.clear();
    _lastUpdate = null;
    await _saveCache();
    LoggingService.info('Caché limpiado completamente');
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getCacheStats() {
    final total = _cachedRecommendations.length;
    final nuevas = _cachedRecommendations.where((r) => r.status == RecommendationStatus.nueva).length;
    final vistas = _cachedRecommendations.where((r) => r.status == RecommendationStatus.vista).length;
    final aplicadas = _cachedRecommendations.where((r) => r.status == RecommendationStatus.aplicada).length;
    final descartadas = _cachedRecommendations.where((r) => r.status == RecommendationStatus.descartada).length;

    return {
      'total': total,
      'nuevas': nuevas,
      'vistas': vistas,
      'aplicadas': aplicadas,
      'descartadas': descartadas,
      'lastUpdate': _lastUpdate?.toIso8601String(),
      'isValid': isCacheValid,
    };
  }

  /// Fuerza la actualización del caché
  Future<void> forceRefresh() async {
    _lastUpdate = null;
    await _loadCache();
    LoggingService.info('Caché forzado a refrescar');
  }

  /// Obtiene estadísticas del caché (alias para getCacheStats)
  Map<String, dynamic> get cacheStatsData => getCacheStats();

  /// Obtiene estadísticas del caché (alias para getCacheStats)
  Map<String, dynamic> getCachedStats() => getCacheStats();

  /// Invalida el caché (alias para clearCache)
  Future<void> invalidateCache() async {
    await clearCache();
    LoggingService.info('Caché invalidado');
  }

  /// Guarda estadísticas en el caché
  Future<void> cacheStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String statsJson = json.encode(stats);
      await prefs.setString('ai_cache_stats', statsJson);
      LoggingService.info('Estadísticas guardadas en caché');
    } catch (e) {
      LoggingService.error('Error guardando estadísticas en caché: $e');
    }
  }

  /// Obtiene estadísticas guardadas en el caché
  Future<Map<String, dynamic>?> getCachedStatsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? statsJson = prefs.getString('ai_cache_stats');
      if (statsJson != null) {
        return Map<String, dynamic>.from(json.decode(statsJson));
      }
      return null;
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas del caché: $e');
      return null;
    }
  }
}