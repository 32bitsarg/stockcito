import 'dart:math';
import 'package:ricitosdebb/models/producto.dart';
import 'package:ricitosdebb/models/venta.dart';
import 'datos.dart';
import 'package:ricitosdebb/services/system/logging_service.dart';

class DemandPredictionService {
  static final DemandPredictionService _instance = DemandPredictionService._internal();
  factory DemandPredictionService() => _instance;
  DemandPredictionService._internal();

  final DatosService _datosService = DatosService();

  /// Predice la demanda para un producto específico en los próximos días
  Future<DemandPrediction> predictDemandForProduct(int productoId, int daysAhead) async {
    try {
      LoggingService.info('Iniciando predicción de demanda para producto $productoId');
      
      // Obtener datos históricos de ventas del producto
      final ventas = await _getProductSalesHistory(productoId);
      
      if (ventas.isEmpty) {
        return DemandPrediction(
          productoId: productoId,
          predictedDemand: 0,
          confidence: 0.0,
          recommendation: 'Sin datos históricos suficientes',
          urgency: DemandUrgency.low,
        );
      }

      // Calcular patrones de demanda
      final patterns = _analyzeDemandPatterns(ventas);
      
      // Aplicar algoritmo de predicción
      final prediction = _calculateDemandPrediction(patterns, daysAhead);
      
      // Generar recomendación
      final recommendation = _generateStockRecommendation(prediction, patterns);
      
      LoggingService.info('Predicción completada: ${prediction.predictedDemand} unidades');
      
      return prediction.copyWith(recommendation: recommendation);
      
    } catch (e) {
      LoggingService.error('Error en predicción de demanda: $e');
      return DemandPrediction(
        productoId: productoId,
        predictedDemand: 0,
        confidence: 0.0,
        recommendation: 'Error en el análisis',
        urgency: DemandUrgency.low,
      );
    }
  }

  /// Predice la demanda para todos los productos
  Future<List<DemandPrediction>> predictDemandForAllProducts(int daysAhead) async {
    try {
      LoggingService.info('Iniciando predicción de demanda para todos los productos');
      
      final productos = await _datosService.getAllProductos();
      final predictions = <DemandPrediction>[];
      
      for (final producto in productos) {
        final prediction = await predictDemandForProduct(producto.id!, daysAhead);
        predictions.add(prediction);
      }
      
      // Ordenar por urgencia y demanda predicha
      predictions.sort((a, b) {
        if (a.urgency.index != b.urgency.index) {
          return b.urgency.index.compareTo(a.urgency.index);
        }
        return b.predictedDemand.compareTo(a.predictedDemand);
      });
      
      LoggingService.info('Predicción completada para ${predictions.length} productos');
      return predictions;
      
    } catch (e) {
      LoggingService.error('Error en predicción masiva: $e');
      return [];
    }
  }

  /// Obtiene recomendaciones de stock basadas en predicciones
  Future<List<StockRecommendation>> getStockRecommendations() async {
    try {
      LoggingService.info('Generando recomendaciones de stock');
      
      final predictions = await predictDemandForAllProducts(7); // Próximos 7 días
      final recommendations = <StockRecommendation>[];
      
      for (final prediction in predictions) {
        if (prediction.urgency != DemandUrgency.low && prediction.confidence > 0.6) {
          final productos = await _datosService.getAllProductos();
          final producto = productos.firstWhere(
            (p) => p.id == prediction.productoId,
            orElse: () => throw Exception('Producto no encontrado'),
          );
          try {
            final currentStock = producto.stock;
            final recommendedStock = _calculateRecommendedStock(
              currentStock, 
              prediction.predictedDemand, 
              prediction.urgency
            );
            
            if (recommendedStock > currentStock) {
              recommendations.add(StockRecommendation(
                producto: producto,
                currentStock: currentStock,
                recommendedStock: recommendedStock,
                predictedDemand: prediction.predictedDemand,
                urgency: prediction.urgency,
                reason: prediction.recommendation,
                confidence: prediction.confidence,
              ));
            }
          } catch (e) {
            // Producto no encontrado, continuar con el siguiente
            continue;
          }
        }
      }
      
      LoggingService.info('Generadas ${recommendations.length} recomendaciones');
      return recommendations;
      
    } catch (e) {
      LoggingService.error('Error generando recomendaciones: $e');
      return [];
    }
  }

  /// Obtiene el historial de ventas de un producto
  Future<List<Venta>> _getProductSalesHistory(int productoId) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final ventas = await _datosService.getVentasByDateRange(thirtyDaysAgo, now);
    
    // Filtrar ventas que contengan el producto
    return ventas.where((venta) {
      return venta.items.any((item) => item.productoId == productoId);
    }).toList();
  }

  /// Analiza patrones de demanda en las ventas
  DemandPatterns _analyzeDemandPatterns(List<Venta> ventas) {
    if (ventas.isEmpty) {
      return DemandPatterns(
        averageDailySales: 0.0,
        trend: DemandTrend.stable,
        seasonality: 0.0,
        volatility: 0.0,
      );
    }

    // Agrupar ventas por día
    final dailySales = <DateTime, int>{};
    for (final venta in ventas) {
      final date = DateTime(venta.fecha.year, venta.fecha.month, venta.fecha.day);
      dailySales[date] = (dailySales[date] ?? 0) + 1;
    }

    final salesValues = dailySales.values.toList();
    final averageDailySales = salesValues.reduce((a, b) => a + b) / salesValues.length;
    
    // Calcular tendencia
    final trend = _calculateTrend(salesValues);
    
    // Calcular estacionalidad (simplificado)
    final seasonality = _calculateSeasonality(ventas);
    
    // Calcular volatilidad
    final volatility = _calculateVolatility(salesValues, averageDailySales);

    return DemandPatterns(
      averageDailySales: averageDailySales,
      trend: trend,
      seasonality: seasonality,
      volatility: volatility,
    );
  }

  /// Calcula la tendencia de las ventas
  DemandTrend _calculateTrend(List<int> salesValues) {
    if (salesValues.length < 2) return DemandTrend.stable;
    
    final firstHalf = salesValues.take(salesValues.length ~/ 2).reduce((a, b) => a + b);
    final secondHalf = salesValues.skip(salesValues.length ~/ 2).reduce((a, b) => a + b);
    
    final firstHalfAvg = firstHalf / (salesValues.length ~/ 2);
    final secondHalfAvg = secondHalf / (salesValues.length - salesValues.length ~/ 2);
    
    final change = (secondHalfAvg - firstHalfAvg) / firstHalfAvg;
    
    if (change > 0.1) return DemandTrend.increasing;
    if (change < -0.1) return DemandTrend.decreasing;
    return DemandTrend.stable;
  }

  /// Calcula la estacionalidad (simplificado)
  double _calculateSeasonality(List<Venta> ventas) {
    // Agrupar por día de la semana
    final weeklyPattern = <int, int>{};
    for (final venta in ventas) {
      final weekday = venta.fecha.weekday;
      weeklyPattern[weekday] = (weeklyPattern[weekday] ?? 0) + 1;
    }
    
    if (weeklyPattern.isEmpty) return 0.0;
    
    final values = weeklyPattern.values.toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    
    return max > 0 ? (max - min) / max : 0.0;
  }

  /// Calcula la volatilidad de las ventas
  double _calculateVolatility(List<int> salesValues, double average) {
    if (salesValues.length < 2) return 0.0;
    
    final variance = salesValues
        .map((x) => pow(x - average, 2))
        .reduce((a, b) => a + b) / salesValues.length;
    
    return sqrt(variance) / average;
  }

  /// Calcula la predicción de demanda
  DemandPrediction _calculateDemandPrediction(DemandPatterns patterns, int daysAhead) {
    double baseDemand = patterns.averageDailySales * daysAhead;
    
    // Aplicar tendencia
    switch (patterns.trend) {
      case DemandTrend.increasing:
        baseDemand *= 1.2;
        break;
      case DemandTrend.decreasing:
        baseDemand *= 0.8;
        break;
      case DemandTrend.stable:
        break;
    }
    
    // Aplicar estacionalidad
    baseDemand *= (1 + patterns.seasonality * 0.3);
    
    // Aplicar factor de confianza basado en volatilidad
    final confidence = (1 - patterns.volatility).clamp(0.0, 1.0);
    
    // Determinar urgencia
    DemandUrgency urgency;
    if (baseDemand > 10 && confidence > 0.7) {
      urgency = DemandUrgency.high;
    } else if (baseDemand > 5 && confidence > 0.5) {
      urgency = DemandUrgency.medium;
    } else {
      urgency = DemandUrgency.low;
    }
    
    return DemandPrediction(
      productoId: 0, // Se asignará después
      predictedDemand: baseDemand.round(),
      confidence: confidence,
      recommendation: '',
      urgency: urgency,
    );
  }

  /// Genera recomendación de stock
  String _generateStockRecommendation(DemandPrediction prediction, DemandPatterns patterns) {
    if (prediction.urgency == DemandUrgency.high) {
      return 'Alta demanda esperada. Considera aumentar el stock significativamente.';
    } else if (prediction.urgency == DemandUrgency.medium) {
      return 'Demanda moderada esperada. Revisa el stock actual.';
    } else {
      return 'Demanda baja esperada. Mantén el stock actual.';
    }
  }

  /// Calcula el stock recomendado
  int _calculateRecommendedStock(int currentStock, int predictedDemand, DemandUrgency urgency) {
    final safetyFactor = urgency == DemandUrgency.high ? 2.0 : 1.5;
    return (predictedDemand * safetyFactor).round();
  }
}

/// Patrones de demanda identificados
class DemandPatterns {
  final double averageDailySales;
  final DemandTrend trend;
  final double seasonality;
  final double volatility;

  DemandPatterns({
    required this.averageDailySales,
    required this.trend,
    required this.seasonality,
    required this.volatility,
  });
}

/// Tendencia de demanda
enum DemandTrend {
  increasing,
  stable,
  decreasing,
}

/// Urgencia de la demanda
enum DemandUrgency {
  low,
  medium,
  high,
}

/// Predicción de demanda para un producto
class DemandPrediction {
  final int productoId;
  final int predictedDemand;
  final double confidence;
  final String recommendation;
  final DemandUrgency urgency;

  DemandPrediction({
    required this.productoId,
    required this.predictedDemand,
    required this.confidence,
    required this.recommendation,
    required this.urgency,
  });

  DemandPrediction copyWith({
    int? productoId,
    int? predictedDemand,
    double? confidence,
    String? recommendation,
    DemandUrgency? urgency,
  }) {
    return DemandPrediction(
      productoId: productoId ?? this.productoId,
      predictedDemand: predictedDemand ?? this.predictedDemand,
      confidence: confidence ?? this.confidence,
      recommendation: recommendation ?? this.recommendation,
      urgency: urgency ?? this.urgency,
    );
  }
}

/// Recomendación de stock para un producto
class StockRecommendation {
  final Producto producto;
  final int currentStock;
  final int recommendedStock;
  final int predictedDemand;
  final DemandUrgency urgency;
  final String reason;
  final double confidence;

  StockRecommendation({
    required this.producto,
    required this.currentStock,
    required this.recommendedStock,
    required this.predictedDemand,
    required this.urgency,
    required this.reason,
    required this.confidence,
  });

  int get stockDifference => recommendedStock - currentStock;
  double get stockIncreasePercentage => 
      currentStock > 0 ? (stockDifference / currentStock) * 100 : 0;
}
