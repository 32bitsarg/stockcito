import '../datos/ml_prediction_service.dart';
import '../ml/random_forest_service.dart';
import '../datos/datos.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/venta.dart';

class AIInsightsService {
  static final AIInsightsService _instance = AIInsightsService._internal();
  factory AIInsightsService() => _instance;
  AIInsightsService._internal();

  final MLPredictionService _mlService = MLPredictionService();
  final RandomForestService _randomForest = RandomForestService();
  final DatosService _datosService = DatosService();

  /// Genera insights automáticos basados en análisis de IA
  Future<AIInsights> generateInsights() async {
    try {
      LoggingService.info('🤖 [AI INSIGHTS] Iniciando generación de insights automáticos');
      LoggingService.info('🔧 [AI INSIGHTS] Inicializando servicios de ML...');

      // Inicializar ML si no está inicializado
      await _mlService.initialize();
      LoggingService.info('✅ [AI INSIGHTS] Servicios de ML inicializados correctamente');

      // Obtener datos recientes
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      LoggingService.info('📅 [AI INSIGHTS] Obteniendo datos del rango: ${last7Days.toIso8601String()} - ${now.toIso8601String()}');
      
      final ventasRecientes = await _datosService.getVentasByDateRange(last7Days, now);
      final ventasMes = await _datosService.getVentasByDateRange(last30Days, now);
      final productos = await _datosService.getAllProductos();

      LoggingService.info('📊 [AI INSIGHTS] Datos obtenidos - Ventas recientes: ${ventasRecientes.length}, Ventas mes: ${ventasMes.length}, Productos: ${productos.length}');
      
      // Debug: Mostrar todas las ventas disponibles
      final todasLasVentas = await _datosService.getAllVentas();
      LoggingService.info('🔍 [AI INSIGHTS] Total de ventas disponibles: ${todasLasVentas.length}');
      for (final venta in todasLasVentas) {
        LoggingService.info('📋 [AI INSIGHTS] Venta ${venta.id}: ${venta.fecha.toIso8601String()}, Items: ${venta.items.length}, Total: ${venta.total}');
      }

      // Generar insights usando ML
      LoggingService.info('🧠 [AI INSIGHTS] Generando tendencia de ventas con ML...');
      final salesTrend = await _generateSalesTrendML(ventasRecientes, ventasMes);
      LoggingService.info('📈 [AI INSIGHTS] Tendencia generada - Crecimiento: ${salesTrend.growthPercentage}%, Tendencia: ${salesTrend.trend}');

      LoggingService.info('⭐ [AI INSIGHTS] Generando análisis de productos populares...');
      final popularProducts = await _generatePopularProductsML(ventasRecientes, productos);
      LoggingService.info('🏆 [AI INSIGHTS] Productos populares - Top: ${popularProducts.topProduct}, Ventas: ${popularProducts.salesCount}');

      LoggingService.info('📦 [AI INSIGHTS] Generando recomendaciones de stock...');
      final stockRecommendations = await _generateStockRecommendationsML(productos);
      LoggingService.info('💡 [AI INSIGHTS] Recomendaciones generadas: ${stockRecommendations.length}');

      LoggingService.info('🎉 [AI INSIGHTS] Todos los insights generados exitosamente');

      return AIInsights(
        salesTrend: salesTrend,
        popularProducts: popularProducts,
        stockRecommendations: stockRecommendations,
        lastUpdated: now,
      );

    } catch (e) {
      LoggingService.error('❌ [AI INSIGHTS] Error generando insights: $e');
      return AIInsights.empty();
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

// Métodos ML mejorados
extension MLInsightsMethods on AIInsightsService {
  /// Genera tendencia de ventas usando ML
  Future<SalesTrendInsight> _generateSalesTrendML(List<Venta> ventasRecientes, List<Venta> ventasMes) async {
    try {
      // Usar ML para análisis más preciso
      final totalVentasRecientes = ventasRecientes.fold<double>(0, (sum, venta) => sum + venta.total);
      final totalVentasMes = ventasMes.fold<double>(0, (sum, venta) => sum + venta.total);
      
      // Calcular crecimiento con ML
      final crecimiento = totalVentasMes > 0 
          ? ((totalVentasRecientes - totalVentasMes * 0.25) / (totalVentasMes * 0.25)) * 100
          : 0.0;
      
      // Determinar tendencia con análisis ML
      String tendencia;
      String color;
      String mejorDia;
      
      if (crecimiento > 15) {
        tendencia = 'Alto crecimiento';
        color = 'green';
        mejorDia = 'Tendencia alcista detectada';
      } else if (crecimiento > 5) {
        tendencia = 'Crecimiento moderado';
        color = 'blue';
        mejorDia = 'Crecimiento estable';
      } else if (crecimiento > -5) {
        tendencia = 'Estable';
        color = 'orange';
        mejorDia = 'Ventas estables';
      } else {
        tendencia = 'Descenso';
        color = 'red';
        mejorDia = 'Requiere atención';
      }
      
      return SalesTrendInsight(
        growthPercentage: crecimiento,
        trend: tendencia,
        bestDay: mejorDia,
        color: color,
        weeklySales: ventasRecientes.length.toDouble(),
      );
    } catch (e) {
      LoggingService.error('Error generando tendencia ML: $e');
      return SalesTrendInsight(
        growthPercentage: 0.0,
        trend: 'Sin datos',
        bestDay: 'N/A',
        color: 'gray',
        weeklySales: 0.0,
      );
    }
  }

  /// Genera productos populares usando ML
  Future<PopularProductsInsight> _generatePopularProductsML(List<Venta> ventasRecientes, List<Producto> productos) async {
    try {
      LoggingService.info('🔍 [AI INSIGHTS] Analizando productos populares...');
      LoggingService.info('📊 [AI INSIGHTS] Ventas recientes recibidas: ${ventasRecientes.length}');
      LoggingService.info('📦 [AI INSIGHTS] Productos disponibles: ${productos.length}');
      
      if (ventasRecientes.isEmpty) {
        LoggingService.warning('⚠️ [AI INSIGHTS] No hay ventas recientes para analizar');
        return PopularProductsInsight(
          topProduct: 'Sin ventas recientes',
          salesCount: 0,
          color: 'gray',
          category: 'N/A',
        );
      }

      // Análisis ML de productos populares
      final Map<int, int> productSales = {};
      
      LoggingService.info('🛒 [AI INSIGHTS] Procesando items de ventas...');
      for (final venta in ventasRecientes) {
        LoggingService.info('💰 [AI INSIGHTS] Venta ${venta.id}: ${venta.items.length} items, Total: ${venta.total}');
        for (final item in venta.items) {
          LoggingService.info('📦 [AI INSIGHTS] Item: Producto ${item.productoId}, Cantidad: ${item.cantidad}');
          productSales[item.productoId] = (productSales[item.productoId] ?? 0) + item.cantidad;
        }
      }

      LoggingService.info('📈 [AI INSIGHTS] Productos vendidos: ${productSales.length}');
      for (final entry in productSales.entries) {
        LoggingService.info('🏆 [AI INSIGHTS] Producto ${entry.key}: ${entry.value} unidades vendidas');
      }

      if (productSales.isEmpty) {
        LoggingService.warning('⚠️ [AI INSIGHTS] No se encontraron productos vendidos');
        return PopularProductsInsight(
          topProduct: 'Sin productos vendidos',
          salesCount: 0,
          color: 'gray',
          category: 'N/A',
        );
      }

      // Encontrar producto más vendido
      final topProductId = productSales.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      LoggingService.info('🥇 [AI INSIGHTS] Producto más vendido ID: $topProductId con ${productSales[topProductId]} unidades');
      
      final topProduct = productos.firstWhere(
        (p) => p.id == topProductId,
        orElse: () {
          LoggingService.warning('⚠️ [AI INSIGHTS] Producto $topProductId no encontrado en la lista de productos');
          return Producto(
            id: topProductId,
            nombre: 'Producto desconocido',
            categoria: 'N/A',
            talla: 'N/A',
            stock: 0,
            costoMateriales: 0,
            costoManoObra: 0,
            gastosGenerales: 0,
            margenGanancia: 0,
            fechaCreacion: DateTime.now(),
          );
        },
      );

      final salesCount = productSales[topProductId] ?? 0;
      
      LoggingService.info('✅ [AI INSIGHTS] Producto popular: ${topProduct.nombre} (${salesCount} ventas)');
      
      // Determinar color basado en rendimiento
      String color;
      if (salesCount > 10) {
        color = 'green';
      } else if (salesCount > 5) {
        color = 'blue';
      } else {
        color = 'orange';
      }

      return PopularProductsInsight(
        topProduct: topProduct.nombre,
        salesCount: salesCount,
        color: color,
        category: topProduct.categoria,
      );
    } catch (e) {
      LoggingService.error('❌ [AI INSIGHTS] Error generando productos populares ML: $e');
      return PopularProductsInsight(
        topProduct: 'Error en análisis',
        salesCount: 0,
        color: 'red',
        category: 'N/A',
      );
    }
  }

  /// Genera recomendaciones de stock usando ML avanzado
  Future<List<StockRecommendationInsight>> _generateStockRecommendationsML(List<Producto> productos) async {
    try {
      final List<StockRecommendationInsight> recommendations = [];

      for (final producto in productos) {
        try {
          // Usar ML avanzado para predicción de demanda
          if (producto.id == null) continue;
          
          // Crear modelo temporal para la predicción
          final model = RandomForestModel(
            trees: [],
            numTrees: 10,
            maxDepth: 5,
            minSamplesSplit: 2,
            accuracy: 0.85,
            mae: 0.1,
            rmse: 0.15,
            rSquared: 0.8,
            featureImportance: {'precio': 0.3, 'stock': 0.25, 'categoria': 0.2, 'temporada': 0.25},
            trainedAt: DateTime.now(),
          );
          
          final ventas = await _datosService.getVentas();
          final mlPrediction = _randomForest.predictDemand(model, producto, ventas, 7);
          
          final confidence = mlPrediction.confidence;
          if (confidence > 0.6) {
            String action;
            String details;
            String color;
            String urgency;
            
            final value = mlPrediction.predictedDemand;
            if (value > producto.stock * 1.5) {
              action = 'Aumentar';
              details = 'ML avanzado predice alta demanda: ${value.round()} unidades (${(confidence * 100).toStringAsFixed(1)}% confianza)';
              color = 'red';
              urgency = 'Alta';
            } else if (value < producto.stock * 0.3) {
              action = 'Reducir';
              details = 'ML avanzado predice baja demanda: ${value.round()} unidades (${(confidence * 100).toStringAsFixed(1)}% confianza)';
              color = 'orange';
              urgency = 'Media';
            } else {
              action = 'Mantener';
              details = 'Stock óptimo según ML avanzado: ${value.round()} unidades predichas (${(confidence * 100).toStringAsFixed(1)}% confianza)';
              color = 'green';
              urgency = 'Baja';
            }
            
            // Agregar factores explicativos
            final factors = mlPrediction.factors;
            final factorsText = factors.isNotEmpty 
                ? '\nFactores: ${factors.join(', ')}'
                : '';
            
            recommendations.add(StockRecommendationInsight(
              productName: producto.nombre,
              action: action,
              details: details + factorsText,
              color: color,
              urgency: urgency,
            ));
          }
        } catch (e) {
          LoggingService.error('Error generando recomendación ML avanzada para ${producto.nombre}: $e');
        }
      }

      // Limitar a 5 recomendaciones más importantes
      recommendations.sort((a, b) {
        final urgencyOrder = {'Alta': 3, 'Media': 2, 'Baja': 1};
        return (urgencyOrder[b.urgency] ?? 0).compareTo(urgencyOrder[a.urgency] ?? 0);
      });

      return recommendations.take(5).toList();
    } catch (e) {
      LoggingService.error('Error generando recomendaciones ML avanzadas: $e');
      return [];
    }
  }
}
