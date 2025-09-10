import 'package:ricitosdebb/services/demand_prediction_service.dart';
import 'package:ricitosdebb/services/database_service.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/models/producto.dart';
import 'package:ricitosdebb/models/venta.dart';

class AIInsightsService {
  static final AIInsightsService _instance = AIInsightsService._internal();
  factory AIInsightsService() => _instance;
  AIInsightsService._internal();

  final DemandPredictionService _demandPrediction = DemandPredictionService();
  final DatabaseService _databaseService = DatabaseService();

  /// Genera insights automáticos basados en análisis de IA
  Future<AIInsights> generateInsights() async {
    try {
      LoggingService.info('Generando insights automáticos de IA');

      // Obtener datos recientes
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      final ventasRecientes = await _databaseService.getVentasByDateRange(last7Days, now);
      final ventasMes = await _databaseService.getVentasByDateRange(last30Days, now);
      final productos = await _databaseService.getAllProductos();

      // Generar insights
      final salesTrend = await _generateSalesTrend(ventasRecientes, ventasMes);
      final popularProducts = await _generatePopularProducts(ventasRecientes, productos);
      final stockRecommendations = await _generateStockRecommendations(productos);

      LoggingService.info('Insights generados exitosamente');

      return AIInsights(
        salesTrend: salesTrend,
        popularProducts: popularProducts,
        stockRecommendations: stockRecommendations,
        lastUpdated: now,
      );

    } catch (e) {
      LoggingService.error('Error generando insights: $e');
      return AIInsights.empty();
    }
  }

  /// Genera tendencia de ventas
  Future<SalesTrendInsight> _generateSalesTrend(List<Venta> ventasRecientes, List<Venta> ventasMes) async {
    if (ventasRecientes.isEmpty) {
      return SalesTrendInsight(
        growthPercentage: 0.0,
        weeklySales: 0.0,
        bestDay: 'Sin datos',
        trend: 'Estable',
        color: 'grey',
      );
    }

    // Calcular crecimiento semanal
    final thisWeek = ventasRecientes.fold<double>(0, (sum, v) => sum + v.total);
    final lastWeek = ventasMes.take(7).fold<double>(0, (sum, v) => sum + v.total);
    final growth = lastWeek > 0 ? ((thisWeek - lastWeek) / lastWeek) * 100 : 0.0;

    // Encontrar mejor día
    final Map<int, double> ventasPorDia = {};
    for (int i = 1; i <= 7; i++) {
      ventasPorDia[i] = ventasRecientes
          .where((v) => v.fecha.weekday == i)
          .fold<double>(0, (sum, v) => sum + v.total);
    }
    final mejorDia = ventasPorDia.entries.reduce((a, b) => a.value > b.value ? a : b);
    final diaNombres = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    // Determinar tendencia y color
    String trend = 'Estable';
    String color = 'grey';
    if (growth > 10) {
      trend = 'Creciendo';
      color = 'green';
    } else if (growth < -10) {
      trend = 'Decreciendo';
      color = 'red';
    }

    return SalesTrendInsight(
      growthPercentage: growth,
      weeklySales: thisWeek,
      bestDay: diaNombres[mejorDia.key],
      trend: trend,
      color: color,
    );
  }

  /// Genera productos populares
  Future<PopularProductsInsight> _generatePopularProducts(List<Venta> ventas, List<Producto> productos) async {
    if (ventas.isEmpty || productos.isEmpty) {
      return PopularProductsInsight(
        topProduct: 'Sin datos',
        salesCount: 0,
        category: 'N/A',
        color: 'grey',
      );
    }

    // Contar ventas por producto
    final Map<int, int> ventasPorProducto = {};
    for (final venta in ventas) {
      for (final item in venta.items) {
        ventasPorProducto[item.productoId] = (ventasPorProducto[item.productoId] ?? 0) + item.cantidad;
      }
    }

    if (ventasPorProducto.isEmpty) {
      return PopularProductsInsight(
        topProduct: 'Sin ventas',
        salesCount: 0,
        category: 'N/A',
        color: 'grey',
      );
    }

    // Encontrar producto más vendido
    final topProductId = ventasPorProducto.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final topProduct = productos.firstWhere((p) => p.id == topProductId, orElse: () => productos.first);
    final salesCount = ventasPorProducto[topProductId] ?? 0;

    return PopularProductsInsight(
      topProduct: topProduct.nombre,
      salesCount: salesCount,
      category: topProduct.categoria,
      color: 'orange',
    );
  }

  /// Genera recomendaciones de stock
  Future<List<StockRecommendationInsight>> _generateStockRecommendations(List<Producto> productos) async {
    final List<StockRecommendationInsight> recommendations = [];

    for (final producto in productos) {
      try {
        // Obtener predicción de demanda
        if (producto.id == null) continue;
        final prediction = await _demandPrediction.predictDemandForProduct(producto.id!, 7);
        
        // Generar recomendación basada en stock actual y demanda predicha
        final currentStock = producto.stock;
        final predictedDemand = prediction.predictedDemand;
        
        String action = 'Mantener';
        String color = 'green';
        String details = 'Stock óptimo';
        
        if (currentStock < predictedDemand * 0.5) {
          action = 'Aumentar';
          color = 'red';
          details = 'Stock actual: $currentStock → Recomendado: ${(predictedDemand * 1.2).round()}';
        } else if (currentStock > predictedDemand * 2) {
          action = 'Reducir';
          color = 'orange';
          details = 'Stock actual: $currentStock → Recomendado: ${(predictedDemand * 1.1).round()}';
        } else {
          details = 'Stock actual: $currentStock (óptimo)';
        }

        recommendations.add(StockRecommendationInsight(
          productName: producto.nombre,
          action: action,
          details: details,
          color: color,
          urgency: prediction.urgency.toString().split('.').last,
        ));

      } catch (e) {
        LoggingService.error('Error generando recomendación para ${producto.nombre}: $e');
      }
    }

    // Ordenar por urgencia y limitar a 3 recomendaciones principales
    recommendations.sort((a, b) => _getUrgencyPriority(b.urgency).compareTo(_getUrgencyPriority(a.urgency)));
    return recommendations.take(3).toList();
  }

  int _getUrgencyPriority(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': return 1;
      default: return 0;
    }
  }
}

// Modelos de datos para los insights
class AIInsights {
  final SalesTrendInsight salesTrend;
  final PopularProductsInsight popularProducts;
  final List<StockRecommendationInsight> stockRecommendations;
  final DateTime lastUpdated;

  AIInsights({
    required this.salesTrend,
    required this.popularProducts,
    required this.stockRecommendations,
    required this.lastUpdated,
  });

  factory AIInsights.empty() {
    return AIInsights(
      salesTrend: SalesTrendInsight.empty(),
      popularProducts: PopularProductsInsight.empty(),
      stockRecommendations: [],
      lastUpdated: DateTime.now(),
    );
  }
}

class SalesTrendInsight {
  final double growthPercentage;
  final double weeklySales;
  final String bestDay;
  final String trend;
  final String color;

  SalesTrendInsight({
    required this.growthPercentage,
    required this.weeklySales,
    required this.bestDay,
    required this.trend,
    required this.color,
  });

  factory SalesTrendInsight.empty() {
    return SalesTrendInsight(
      growthPercentage: 0.0,
      weeklySales: 0.0,
      bestDay: 'Sin datos',
      trend: 'Estable',
      color: 'grey',
    );
  }
}

class PopularProductsInsight {
  final String topProduct;
  final int salesCount;
  final String category;
  final String color;

  PopularProductsInsight({
    required this.topProduct,
    required this.salesCount,
    required this.category,
    required this.color,
  });

  factory PopularProductsInsight.empty() {
    return PopularProductsInsight(
      topProduct: 'Sin datos',
      salesCount: 0,
      category: 'N/A',
      color: 'grey',
    );
  }
}

class StockRecommendationInsight {
  final String productName;
  final String action;
  final String details;
  final String color;
  final String urgency;

  StockRecommendationInsight({
    required this.productName,
    required this.action,
    required this.details,
    required this.color,
    required this.urgency,
  });
}
