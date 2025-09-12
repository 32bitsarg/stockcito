import 'datos/datos.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/models/producto.dart';
import 'package:ricitosdebb/models/venta.dart';
import 'dart:math';

class AdvancedAIAnalysisService {
  final DatosService _datosService = DatosService();

  // Análisis de tendencias estacionales
  Future<SeasonalAnalysis> analyzeSeasonalTrends() async {
    try {
      LoggingService.info('Iniciando análisis de tendencias estacionales');
      
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final ventas = await _datosService.getVentasByDateRange(last30Days, now);
      
      // Análisis por días de la semana
      final Map<int, List<Venta>> ventasPorDia = {};
      for (int i = 1; i <= 7; i++) {
        ventasPorDia[i] = ventas.where((v) => v.fecha.weekday == i).toList();
      }
      
      // Análisis por horas del día (simulado)
      final Map<int, int> ventasPorHora = {};
      for (int i = 0; i < 24; i++) {
        ventasPorHora[i] = Random().nextInt(10); // Simulado por ahora
      }
      
      // Calcular tendencias
      final tendenciasDias = <String, double>{};
      for (int dia = 1; dia <= 7; dia++) {
        final ventasDia = ventasPorDia[dia]?.length ?? 0;
        final promedio = ventas.length / 7;
        tendenciasDias[_getDayName(dia)] = ventasDia / promedio;
      }
      
      // Encontrar mejor y peor día
      final mejorDia = tendenciasDias.entries.reduce((a, b) => a.value > b.value ? a : b);
      final peorDia = tendenciasDias.entries.reduce((a, b) => a.value < b.value ? a : b);
      
      // Encontrar mejor hora
      final mejorHora = ventasPorHora.entries.reduce((a, b) => a.value > b.value ? a : b);
      
      LoggingService.info('Análisis de tendencias estacionales completado');
      
      return SeasonalAnalysis(
        bestDay: mejorDia.key,
        worstDay: peorDia.key,
        bestHour: mejorHora.key,
        dayTrends: tendenciasDias,
        hourTrends: ventasPorHora,
        insights: _generateSeasonalInsights(mejorDia, peorDia, mejorHora),
      );
    } catch (e) {
      LoggingService.error('Error en análisis de tendencias estacionales: $e');
      rethrow;
    }
  }

  // Análisis de productos más rentables
  Future<ProfitabilityAnalysis> analyzeProductProfitability() async {
    try {
      LoggingService.info('Iniciando análisis de rentabilidad de productos');
      
      final productos = await _datosService.getAllProductos();
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final ventas = await _datosService.getVentasByDateRange(last30Days, now);
      
      final List<ProductProfitability> productProfits = [];
      
      for (final producto in productos) {
        // Calcular ventas del producto en los últimos 30 días
        final ventasProducto = ventas.where((v) => 
          v.items.any((item) => item.productoId == producto.id)
        ).toList();
        
        // Calcular ingresos totales
        double ingresosTotales = 0;
        double cantidadVendida = 0;
        
        for (final venta in ventasProducto) {
          for (final item in venta.items) {
            if (item.productoId == producto.id) {
              ingresosTotales += item.subtotal;
              cantidadVendida += item.cantidad;
            }
          }
        }
        
        // Calcular margen de ganancia
        final costoUnitario = producto.costoTotal;
        final precioVenta = producto.precioVenta;
        final margenUnitario = precioVenta - costoUnitario;
        final margenPorcentaje = (margenUnitario / precioVenta) * 100;
        
        // Calcular rentabilidad total
        final rentabilidadTotal = ingresosTotales * (margenPorcentaje / 100);
        
        // Calcular velocidad de venta (unidades por día)
        final velocidadVenta = cantidadVendida / 30;
        
        // Calcular score de rentabilidad
        final score = _calculateProfitabilityScore(
          margenPorcentaje, 
          velocidadVenta, 
          cantidadVendida.round()
        );
        
        productProfits.add(ProductProfitability(
          producto: producto,
          totalRevenue: ingresosTotales,
          totalSold: cantidadVendida.round(),
          profitMargin: margenPorcentaje,
          totalProfit: rentabilidadTotal,
          salesVelocity: velocidadVenta,
          profitabilityScore: score,
        ));
      }
      
      // Ordenar por score de rentabilidad
      productProfits.sort((a, b) => b.profitabilityScore.compareTo(a.profitabilityScore));
      
      // Obtener top productos
      final topProducts = productProfits.take(5).toList();
      final worstProducts = productProfits.reversed.take(3).toList();
      
      LoggingService.info('Análisis de rentabilidad completado');
      
      return ProfitabilityAnalysis(
        topProducts: topProducts,
        worstProducts: worstProducts,
        averageMargin: productProfits.map((p) => p.profitMargin).reduce((a, b) => a + b) / productProfits.length,
        totalRevenue: productProfits.map((p) => p.totalRevenue).reduce((a, b) => a + b),
        insights: _generateProfitabilityInsights(topProducts, worstProducts),
      );
    } catch (e) {
      LoggingService.error('Error en análisis de rentabilidad: $e');
      rethrow;
    }
  }

  // Recomendaciones de precios dinámicos
  Future<PriceRecommendation> getDynamicPriceRecommendation(int productoId) async {
    try {
      LoggingService.info('Generando recomendación de precio para producto $productoId');
      
      final productos = await _datosService.getAllProductos();
      final producto = productos.firstWhere((p) => p.id == productoId);
      
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final ventas = await _datosService.getVentasByDateRange(last30Days, now);
      
      // Calcular elasticidad de precio (simulada)
      final elasticidad = _calculatePriceElasticity(producto, ventas);
      
      // Calcular precio óptimo
      final precioOptimo = _calculateOptimalPrice(producto, elasticidad);
      
      // Calcular impacto esperado
      final impactoVentas = _calculateSalesImpact(producto.precioVenta, precioOptimo, elasticidad);
      final impactoIngresos = _calculateRevenueImpact(producto.precioVenta, precioOptimo, impactoVentas);
      
      // Generar recomendación
      final recomendacion = _generatePriceRecommendation(
        producto, 
        precioOptimo, 
        impactoVentas, 
        impactoIngresos
      );
      
      LoggingService.info('Recomendación de precio generada');
      
      return PriceRecommendation(
        producto: producto,
        currentPrice: producto.precioVenta,
        recommendedPrice: precioOptimo,
        priceChange: precioOptimo - producto.precioVenta,
        priceChangePercent: ((precioOptimo - producto.precioVenta) / producto.precioVenta) * 100,
        expectedSalesImpact: impactoVentas,
        expectedRevenueImpact: impactoIngresos,
        confidence: _calculateConfidence(producto, ventas),
        reasoning: recomendacion,
        riskLevel: _assessRiskLevel(producto, precioOptimo),
      );
    } catch (e) {
      LoggingService.error('Error generando recomendación de precio: $e');
      rethrow;
    }
  }

  // Detección de patrones de compra
  Future<PurchasePatternAnalysis> detectPurchasePatterns() async {
    try {
      LoggingService.info('Detectando patrones de compra');
      
      final now = DateTime.now();
      final last60Days = now.subtract(const Duration(days: 60));
      final ventas = await _datosService.getVentasByDateRange(last60Days, now);
      
      // Patrones por día de la semana
      final Map<int, int> patronesDia = {};
      for (int i = 1; i <= 7; i++) {
        patronesDia[i] = ventas.where((v) => v.fecha.weekday == i).length;
      }
      
      // Patrones por categoría (simulado)
      final Map<String, int> patronesCategoria = {
        'Ropa': Random().nextInt(50),
        'Accesorios': Random().nextInt(30),
        'Calzado': Random().nextInt(20),
      };
      
      // Detectar tendencias
      final tendencias = _detectTrends(ventas);
      
      // Detectar anomalías
      final anomalias = _detectAnomalies(ventas);
      
      // Generar insights
      final insights = _generatePatternInsights(patronesDia, patronesCategoria, tendencias, anomalias);
      
      LoggingService.info('Análisis de patrones de compra completado');
      
      return PurchasePatternAnalysis(
        dayPatterns: patronesDia,
        categoryPatterns: patronesCategoria,
        trends: tendencias,
        anomalies: anomalias,
        insights: insights,
        confidence: 0.85, // Simulado
      );
    } catch (e) {
      LoggingService.error('Error detectando patrones de compra: $e');
      rethrow;
    }
  }

  // Métodos auxiliares
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Lunes';
      case 2: return 'Martes';
      case 3: return 'Miércoles';
      case 4: return 'Jueves';
      case 5: return 'Viernes';
      case 6: return 'Sábado';
      case 7: return 'Domingo';
      default: return 'Desconocido';
    }
  }

  double _calculateProfitabilityScore(double margin, double velocity, int totalSold) {
    // Score basado en margen, velocidad y volumen
    final marginScore = (margin / 100) * 40; // 40% del score
    final velocityScore = min(velocity / 5, 1.0) * 30; // 30% del score
    final volumeScore = min(totalSold / 100, 1.0) * 30; // 30% del score
    
    return (marginScore + velocityScore + volumeScore) * 100;
  }

  double _calculatePriceElasticity(Producto producto, List<Venta> ventas) {
    // Elasticidad simulada basada en el tipo de producto
    final baseElasticity = -1.5; // Elasticidad base
    final categoryMultiplier = _getCategoryElasticityMultiplier(producto.categoria);
    return baseElasticity * categoryMultiplier;
  }

  double _getCategoryElasticityMultiplier(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'ropa':
        return 1.2;
      case 'accesorios':
        return 0.8;
      case 'calzado':
        return 1.0;
      default:
        return 1.0;
    }
  }

  double _calculateOptimalPrice(Producto producto, double elasticidad) {
    final costo = producto.costoTotal;
    final elasticidadAbs = elasticidad.abs();
    
    // Fórmula simplificada para precio óptimo
    return costo * (elasticidadAbs / (elasticidadAbs - 1));
  }

  double _calculateSalesImpact(double currentPrice, double newPrice, double elasticidad) {
    final priceChange = (newPrice - currentPrice) / currentPrice;
    return elasticidad * priceChange;
  }

  double _calculateRevenueImpact(double currentPrice, double newPrice, double salesImpact) {
    final priceChange = (newPrice - currentPrice) / currentPrice;
    return priceChange + salesImpact + (priceChange * salesImpact);
  }

  String _generatePriceRecommendation(Producto producto, double precioOptimo, double impactoVentas, double impactoIngresos) {
    if (precioOptimo > producto.precioVenta) {
      return 'Aumentar precio a \$${precioOptimo.toStringAsFixed(2)} podría aumentar ingresos en ${(impactoIngresos * 100).toStringAsFixed(1)}%';
    } else if (precioOptimo < producto.precioVenta) {
      return 'Reducir precio a \$${precioOptimo.toStringAsFixed(2)} podría aumentar ventas en ${(impactoVentas * 100).toStringAsFixed(1)}%';
    } else {
      return 'El precio actual es óptimo para este producto';
    }
  }

  double _calculateConfidence(Producto producto, List<Venta> ventas) {
    // Confianza basada en la cantidad de datos disponibles
    final dataPoints = ventas.length;
    return min(dataPoints / 50, 1.0); // Máximo 100% con 50+ ventas
  }

  String _assessRiskLevel(Producto producto, double newPrice) {
    final priceChange = (newPrice - producto.precioVenta) / producto.precioVenta;
    
    if (priceChange.abs() > 0.2) {
      return 'Alto';
    } else if (priceChange.abs() > 0.1) {
      return 'Medio';
    } else {
      return 'Bajo';
    }
  }

  List<String> _detectTrends(List<Venta> ventas) {
    // Detectar tendencias simples
    final trends = <String>[];
    
    if (ventas.length > 10) {
      final recent = ventas.take(10).length;
      final older = ventas.skip(10).take(10).length;
      
      if (recent > older * 1.2) {
        trends.add('Tendencia creciente en ventas');
      } else if (recent < older * 0.8) {
        trends.add('Tendencia decreciente en ventas');
      }
    }
    
    return trends;
  }

  List<String> _detectAnomalies(List<Venta> ventas) {
    // Detectar anomalías simples
    final anomalies = <String>[];
    
    if (ventas.isNotEmpty) {
      final totales = ventas.map((v) => v.total).toList();
      final promedio = totales.reduce((a, b) => a + b) / totales.length;
      final desviacion = _calculateStandardDeviation(totales, promedio);
      
      for (final venta in ventas) {
        if ((venta.total - promedio).abs() > 2 * desviacion) {
          anomalies.add('Venta anómala detectada: \$${venta.total}');
        }
      }
    }
    
    return anomalies;
  }

  double _calculateStandardDeviation(List<double> values, double mean) {
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  List<String> _generateSeasonalInsights(MapEntry<String, double> mejorDia, MapEntry<String, double> peorDia, MapEntry<int, int> mejorHora) {
    return [
      'El mejor día para ventas es $mejorDia con ${(mejorDia.value * 100).toStringAsFixed(0)}% del promedio',
      'El peor día para ventas es $peorDia con ${(peorDia.value * 100).toStringAsFixed(0)}% del promedio',
      'La mejor hora para ventas es ${mejorHora.key}:00 con ${mejorHora.value} ventas',
      'Considera ajustar horarios y promociones según estos patrones',
    ];
  }

  List<String> _generateProfitabilityInsights(List<ProductProfitability> topProducts, List<ProductProfitability> worstProducts) {
    final insights = <String>[];
    
    if (topProducts.isNotEmpty) {
      insights.add('${topProducts.first.producto.nombre} es tu producto más rentable');
      insights.add('Considera aumentar el stock de productos top performers');
    }
    
    if (worstProducts.isNotEmpty) {
      insights.add('${worstProducts.first.producto.nombre} tiene baja rentabilidad');
      insights.add('Revisa precios o considera discontinuar productos poco rentables');
    }
    
    return insights;
  }

  List<String> _generatePatternInsights(Map<int, int> patronesDia, Map<String, int> patronesCategoria, List<String> tendencias, List<String> anomalias) {
    final insights = <String>[];
    
    insights.addAll(tendencias);
    insights.addAll(anomalias);
    
    final mejorDia = patronesDia.entries.reduce((a, b) => a.value > b.value ? a : b);
    insights.add('El ${_getDayName(mejorDia.key)} es el día con más actividad');
    
    final mejorCategoria = patronesCategoria.entries.reduce((a, b) => a.value > b.value ? a : b);
    insights.add('$mejorCategoria es la categoría más popular');
    
    return insights;
  }
}

// Clases de datos para los análisis
class SeasonalAnalysis {
  final String bestDay;
  final String worstDay;
  final int bestHour;
  final Map<String, double> dayTrends;
  final Map<int, int> hourTrends;
  final List<String> insights;

  SeasonalAnalysis({
    required this.bestDay,
    required this.worstDay,
    required this.bestHour,
    required this.dayTrends,
    required this.hourTrends,
    required this.insights,
  });
}

class ProductProfitability {
  final Producto producto;
  final double totalRevenue;
  final int totalSold;
  final double profitMargin;
  final double totalProfit;
  final double salesVelocity;
  final double profitabilityScore;

  ProductProfitability({
    required this.producto,
    required this.totalRevenue,
    required this.totalSold,
    required this.profitMargin,
    required this.totalProfit,
    required this.salesVelocity,
    required this.profitabilityScore,
  });
}

class ProfitabilityAnalysis {
  final List<ProductProfitability> topProducts;
  final List<ProductProfitability> worstProducts;
  final double averageMargin;
  final double totalRevenue;
  final List<String> insights;

  ProfitabilityAnalysis({
    required this.topProducts,
    required this.worstProducts,
    required this.averageMargin,
    required this.totalRevenue,
    required this.insights,
  });
}

class PriceRecommendation {
  final Producto producto;
  final double currentPrice;
  final double recommendedPrice;
  final double priceChange;
  final double priceChangePercent;
  final double expectedSalesImpact;
  final double expectedRevenueImpact;
  final double confidence;
  final String reasoning;
  final String riskLevel;

  PriceRecommendation({
    required this.producto,
    required this.currentPrice,
    required this.recommendedPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.expectedSalesImpact,
    required this.expectedRevenueImpact,
    required this.confidence,
    required this.reasoning,
    required this.riskLevel,
  });
}

class PurchasePatternAnalysis {
  final Map<int, int> dayPatterns;
  final Map<String, int> categoryPatterns;
  final List<String> trends;
  final List<String> anomalies;
  final List<String> insights;
  final double confidence;

  PurchasePatternAnalysis({
    required this.dayPatterns,
    required this.categoryPatterns,
    required this.trends,
    required this.anomalies,
    required this.insights,
    required this.confidence,
  });
}
