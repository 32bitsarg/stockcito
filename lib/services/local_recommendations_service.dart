import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ricitosdebb/models/ai_recommendation.dart';
import 'datos/datos.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/services/ai_cache_service.dart';

/// Servicio para gestionar recomendaciones de IA localmente
class LocalRecommendationsService {
  static final LocalRecommendationsService _instance = LocalRecommendationsService._internal();
  factory LocalRecommendationsService() => _instance;
  LocalRecommendationsService._internal();

  final DatosService _datosService = DatosService();
  final AICacheService _cacheService = AICacheService();
  static const String _recommendationsKey = 'ai_recommendations';
  static const int _maxRecommendations = 4; // Máximo 4 recomendaciones
  static const Duration _refreshInterval = Duration(minutes: 30); // 30 minutos para producción

  List<AIRecommendation> _recommendations = [];
  DateTime? _lastGeneration;
  Timer? _refreshTimer;

  /// Inicializa el servicio
  Future<void> initialize() async {
    try {
      print('🔧 DEBUG: Inicializando LocalRecommendationsService...');
      await _cacheService.initialize();
      await _loadRecommendations();
      _startPeriodicRefresh();
      print('✅ DEBUG: LocalRecommendationsService inicializado correctamente');
      LoggingService.info('LocalRecommendationsService inicializado');
    } catch (e) {
      print('❌ DEBUG: Error inicializando LocalRecommendationsService: $e');
      LoggingService.error('Error inicializando LocalRecommendationsService: $e');
    }
  }

  /// Carga recomendaciones desde SharedPreferences
  Future<void> _loadRecommendations() async {
    try {
      print('🔍 DEBUG: Cargando recomendaciones desde SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final String? recommendationsJson = prefs.getString(_recommendationsKey);
      
      if (recommendationsJson != null) {
        final List<dynamic> recommendationsList = json.decode(recommendationsJson);
        _recommendations = recommendationsList
            .map((json) => AIRecommendation.fromMap(json))
            .toList();
        
        // Filtrar recomendaciones descartadas y aplicadas (mantener solo las últimas 10)
        _recommendations = _recommendations
            .where((r) => r.status != RecommendationStatus.descartada || 
                         r.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .toList();
        
        // Ordenar por fecha de creación (más recientes primero)
        _recommendations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        print('✅ DEBUG: Cargadas ${_recommendations.length} recomendaciones locales');
        LoggingService.info('Cargadas ${_recommendations.length} recomendaciones locales');
      } else {
        print('📝 DEBUG: No hay recomendaciones guardadas, se generarán nuevas');
      }
    } catch (e) {
      print('❌ DEBUG: Error cargando recomendaciones: $e');
      LoggingService.error('Error cargando recomendaciones: $e');
      _recommendations = [];
    }
  }

  /// Guarda recomendaciones en SharedPreferences
  Future<void> _saveRecommendations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String recommendationsJson = json.encode(
        _recommendations.map((r) => r.toMap()).toList()
      );
      await prefs.setString(_recommendationsKey, recommendationsJson);
      LoggingService.info('Recomendaciones guardadas localmente');
    } catch (e) {
      LoggingService.error('Error guardando recomendaciones: $e');
    }
  }

  /// Inicia el refresco periódico
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (timer) {
      _generateNewRecommendations();
    });
  }

  /// Genera nuevas recomendaciones si es necesario
  Future<void> _generateNewRecommendations() async {
    try {
      // Verificar si el caché es válido
      if (_cacheService.isCacheValid) {
        print('🔍 DEBUG: Usando caché válido, no generando nuevas recomendaciones');
        return;
      }

      // Solo generar si no hay recomendaciones nuevas o han pasado más de 30 minutos
      final now = DateTime.now();
      if (_lastGeneration != null && 
          now.difference(_lastGeneration!) < _refreshInterval) {
        return;
      }

      // Verificar si necesitamos generar nuevas recomendaciones
      final activeRecommendations = _recommendations
          .where((r) => r.status == RecommendationStatus.nueva || 
                       r.status == RecommendationStatus.vista)
          .length;

      if (activeRecommendations >= _maxRecommendations) {
        return; // Ya tenemos suficientes recomendaciones activas
      }

      // Generar nuevas recomendaciones
      final newRecommendations = await _analyzeDataAndGenerateRecommendations();
      
      if (newRecommendations.isNotEmpty) {
        // Filtrar recomendaciones duplicadas usando el caché
        final uniqueRecommendations = await _cacheService.addRecommendationsIfNew(newRecommendations);
        
        if (uniqueRecommendations.isNotEmpty) {
          _recommendations.addAll(uniqueRecommendations);
          _lastGeneration = now;
          
          // Mantener solo las últimas 20 recomendaciones
          if (_recommendations.length > 20) {
            _recommendations = _recommendations
                .take(20)
                .toList();
          }
          
          await _saveRecommendations();
          LoggingService.info('Generadas ${uniqueRecommendations.length} nuevas recomendaciones únicas');
        } else {
          LoggingService.info('Todas las recomendaciones generadas ya existen en caché');
        }
      }
    } catch (e) {
      LoggingService.error('Error generando nuevas recomendaciones: $e');
    }
  }

  /// Analiza datos y genera recomendaciones
  Future<List<AIRecommendation>> _analyzeDataAndGenerateRecommendations() async {
    try {
      final List<AIRecommendation> recommendations = [];
      
      // Obtener datos de productos y ventas
      final productos = await _datosService.getAllProductos();
      final ventas = await _datosService.getAllVentas();
      
      print('🔍 DEBUG: Productos encontrados: ${productos.length}');
      print('🔍 DEBUG: Ventas encontradas: ${ventas.length}');
      
      if (productos.isEmpty) {
        print('⚠️ DEBUG: No hay productos para generar recomendaciones');
        return recommendations;
      }

      // Análisis de stock bajo
      final stockRecommendation = _analyzeStockLevels(productos);
      if (stockRecommendation != null) {
        recommendations.add(stockRecommendation);
      }

      // Análisis de precios
      final pricingRecommendation = _analyzePricing(productos);
      if (pricingRecommendation != null) {
        recommendations.add(pricingRecommendation);
      }

      // Análisis de rentabilidad
      final profitabilityRecommendation = _analyzeProfitability(productos);
      if (profitabilityRecommendation != null) {
        recommendations.add(profitabilityRecommendation);
      }

      // Análisis de tendencias de ventas
      final trendRecommendation = _analyzeSalesTrends(ventas, productos);
      if (trendRecommendation != null) {
        recommendations.add(trendRecommendation);
      }

      // Limitar a máximo 4 recomendaciones
      final finalRecommendations = recommendations.take(_maxRecommendations).toList();
      print('✅ DEBUG: Generadas ${finalRecommendations.length} recomendaciones');
      return finalRecommendations;
    } catch (e) {
      print('❌ DEBUG: Error analizando datos para recomendaciones: $e');
      LoggingService.error('Error analizando datos para recomendaciones: $e');
      return [];
    }
  }

  /// Analiza niveles de stock
  AIRecommendation? _analyzeStockLevels(List<dynamic> productos) {
    try {
      final lowStockProducts = productos.where((p) => p.stock < 5).toList();
      
      if (lowStockProducts.isEmpty) return null;

      final product = lowStockProducts.first;
      return AIRecommendation(
        id: 'stock_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Stock Bajo Detectado',
        message: '${product.nombre} tiene solo ${product.stock} unidades en stock. Considera reponer inventario.',
        action: 'Revisar inventario y realizar pedido de reposición',
        priority: product.stock <= 2 ? RecommendationPriority.alta : RecommendationPriority.media,
        category: 'stock',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Error analizando stock: $e');
      return null;
    }
  }

  /// Analiza precios
  AIRecommendation? _analyzePricing(List<dynamic> productos) {
    try {
      if (productos.length < 3) return null;

      // Calcular precio promedio
      final avgPrice = productos.map((p) => p.precioVenta).reduce((a, b) => a + b) / productos.length;
      
      // Buscar productos con precios muy altos o muy bajos
      final extremePriceProducts = productos.where((p) => 
        p.precioVenta > avgPrice * 1.5 || p.precioVenta < avgPrice * 0.5
      ).toList();

      if (extremePriceProducts.isEmpty) return null;

      final product = extremePriceProducts.first;
      final isHigh = product.precioVenta > avgPrice * 1.5;
      
      return AIRecommendation(
        id: 'pricing_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: isHigh ? 'Precio Alto Detectado' : 'Precio Bajo Detectado',
        message: '${product.nombre} tiene un precio ${isHigh ? 'muy alto' : 'muy bajo'} (${product.precioVenta.toStringAsFixed(2)}). El promedio es ${avgPrice.toStringAsFixed(2)}.',
        action: isHigh ? 'Revisar si el precio es competitivo' : 'Verificar que el margen de ganancia sea adecuado',
        priority: RecommendationPriority.media,
        category: 'pricing',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Error analizando precios: $e');
      return null;
    }
  }

  /// Analiza rentabilidad
  AIRecommendation? _analyzeProfitability(List<dynamic> productos) {
    try {
      final lowMarginProducts = productos.where((p) {
        final margin = (p.precioVenta - p.costoMateriales - p.costoManoObra - p.gastosGenerales) / p.precioVenta;
        return margin < 0.1; // Menos del 10% de margen
      }).toList();

      if (lowMarginProducts.isEmpty) return null;

      final product = lowMarginProducts.first;
      final margin = (product.precioVenta - product.costoMateriales - product.costoManoObra - product.gastosGenerales) / product.precioVenta;
      
      return AIRecommendation(
        id: 'profitability_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Baja Rentabilidad Detectada',
        message: '${product.nombre} tiene un margen de ganancia del ${(margin * 100).toStringAsFixed(1)}%. Considera ajustar precios o costos.',
        action: 'Revisar costos y ajustar precio de venta para mejorar rentabilidad',
        priority: RecommendationPriority.alta,
        category: 'profitability',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Error analizando rentabilidad: $e');
      return null;
    }
  }

  /// Analiza tendencias de ventas
  AIRecommendation? _analyzeSalesTrends(List<dynamic> ventas, List<dynamic> productos) {
    try {
      if (ventas.length < 5) return null;

      // Agrupar ventas por día de la semana
      final Map<int, List<dynamic>> salesByWeekday = {};
      for (final venta in ventas) {
        final weekday = venta.fecha.weekday;
        salesByWeekday[weekday] ??= [];
        salesByWeekday[weekday]!.add(venta);
      }

      // Encontrar el día con más ventas
      int bestDay = 0;
      int maxSales = 0;
      salesByWeekday.forEach((day, sales) {
        if (sales.length > maxSales) {
          maxSales = sales.length;
          bestDay = day;
        }
      });

      final dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      
      return AIRecommendation(
        id: 'trend_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Tendencia de Ventas Detectada',
        message: 'Los ${dayNames[bestDay - 1]} son tus mejores días de ventas (${maxSales} ventas). Considera promociones especiales.',
        action: 'Planificar promociones y marketing para los días de mayor actividad',
        priority: RecommendationPriority.baja,
        category: 'trend',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Error analizando tendencias: $e');
      return null;
    }
  }

  /// Obtiene todas las recomendaciones
  List<AIRecommendation> getRecommendations() {
    return List.from(_recommendations);
  }

  /// Obtiene recomendaciones activas (nuevas y vistas)
  List<AIRecommendation> getActiveRecommendations() {
    return _recommendations
        .where((r) => r.status == RecommendationStatus.nueva || 
                     r.status == RecommendationStatus.vista)
        .toList();
  }

  /// Marca una recomendación como vista
  Future<void> markAsViewed(String recommendationId) async {
    try {
      final index = _recommendations.indexWhere((r) => r.id == recommendationId);
      if (index != -1) {
        _recommendations[index] = _recommendations[index].copyWith(
          status: RecommendationStatus.vista,
          viewedAt: DateTime.now(),
        );
        await _saveRecommendations();
        // Actualizar también en el caché
        await _cacheService.updateRecommendationStatus(recommendationId, RecommendationStatus.vista);
        LoggingService.info('Recomendación marcada como vista: $recommendationId');
      }
    } catch (e) {
      LoggingService.error('Error marcando recomendación como vista: $e');
    }
  }

  /// Marca una recomendación como aplicada
  Future<void> markAsApplied(String recommendationId) async {
    try {
      final index = _recommendations.indexWhere((r) => r.id == recommendationId);
      if (index != -1) {
        _recommendations[index] = _recommendations[index].copyWith(
          status: RecommendationStatus.aplicada,
          appliedAt: DateTime.now(),
        );
        await _saveRecommendations();
        // Actualizar también en el caché
        await _cacheService.updateRecommendationStatus(recommendationId, RecommendationStatus.aplicada);
        LoggingService.info('Recomendación marcada como aplicada: $recommendationId');
      }
    } catch (e) {
      LoggingService.error('Error marcando recomendación como aplicada: $e');
    }
  }

  /// Marca una recomendación como descartada
  Future<void> markAsDiscarded(String recommendationId) async {
    try {
      final index = _recommendations.indexWhere((r) => r.id == recommendationId);
      if (index != -1) {
        _recommendations[index] = _recommendations[index].copyWith(
          status: RecommendationStatus.descartada,
          discardedAt: DateTime.now(),
        );
        await _saveRecommendations();
        // Actualizar también en el caché
        await _cacheService.updateRecommendationStatus(recommendationId, RecommendationStatus.descartada);
        LoggingService.info('Recomendación marcada como descartada: $recommendationId');
      }
    } catch (e) {
      LoggingService.error('Error marcando recomendación como descartada: $e');
    }
  }

  /// Elimina una recomendación
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      _recommendations.removeWhere((r) => r.id == recommendationId);
      await _saveRecommendations();
      LoggingService.info('Recomendación eliminada: $recommendationId');
    } catch (e) {
      LoggingService.error('Error eliminando recomendación: $e');
    }
  }

  /// Obtiene estadísticas de recomendaciones
  Map<String, dynamic> getStats() {
    final total = _recommendations.length;
    final nuevas = _recommendations.where((r) => r.status == RecommendationStatus.nueva).length;
    final vistas = _recommendations.where((r) => r.status == RecommendationStatus.vista).length;
    final aplicadas = _recommendations.where((r) => r.status == RecommendationStatus.aplicada).length;
    final descartadas = _recommendations.where((r) => r.status == RecommendationStatus.descartada).length;

    return {
      'total': total,
      'nuevas': nuevas,
      'vistas': vistas,
      'aplicadas': aplicadas,
      'descartadas': descartadas,
      'activas': nuevas + vistas,
    };
  }

  /// Limpia recomendaciones antiguas (más de 7 días)
  Future<void> cleanOldRecommendations() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      _recommendations.removeWhere((r) => 
        r.createdAt.isBefore(cutoffDate) && 
        (r.status == RecommendationStatus.descartada || r.status == RecommendationStatus.aplicada)
      );
      await _saveRecommendations();
      LoggingService.info('Recomendaciones antiguas limpiadas');
    } catch (e) {
      LoggingService.error('Error limpiando recomendaciones antiguas: $e');
    }
  }

  /// Dispone del servicio
  void dispose() {
    _refreshTimer?.cancel();
  }
}
