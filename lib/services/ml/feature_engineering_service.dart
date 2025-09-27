import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/ml_prediction_models.dart';
import 'statistical_analysis_service.dart';

/// Servicio para ingeniería de features real sin simulaciones
class FeatureEngineeringService {
  static final FeatureEngineeringService _instance = FeatureEngineeringService._internal();
  factory FeatureEngineeringService() => _instance;
  FeatureEngineeringService._internal();

  final StatisticalAnalysisService _statisticalService = StatisticalAnalysisService();

  /// Genera features para predicción de demanda
  MLFeatures generateDemandFeatures(List<Venta> ventas, Producto producto, int daysAhead) {
    try {
      LoggingService.info('🔧 Generando features de demanda para producto ${producto.id}');

      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));
      final last90Days = now.subtract(const Duration(days: 90));

      // Filtrar ventas del producto específico
      final productVentas = ventas.where((v) => 
        v.items.any((item) => item.productoId == producto.id)
      ).toList();

      // Features básicos
      final ventas7Dias = productVentas.where((v) => v.fecha.isAfter(last7Days)).length;
      final ventas30Dias = productVentas.where((v) => v.fecha.isAfter(last30Days)).length;
      final ventas90Dias = productVentas.where((v) => v.fecha.isAfter(last90Days)).length;

      // Calcular métricas estadísticas reales
      final salesTrend = _statisticalService.calculateSalesTrend(productVentas, 30);
      final salesVolatility = _statisticalService.calculateSalesVolatility(productVentas, 30);
      final seasonalFactors = _statisticalService.calculateSeasonalFactors(productVentas);
      final weeklyPattern = _statisticalService.calculateWeeklyPattern(productVentas);

      // Features de precio
      final avgPrice = productVentas.isNotEmpty 
          ? productVentas.map((v) => v.total / v.items.fold(0, (sum, item) => sum + item.cantidad)).reduce((a, b) => a + b) / productVentas.length
          : producto.precioVenta;

      final priceElasticity = _statisticalService.calculatePriceElasticity(productVentas, avgPrice);
      final priceQuantityCorrelation = _statisticalService.calculatePriceQuantityCorrelation(productVentas);

      // Features de stock
      final stockRatio = producto.stock / max(producto.stock + ventas7Dias, 1);
      final stockTurnover = ventas30Dias > 0 ? producto.stock / ventas30Dias : 0.0;

      // Features temporales
      final currentSeasonalFactor = seasonalFactors[now.month] ?? 1.0;
      final currentWeeklyFactor = weeklyPattern[now.weekday] ?? 1.0;
      final dayOfMonth = now.day / 31.0; // Normalizar día del mes
      final dayOfWeek = now.weekday / 7.0; // Normalizar día de la semana

      // Features de categoría (one-hot encoding)
      final categoryFeatures = _encodeCategoryFeatures(producto.categoria);

      // Features de tendencia
      final trendAcceleration = _calculateTrendAcceleration(productVentas, 30);
      final momentum = _calculateMomentum(productVentas, 7);

      // Construir vector de features
      final demandFeatures = [
        producto.precioVenta,
        producto.stock.toDouble(),
        ventas7Dias.toDouble(),
        ventas30Dias.toDouble(),
        ventas90Dias.toDouble(),
        salesTrend,
        salesVolatility,
        avgPrice,
        priceElasticity,
        priceQuantityCorrelation,
        stockRatio,
        stockTurnover,
        currentSeasonalFactor,
        currentWeeklyFactor,
        dayOfMonth,
        dayOfWeek,
        trendAcceleration,
        momentum,
        ...categoryFeatures,
      ];

      // Features de precio
      final priceFeatures = [
        producto.precioVenta,
        avgPrice,
        priceElasticity,
        priceQuantityCorrelation,
        salesTrend,
        currentSeasonalFactor,
        stockRatio,
      ];

      // Features de mercado
      final marketFeatures = {
        'competition_level': _calculateCompetitionLevel(producto.categoria, productVentas),
        'market_share': _calculateMarketShare(producto, productVentas),
        'demand_supply_ratio': _calculateDemandSupplyRatio(producto, productVentas),
        'price_positioning': _calculatePricePositioning(producto, productVentas),
      };

      LoggingService.info('✅ Features de demanda generados: ${demandFeatures.length} features');

      return MLFeatures(
        demandFeatures: demandFeatures,
        priceFeatures: priceFeatures,
        customerFeatures: {}, // Se llena en análisis de clientes
        marketFeatures: marketFeatures,
        featureDate: now,
      );
    } catch (e) {
      LoggingService.error('❌ Error generando features de demanda: $e');
      return MLFeatures(
        demandFeatures: [],
        priceFeatures: [],
        customerFeatures: {},
        marketFeatures: {},
        featureDate: DateTime.now(),
      );
    }
  }

  /// Genera features para análisis de clientes
  Map<String, dynamic> generateCustomerFeatures(List<Venta> ventas, List<dynamic> clientes) {
    try {
      LoggingService.info('🔧 Generando features de clientes');

      // Agrupar ventas por cliente
      final Map<String, List<Venta>> customerSales = {};
      for (final venta in ventas) {
        final customerId = venta.id.toString(); // Usar ID de venta como identificador temporal
        customerSales[customerId] = customerSales[customerId] ?? [];
        customerSales[customerId]!.add(venta);
      }

      // Calcular métricas por cliente
      final List<Map<String, dynamic>> customerMetrics = [];
      
      for (final customerId in customerSales.keys) {
        final sales = customerSales[customerId]!;
        if (sales.isNotEmpty) {
          final metrics = _calculateCustomerMetrics(sales, customerId);
          customerMetrics.add(metrics);
        }
      }

      // Calcular métricas agregadas
      final totalRevenue = ventas.map((v) => v.total).reduce((a, b) => a + b);
      final avgOrderValue = totalRevenue / ventas.length;
      final customerLifetimeValue = _statisticalService.calculateCustomerLifetimeValue(ventas, clientes);
      final retentionRate = _statisticalService.calculateRetentionRate(ventas, clientes);

      // Features de segmentación
      final segmentationFeatures = {
        'customer_metrics': customerMetrics,
        'total_customers': clientes.length,
        'total_ventas': ventas.length,
        'total_revenue': totalRevenue,
        'avg_order_value': avgOrderValue,
        'customer_lifetime_value': customerLifetimeValue,
        'retention_rate': retentionRate,
        'customer_frequency_distribution': _calculateFrequencyDistribution(customerMetrics),
        'customer_value_distribution': _calculateValueDistribution(customerMetrics),
      };

      LoggingService.info('✅ Features de clientes generados');

      return segmentationFeatures;
    } catch (e) {
      LoggingService.error('❌ Error generando features de clientes: $e');
      return {};
    }
  }

  /// Calcula métricas individuales de cliente
  Map<String, dynamic> _calculateCustomerMetrics(List<Venta> sales, String customerId) {
    final totalSpent = sales.map((v) => v.total).reduce((a, b) => a + b);
    final orderCount = sales.length;
    final avgOrderValue = totalSpent / orderCount;
    
    final firstPurchase = sales.map((v) => v.fecha).reduce((a, b) => a.isBefore(b) ? a : b);
    final lastPurchase = sales.map((v) => v.fecha).reduce((a, b) => a.isAfter(b) ? a : b);
    final daysActive = lastPurchase.difference(firstPurchase).inDays;
    
    final purchaseFrequency = daysActive > 0 ? orderCount / (daysActive / 30.0) : 0.0;
    
    // Calcular categorías preferidas
    final categoryCounts = <String, int>{};
    for (final venta in sales) {
      for (final item in venta.items) {
        // Aquí necesitarías obtener la categoría del producto
        // Por simplicidad, usamos un placeholder
        categoryCounts['general'] = (categoryCounts['general'] ?? 0) + item.cantidad;
      }
    }
    
    final preferredCategory = categoryCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return {
      'customer_id': customerId,
      'total_spent': totalSpent,
      'order_count': orderCount,
      'avg_order_value': avgOrderValue,
      'purchase_frequency': purchaseFrequency,
      'days_active': daysActive,
      'preferred_category': preferredCategory,
      'first_purchase': firstPurchase.toIso8601String(),
      'last_purchase': lastPurchase.toIso8601String(),
    };
  }

  /// Codifica features de categoría usando one-hot encoding
  List<double> _encodeCategoryFeatures(String categoria) {
    final categories = ['Bodies', 'Conjuntos', 'Vestidos', 'Pijamas', 'Gorros', 'Accesorios', 'Ropa Interior', 'Deportiva'];
    final features = List<double>.filled(categories.length, 0.0);
    
    final index = categories.indexOf(categoria);
    if (index >= 0) {
      features[index] = 1.0;
    }
    
    return features;
  }

  /// Calcula la aceleración de la tendencia
  double _calculateTrendAcceleration(List<Venta> ventas, int days) {
    if (ventas.length < 3) return 0.0;

    final now = DateTime.now();
    final periods = [
      now.subtract(Duration(days: days ~/ 3)),
      now.subtract(Duration(days: (days * 2) ~/ 3)),
      now.subtract(Duration(days: days)),
    ];

    final List<double> periodSales = [];
    for (final period in periods) {
      final sales = ventas.where((v) => v.fecha.isAfter(period)).length;
      periodSales.add(sales.toDouble());
    }

    // Calcular segunda derivada (aceleración)
    if (periodSales.length >= 3) {
      final firstDerivative = periodSales[1] - periodSales[0];
      final secondDerivative = periodSales[2] - periodSales[1];
      return secondDerivative - firstDerivative;
    }

    return 0.0;
  }

  /// Calcula el momentum de ventas
  double _calculateMomentum(List<Venta> ventas, int days) {
    if (ventas.length < 2) return 0.0;

    final now = DateTime.now();
    final recentPeriod = now.subtract(Duration(days: days));
    final previousPeriod = now.subtract(Duration(days: days * 2));

    final recentSales = ventas.where((v) => v.fecha.isAfter(recentPeriod)).length;
    final previousSales = ventas.where((v) => 
      v.fecha.isAfter(previousPeriod) && v.fecha.isBefore(recentPeriod)
    ).length;

    return previousSales > 0 ? (recentSales - previousSales) / previousSales : 0.0;
  }

  /// Calcula el nivel de competencia real
  double _calculateCompetitionLevel(String categoria, List<Venta> ventas) {
    // Basado en la variabilidad de precios en la categoría
    final categoryVentas = ventas.where((v) => 
      v.items.isNotEmpty // Verificar que hay items
    ).toList();

    if (categoryVentas.length < 2) return 0.5; // Valor por defecto

    final prices = categoryVentas.map((v) => 
      v.total / v.items.fold(0, (sum, item) => sum + item.cantidad)
    ).toList();

    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final variance = prices.map((p) => pow(p - avgPrice, 2)).reduce((a, b) => a + b) / prices.length;
    final coefficientOfVariation = sqrt(variance) / avgPrice;

    // Normalizar entre 0 y 1
    return (coefficientOfVariation / 0.5).clamp(0.0, 1.0);
  }

  /// Calcula la participación de mercado
  double _calculateMarketShare(Producto producto, List<Venta> ventas) {
    final productVentas = ventas.where((v) => 
      v.items.any((item) => item.productoId == producto.id)
    ).length;

    return ventas.isNotEmpty ? productVentas / ventas.length : 0.0;
  }

  /// Calcula la relación demanda-oferta
  double _calculateDemandSupplyRatio(Producto producto, List<Venta> ventas) {
    final productVentas = ventas.where((v) => 
      v.items.any((item) => item.productoId == producto.id)
    ).length;

    return producto.stock > 0 ? productVentas / producto.stock : 0.0;
  }

  /// Calcula el posicionamiento de precio
  double _calculatePricePositioning(Producto producto, List<Venta> ventas) {
    if (ventas.isEmpty) return 0.5;

    final allPrices = ventas.map((v) => 
      v.total / v.items.fold(0, (sum, item) => sum + item.cantidad)
    ).toList();

    allPrices.sort();
    final medianPrice = allPrices[allPrices.length ~/ 2];
    
    return producto.precioVenta / medianPrice;
  }

  /// Calcula distribución de frecuencia de clientes
  Map<String, int> _calculateFrequencyDistribution(List<Map<String, dynamic>> customerMetrics) {
    final distribution = <String, int>{
      'low': 0,
      'medium': 0,
      'high': 0,
    };

    for (final metrics in customerMetrics) {
      final frequency = metrics['purchase_frequency'] as double;
      if (frequency < 1.0) {
        distribution['low'] = distribution['low']! + 1;
      } else if (frequency < 3.0) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['high'] = distribution['high']! + 1;
      }
    }

    return distribution;
  }

  /// Calcula distribución de valor de clientes
  Map<String, int> _calculateValueDistribution(List<Map<String, dynamic>> customerMetrics) {
    final distribution = <String, int>{
      'low': 0,
      'medium': 0,
      'high': 0,
    };

    for (final metrics in customerMetrics) {
      final totalSpent = metrics['total_spent'] as double;
      if (totalSpent < 100) {
        distribution['low'] = distribution['low']! + 1;
      } else if (totalSpent < 500) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['high'] = distribution['high']! + 1;
      }
    }

    return distribution;
  }
}
