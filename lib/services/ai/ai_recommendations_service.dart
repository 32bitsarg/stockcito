import 'package:stockcito/services/ml/ml_persistence_service.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio de recomendaciones de IA basado en datos reales
class AIRecommendationsService {
  static final AIRecommendationsService _instance = AIRecommendationsService._internal();
  factory AIRecommendationsService() => _instance;
  AIRecommendationsService._internal();

  final MLPersistenceService _mlPersistenceService = MLPersistenceService();

  /// Genera recomendaciones automáticas basadas en datos históricos
  Future<List<Map<String, dynamic>>> generateRecommendations() async {
    try {
      print('🤖 DEBUG: Generando recomendaciones de IA...');
      
      // Cargar datos de entrenamiento
      final trainingData = await _mlPersistenceService.loadTrainingData(limit: 100);
      
      if (trainingData.isEmpty) {
        print('⚠️ DEBUG: No hay datos de entrenamiento para generar recomendaciones');
        return _getDefaultRecommendations();
      }

      // Analizar patrones en los datos
      final recommendations = <Map<String, dynamic>>[];
      
      // 1. Análisis de precios
      final priceAnalysis = _analyzePricingPatterns(trainingData);
      if (priceAnalysis != null) {
        recommendations.add(priceAnalysis);
      }

      // 2. Análisis de stock
      final stockAnalysis = _analyzeStockPatterns(trainingData);
      if (stockAnalysis != null) {
        recommendations.add(stockAnalysis);
      }

      // 3. Análisis de rentabilidad
      final profitabilityAnalysis = _analyzeProfitabilityPatterns(trainingData);
      if (profitabilityAnalysis != null) {
        recommendations.add(profitabilityAnalysis);
      }

      // 4. Análisis de tendencias
      final trendAnalysis = _analyzeTrends(trainingData);
      if (trendAnalysis != null) {
        recommendations.add(trendAnalysis);
      }

      print('✅ DEBUG: Generadas ${recommendations.length} recomendaciones');
      return recommendations;
    } catch (e) {
      print('❌ DEBUG: Error generando recomendaciones: $e');
      LoggingService.error('Error generando recomendaciones: $e');
      return _getDefaultRecommendations();
    }
  }

  /// Analiza patrones de precios en los datos
  Map<String, dynamic>? _analyzePricingPatterns(List<Map<String, dynamic>> data) {
    if (data.length < 3) return null;

    // Calcular estadísticas de precios
    final prices = data.map((d) => (d['target'] ?? 0.0).toDouble()).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    // Generar recomendación basada en patrones
    if (avgPrice > 100) {
      return {
        'type': 'pricing',
        'title': '💡 Optimización de Precios',
        'message': 'Tus productos tienen un precio promedio alto (\$${avgPrice.toStringAsFixed(0)}). Considera ajustar precios para aumentar ventas.',
        'priority': 'medium',
        'action': 'Revisar estrategia de precios',
        'timestamp': DateTime.now(),
      };
    }

    return null;
  }

  /// Analiza patrones de stock en los datos
  Map<String, dynamic>? _analyzeStockPatterns(List<Map<String, dynamic>> data) {
    if (data.length < 3) return null;

    // Analizar características de stock (asumiendo que el índice 4 es stock)
    final stockValues = data.where((d) => ((d['features'] as List?)?.length ?? 0) > 4).map((d) => (d['features'] as List)[4]).toList();
    
    if (stockValues.isEmpty) return null;

    final lowStockItems = stockValues.where((s) => s < 5).length;

    if (lowStockItems > 0) {
      return {
        'type': 'stock',
        'title': '📦 Gestión de Stock',
        'message': 'Tienes $lowStockItems productos con stock bajo. Considera reabastecer para evitar desabastecimiento.',
        'priority': 'high',
        'action': 'Revisar inventario',
        'timestamp': DateTime.now(),
      };
    }

    return null;
  }

  /// Analiza patrones de rentabilidad
  Map<String, dynamic>? _analyzeProfitabilityPatterns(List<Map<String, dynamic>> data) {
    if (data.length < 3) return null;

    // Analizar margen de ganancia (asumiendo que el índice 3 es margen)
    final margins = data.where((d) => ((d['features'] as List?)?.length ?? 0) > 3).map((d) => (d['features'] as List)[3]).toList();
    
    if (margins.isEmpty) return null;

    final avgMargin = margins.reduce((a, b) => a + b) / margins.length;

    if (avgMargin < 0.3) {
      return {
        'type': 'profitability',
        'title': '💰 Rentabilidad',
        'message': 'Tu margen promedio es del ${(avgMargin * 100).toStringAsFixed(1)}%. Considera aumentar precios o reducir costos.',
        'priority': 'medium',
        'action': 'Optimizar rentabilidad',
        'timestamp': DateTime.now(),
      };
    }

    return null;
  }

  /// Analiza tendencias en los datos
  Map<String, dynamic>? _analyzeTrends(List<Map<String, dynamic>> data) {
    if (data.length < 5) return null;

    // Analizar tendencia temporal
    final sortedData = List<Map<String, dynamic>>.from(data);
    sortedData.sort((a, b) => (a['timestamp'] ?? '').compareTo(b['timestamp'] ?? ''));

    final recentData = sortedData.take(3).map((d) => (d['target'] ?? 0.0).toDouble()).toList();
    final olderData = sortedData.skip(sortedData.length - 3).map((d) => (d['target'] ?? 0.0).toDouble()).toList();

    if (recentData.length < 3 || olderData.length < 3) return null;

    final recentAvg = recentData.reduce((a, b) => a + b) / recentData.length;
    final olderAvg = olderData.reduce((a, b) => a + b) / olderData.length;

    final trend = (recentAvg - olderAvg) / olderAvg;

    if (trend > 0.1) {
      return {
        'type': 'trend',
        'title': '📈 Tendencia Positiva',
        'message': 'Tus precios han aumentado un ${(trend * 100).toStringAsFixed(1)}% recientemente. ¡Excelente tendencia!',
        'priority': 'low',
        'action': 'Mantener estrategia',
        'timestamp': DateTime.now(),
      };
    } else if (trend < -0.1) {
      return {
        'type': 'trend',
        'title': '📉 Tendencia Negativa',
        'message': 'Tus precios han disminuido un ${(trend.abs() * 100).toStringAsFixed(1)}% recientemente. Revisa tu estrategia.',
        'priority': 'high',
        'action': 'Revisar precios',
        'timestamp': DateTime.now(),
      };
    }

    return null;
  }

  /// Recomendaciones por defecto cuando no hay suficientes datos
  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'type': 'welcome',
        'title': '👋 ¡Bienvenido a la IA!',
        'message': 'A medida que uses la app, la IA aprenderá de tus datos y te dará recomendaciones personalizadas.',
        'priority': 'low',
        'action': 'Seguir usando la app',
        'timestamp': DateTime.now(),
      },
      {
        'type': 'data',
        'title': '📊 Más Datos = Mejores Recomendaciones',
        'message': 'Crea más productos y ventas para que la IA pueda darte recomendaciones más precisas.',
        'priority': 'medium',
        'action': 'Agregar más datos',
        'timestamp': DateTime.now(),
      },
    ];
  }
}
