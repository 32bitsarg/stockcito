import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';

/// Servicio para métricas de calidad de datos ML
/// Evalúa la calidad y confiabilidad de los datos para entrenamiento
class DataQualityMetricsService {
  static final DataQualityMetricsService _instance = DataQualityMetricsService._internal();
  factory DataQualityMetricsService() => _instance;
  DataQualityMetricsService._internal();

  /// Calcula métricas de calidad para productos
  Map<String, dynamic> calculateProductQualityMetrics(List<Producto> productos) {
    try {
      if (productos.isEmpty) {
        return _createEmptyMetrics('productos');
      }

      final metrics = <String, dynamic>{};
      
      // Métricas básicas
      metrics['total_count'] = productos.length;
      metrics['completeness_score'] = _calculateCompletenessScore(productos);
      metrics['consistency_score'] = _calculateConsistencyScore(productos);
      metrics['accuracy_score'] = _calculateAccuracyScore(productos);
      
      // Métricas de distribución
      metrics['price_distribution'] = _calculatePriceDistribution(productos);
      metrics['category_distribution'] = _calculateCategoryDistribution(productos);
      metrics['size_distribution'] = _calculateSizeDistribution(productos);
      
      // Métricas de calidad específicas
      metrics['data_quality_issues'] = _identifyProductQualityIssues(productos);
      metrics['recommendations'] = _generateProductQualityRecommendations(productos, metrics);
      
      // Score general de calidad
      metrics['overall_quality_score'] = _calculateOverallQualityScore(metrics);
      
      LoggingService.info('📊 Métricas de calidad de productos calculadas: ${metrics['overall_quality_score']}');
      return metrics;
      
    } catch (e) {
      LoggingService.error('Error calculando métricas de calidad de productos: $e');
      return _createEmptyMetrics('productos');
    }
  }

  /// Calcula métricas de calidad para ventas
  Map<String, dynamic> calculateSalesQualityMetrics(List<Venta> ventas) {
    try {
      if (ventas.isEmpty) {
        return _createEmptyMetrics('ventas');
      }

      final metrics = <String, dynamic>{};
      
      // Métricas básicas
      metrics['total_count'] = ventas.length;
      metrics['completeness_score'] = _calculateSalesCompletenessScore(ventas);
      metrics['consistency_score'] = _calculateSalesConsistencyScore(ventas);
      metrics['accuracy_score'] = _calculateSalesAccuracyScore(ventas);
      
      // Métricas temporales
      metrics['temporal_coverage'] = _calculateTemporalCoverage(ventas);
      metrics['seasonality_patterns'] = _calculateSeasonalityPatterns(ventas);
      metrics['trend_stability'] = _calculateTrendStability(ventas);
      
      // Métricas de calidad específicas
      metrics['data_quality_issues'] = _identifySalesQualityIssues(ventas);
      metrics['recommendations'] = _generateSalesQualityRecommendations(ventas, metrics);
      
      // Score general de calidad
      metrics['overall_quality_score'] = _calculateOverallQualityScore(metrics);
      
      LoggingService.info('📊 Métricas de calidad de ventas calculadas: ${metrics['overall_quality_score']}');
      return metrics;
      
    } catch (e) {
      LoggingService.error('Error calculando métricas de calidad de ventas: $e');
      return _createEmptyMetrics('ventas');
    }
  }

  /// Calcula métricas de calidad para clientes
  Map<String, dynamic> calculateCustomerQualityMetrics(List<Cliente> clientes) {
    try {
      if (clientes.isEmpty) {
        return _createEmptyMetrics('clientes');
      }

      final metrics = <String, dynamic>{};
      
      // Métricas básicas
      metrics['total_count'] = clientes.length;
      metrics['completeness_score'] = _calculateCustomerCompletenessScore(clientes);
      metrics['consistency_score'] = _calculateCustomerConsistencyScore(clientes);
      metrics['accuracy_score'] = _calculateCustomerAccuracyScore(clientes);
      
      // Métricas de datos personales
      metrics['contact_info_completeness'] = _calculateContactInfoCompleteness(clientes);
      metrics['data_privacy_score'] = _calculateDataPrivacyScore(clientes);
      
      // Métricas de calidad específicas
      metrics['data_quality_issues'] = _identifyCustomerQualityIssues(clientes);
      metrics['recommendations'] = _generateCustomerQualityRecommendations(clientes, metrics);
      
      // Score general de calidad
      metrics['overall_quality_score'] = _calculateOverallQualityScore(metrics);
      
      LoggingService.info('📊 Métricas de calidad de clientes calculadas: ${metrics['overall_quality_score']}');
      return metrics;
      
    } catch (e) {
      LoggingService.error('Error calculando métricas de calidad de clientes: $e');
      return _createEmptyMetrics('clientes');
    }
  }

  /// Calcula métricas de calidad generales del dataset
  Map<String, dynamic> calculateOverallQualityMetrics({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
  }) {
    try {
      final metrics = <String, dynamic>{};
      
      // Métricas individuales
      final productMetrics = calculateProductQualityMetrics(productos);
      final salesMetrics = calculateSalesQualityMetrics(ventas);
      final customerMetrics = calculateCustomerQualityMetrics(clientes);
      
      metrics['product_metrics'] = productMetrics;
      metrics['sales_metrics'] = salesMetrics;
      metrics['customer_metrics'] = customerMetrics;
      
      // Métricas de integridad referencial
      metrics['referential_integrity'] = _calculateReferentialIntegrity(productos, ventas, clientes);
      
      // Métricas de cobertura temporal
      metrics['temporal_coverage'] = _calculateOverallTemporalCoverage(ventas);
      
      // Score general de calidad del dataset
      final overallScore = _calculateDatasetOverallScore(productMetrics, salesMetrics, customerMetrics);
      metrics['dataset_quality_score'] = overallScore;
      
      // Recomendaciones generales
      metrics['overall_recommendations'] = _generateOverallRecommendations(
        productMetrics, 
        salesMetrics, 
        customerMetrics, 
        overallScore
      );
      
      LoggingService.info('📊 Métricas de calidad generales calculadas: $overallScore');
      return metrics;
      
    } catch (e) {
      LoggingService.error('Error calculando métricas de calidad generales: $e');
      return {'error': e.toString()};
    }
  }

  // ==================== MÉTODOS AUXILIARES PARA PRODUCTOS ====================

  double _calculateCompletenessScore(List<Producto> productos) {
    if (productos.isEmpty) return 0.0;
    
    int totalFields = productos.length * 6; // 6 campos obligatorios
    int completedFields = 0;
    
    for (final producto in productos) {
      if (producto.nombre.isNotEmpty) completedFields++;
      if (producto.categoria.isNotEmpty) completedFields++;
      if (producto.talla.isNotEmpty) completedFields++;
      if (producto.costoMateriales > 0) completedFields++;
      if (producto.costoManoObra > 0) completedFields++;
      if (producto.precioVenta > 0) completedFields++;
    }
    
    return completedFields / totalFields;
  }

  double _calculateConsistencyScore(List<Producto> productos) {
    if (productos.length < 2) return 1.0;
    
    // Verificar consistencia en precios (no deberían ser negativos)
    final negativePrices = productos.where((p) => p.precioVenta <= 0).length;
    final priceConsistency = 1.0 - (negativePrices / productos.length);
    
    // Verificar consistencia en costos
    final invalidCosts = productos.where((p) => 
      p.costoMateriales < 0 || p.costoManoObra < 0 || p.gastosGenerales < 0
    ).length;
    final costConsistency = 1.0 - (invalidCosts / productos.length);
    
    return (priceConsistency + costConsistency) / 2;
  }

  double _calculateAccuracyScore(List<Producto> productos) {
    if (productos.isEmpty) return 0.0;
    
    // Verificar que los precios sean razonables (mayores que costos)
    int accuratePrices = 0;
    
    for (final producto in productos) {
      final totalCost = producto.costoMateriales + producto.costoManoObra + producto.gastosGenerales;
      if (producto.precioVenta > totalCost) {
        accuratePrices++;
      }
    }
    
    return accuratePrices / productos.length;
  }

  Map<String, dynamic> _calculatePriceDistribution(List<Producto> productos) {
    if (productos.isEmpty) return {};
    
    final prices = productos.map((p) => p.precioVenta).toList();
    prices.sort();
    
    return {
      'min': prices.first,
      'max': prices.last,
      'mean': prices.reduce((a, b) => a + b) / prices.length,
      'median': prices[prices.length ~/ 2],
      'std_dev': _calculateStandardDeviation(prices),
    };
  }

  Map<String, dynamic> _calculateCategoryDistribution(List<Producto> productos) {
    final categoryCount = <String, int>{};
    for (final producto in productos) {
      categoryCount[producto.categoria] = (categoryCount[producto.categoria] ?? 0) + 1;
    }
    
    return {
      'categories': categoryCount,
      'most_common': categoryCount.entries.isNotEmpty 
          ? categoryCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'diversity_score': categoryCount.length / productos.length,
    };
  }

  Map<String, dynamic> _calculateSizeDistribution(List<Producto> productos) {
    final sizeCount = <String, int>{};
    for (final producto in productos) {
      sizeCount[producto.talla] = (sizeCount[producto.talla] ?? 0) + 1;
    }
    
    return {
      'sizes': sizeCount,
      'most_common': sizeCount.entries.isNotEmpty 
          ? sizeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
      'diversity_score': sizeCount.length / productos.length,
    };
  }

  List<String> _identifyProductQualityIssues(List<Producto> productos) {
    final issues = <String>[];
    
    // Verificar productos con precios inválidos
    final invalidPrices = productos.where((p) => p.precioVenta <= 0).length;
    if (invalidPrices > 0) {
      issues.add('$invalidPrices productos con precios inválidos');
    }
    
    // Verificar productos con costos inválidos
    final invalidCosts = productos.where((p) => 
      p.costoMateriales < 0 || p.costoManoObra < 0 || p.gastosGenerales < 0
    ).length;
    if (invalidCosts > 0) {
      issues.add('$invalidCosts productos con costos inválidos');
    }
    
    // Verificar productos con nombres vacíos
    final emptyNames = productos.where((p) => p.nombre.isEmpty).length;
    if (emptyNames > 0) {
      issues.add('$emptyNames productos sin nombre');
    }
    
    // Verificar productos con precios menores a costos
    final unprofitableProducts = productos.where((p) => 
      p.precioVenta <= (p.costoMateriales + p.costoManoObra + p.gastosGenerales)
    ).length;
    if (unprofitableProducts > 0) {
      issues.add('$unprofitableProducts productos no rentables');
    }
    
    return issues;
  }

  List<String> _generateProductQualityRecommendations(List<Producto> productos, Map<String, dynamic> metrics) {
    final recommendations = <String>[];
    
    if (metrics['completeness_score'] < 0.8) {
      recommendations.add('Completar información faltante en productos');
    }
    
    if (metrics['consistency_score'] < 0.9) {
      recommendations.add('Revisar consistencia de precios y costos');
    }
    
    if (metrics['accuracy_score'] < 0.8) {
      recommendations.add('Verificar que los precios sean mayores que los costos');
    }
    
    final categoryDist = metrics['category_distribution'] as Map<String, dynamic>;
    if (categoryDist['diversity_score'] < 0.3) {
      recommendations.add('Considerar diversificar categorías de productos');
    }
    
    return recommendations;
  }

  // ==================== MÉTODOS AUXILIARES PARA VENTAS ====================

  double _calculateSalesCompletenessScore(List<Venta> ventas) {
    if (ventas.isEmpty) return 0.0;
    
    int totalFields = ventas.length * 4; // 4 campos obligatorios
    int completedFields = 0;
    
    for (final venta in ventas) {
      if (venta.total > 0) completedFields++;
      completedFields++; // fecha siempre existe
      if (venta.metodoPago.isNotEmpty) completedFields++;
      if (venta.items.isNotEmpty) completedFields++;
    }
    
    return completedFields / totalFields;
  }

  double _calculateSalesConsistencyScore(List<Venta> ventas) {
    if (ventas.length < 2) return 1.0;
    
    // Verificar consistencia en totales
    final invalidTotals = ventas.where((v) => v.total <= 0).length;
    final totalConsistency = 1.0 - (invalidTotals / ventas.length);
    
    // Verificar consistencia en fechas
    final invalidDates = ventas.where((v) => 
      v.fecha.isAfter(DateTime.now()) || 
      v.fecha.isBefore(DateTime(2020))
    ).length;
    final dateConsistency = 1.0 - (invalidDates / ventas.length);
    
    return (totalConsistency + dateConsistency) / 2;
  }

  double _calculateSalesAccuracyScore(List<Venta> ventas) {
    if (ventas.isEmpty) return 0.0;
    
    // Verificar que el total coincida con la suma de items
    int accurateTotals = 0;
    
    for (final venta in ventas) {
      final calculatedTotal = venta.items.fold(0.0, (sum, item) => 
        sum + (item.precioUnitario * item.cantidad)
      );
      if ((venta.total - calculatedTotal).abs() < 0.01) {
        accurateTotals++;
      }
    }
    
    return accurateTotals / ventas.length;
  }

  Map<String, dynamic> _calculateTemporalCoverage(List<Venta> ventas) {
    if (ventas.isEmpty) return {};
    
    final dates = ventas.map((v) => v.fecha).toList();
    dates.sort();
    
    final firstDate = dates.first;
    final lastDate = dates.last;
    final totalDays = lastDate.difference(firstDate).inDays + 1;
    
    // Calcular días con ventas
    final daysWithSales = <DateTime>{};
    for (final date in dates) {
      daysWithSales.add(DateTime(date.year, date.month, date.day));
    }
    
    return {
      'first_sale': firstDate.toIso8601String(),
      'last_sale': lastDate.toIso8601String(),
      'total_days': totalDays,
      'days_with_sales': daysWithSales.length,
      'coverage_percentage': (daysWithSales.length / totalDays) * 100,
    };
  }

  Map<String, dynamic> _calculateSeasonalityPatterns(List<Venta> ventas) {
    if (ventas.isEmpty) return {};
    
    final monthlySales = <int, int>{};
    final weeklySales = <int, int>{};
    
    for (final venta in ventas) {
      monthlySales[venta.fecha.month] = (monthlySales[venta.fecha.month] ?? 0) + 1;
      weeklySales[venta.fecha.weekday] = (weeklySales[venta.fecha.weekday] ?? 0) + 1;
    }
    
    return {
      'monthly_pattern': monthlySales,
      'weekly_pattern': weeklySales,
      'has_seasonality': monthlySales.length > 1,
    };
  }

  double _calculateTrendStability(List<Venta> ventas) {
    if (ventas.length < 10) return 0.0;
    
    // Calcular tendencia usando regresión lineal simple
    final dates = ventas.map((v) => v.fecha.millisecondsSinceEpoch).toList();
    final totals = ventas.map((v) => v.total).toList();
    
    final slope = _calculateLinearRegressionSlope(
      dates.map((d) => d.toDouble()).toList(),
      totals
    );
    
    // La estabilidad es inversamente proporcional a la pendiente
    return (1.0 - slope.abs() / 1000.0).clamp(0.0, 1.0);
  }

  List<String> _identifySalesQualityIssues(List<Venta> ventas) {
    final issues = <String>[];
    
    // Verificar ventas con totales inválidos
    final invalidTotals = ventas.where((v) => v.total <= 0).length;
    if (invalidTotals > 0) {
      issues.add('$invalidTotals ventas con totales inválidos');
    }
    
    // Verificar ventas sin items
    final emptyVentas = ventas.where((v) => v.items.isEmpty).length;
    if (emptyVentas > 0) {
      issues.add('$emptyVentas ventas sin items');
    }
    
    // Verificar ventas con fechas futuras
    final futureVentas = ventas.where((v) => v.fecha.isAfter(DateTime.now())).length;
    if (futureVentas > 0) {
      issues.add('$futureVentas ventas con fechas futuras');
    }
    
    return issues;
  }

  List<String> _generateSalesQualityRecommendations(List<Venta> ventas, Map<String, dynamic> metrics) {
    final recommendations = <String>[];
    
    if (metrics['completeness_score'] < 0.8) {
      recommendations.add('Completar información faltante en ventas');
    }
    
    if (metrics['consistency_score'] < 0.9) {
      recommendations.add('Revisar consistencia de datos de ventas');
    }
    
    if (metrics['accuracy_score'] < 0.8) {
      recommendations.add('Verificar cálculos de totales en ventas');
    }
    
    final temporalCoverage = metrics['temporal_coverage'] as Map<String, dynamic>;
    if (temporalCoverage['coverage_percentage'] < 50) {
      recommendations.add('Mejorar cobertura temporal de ventas');
    }
    
    return recommendations;
  }

  // ==================== MÉTODOS AUXILIARES PARA CLIENTES ====================

  double _calculateCustomerCompletenessScore(List<Cliente> clientes) {
    if (clientes.isEmpty) return 0.0;
    
    int totalFields = clientes.length * 4; // 4 campos principales
    int completedFields = 0;
    
    for (final cliente in clientes) {
      if (cliente.nombre.isNotEmpty) completedFields++;
      if (cliente.telefono.isNotEmpty) completedFields++;
      if (cliente.email.isNotEmpty) completedFields++;
      if (cliente.direccion.isNotEmpty) completedFields++;
    }
    
    return completedFields / totalFields;
  }

  double _calculateCustomerConsistencyScore(List<Cliente> clientes) {
    if (clientes.isEmpty) return 0.0;
    
    // Verificar consistencia en emails
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final validEmails = clientes.where((c) => 
      c.email.isEmpty || emailPattern.hasMatch(c.email)
    ).length;
    
    return validEmails / clientes.length;
  }

  double _calculateCustomerAccuracyScore(List<Cliente> clientes) {
    if (clientes.isEmpty) return 0.0;
    
    // Verificar que no haya clientes duplicados (mismo nombre y teléfono)
    final uniqueClients = <String>{};
    int duplicates = 0;
    
    for (final cliente in clientes) {
      final key = '${cliente.nombre}_${cliente.telefono}';
      if (uniqueClients.contains(key)) {
        duplicates++;
      } else {
        uniqueClients.add(key);
      }
    }
    
    return 1.0 - (duplicates / clientes.length);
  }

  double _calculateContactInfoCompleteness(List<Cliente> clientes) {
    if (clientes.isEmpty) return 0.0;
    
    int clientsWithContact = 0;
    
    for (final cliente in clientes) {
      if (cliente.telefono.isNotEmpty || cliente.email.isNotEmpty) {
        clientsWithContact++;
      }
    }
    
    return clientsWithContact / clientes.length;
  }

  double _calculateDataPrivacyScore(List<Cliente> clientes) {
    if (clientes.isEmpty) return 0.0;
    
    // Verificar que no haya datos sensibles innecesarios
    int clientsWithMinimalData = 0;
    
    for (final cliente in clientes) {
      // Solo nombre es suficiente para identificación básica
      if (cliente.nombre.isNotEmpty && 
          (cliente.telefono.isEmpty || cliente.email.isEmpty || cliente.direccion.isEmpty)) {
        clientsWithMinimalData++;
      }
    }
    
    return clientsWithMinimalData / clientes.length;
  }

  List<String> _identifyCustomerQualityIssues(List<Cliente> clientes) {
    final issues = <String>[];
    
    // Verificar clientes sin nombre
    final unnamedClients = clientes.where((c) => c.nombre.isEmpty).length;
    if (unnamedClients > 0) {
      issues.add('$unnamedClients clientes sin nombre');
    }
    
    // Verificar clientes sin información de contacto
    final clientsWithoutContact = clientes.where((c) => 
      c.telefono.isEmpty && c.email.isEmpty
    ).length;
    if (clientsWithoutContact > 0) {
      issues.add('$clientsWithoutContact clientes sin información de contacto');
    }
    
    // Verificar emails inválidos
    final emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final invalidEmails = clientes.where((c) => 
      c.email.isNotEmpty && !emailPattern.hasMatch(c.email)
    ).length;
    if (invalidEmails > 0) {
      issues.add('$invalidEmails clientes con emails inválidos');
    }
    
    return issues;
  }

  List<String> _generateCustomerQualityRecommendations(List<Cliente> clientes, Map<String, dynamic> metrics) {
    final recommendations = <String>[];
    
    if (metrics['completeness_score'] < 0.7) {
      recommendations.add('Completar información de contacto de clientes');
    }
    
    if (metrics['consistency_score'] < 0.9) {
      recommendations.add('Revisar formato de emails de clientes');
    }
    
    if (metrics['accuracy_score'] < 0.8) {
      recommendations.add('Identificar y eliminar clientes duplicados');
    }
    
    if (metrics['contact_info_completeness'] < 0.8) {
      recommendations.add('Asegurar que todos los clientes tengan información de contacto');
    }
    
    return recommendations;
  }

  // ==================== MÉTODOS AUXILIARES GENERALES ====================

  Map<String, dynamic> _calculateReferentialIntegrity(
    List<Producto> productos,
    List<Venta> ventas,
    List<Cliente> clientes
  ) {
    // Verificar que las ventas referencien productos existentes
    final productIds = productos.map((p) => p.id).toSet();
    int validProductReferences = 0;
    int totalProductReferences = 0;
    
    for (final venta in ventas) {
      for (final item in venta.items) {
        totalProductReferences++;
        if (productIds.contains(item.productoId)) {
          validProductReferences++;
        }
      }
    }
    
    final productIntegrity = totalProductReferences > 0 
        ? validProductReferences / totalProductReferences 
        : 1.0;
    
    return {
      'product_references_valid': productIntegrity,
      'total_product_references': totalProductReferences,
      'valid_product_references': validProductReferences,
    };
  }

  Map<String, dynamic> _calculateOverallTemporalCoverage(List<Venta> ventas) {
    if (ventas.isEmpty) return {};
    
    final dates = ventas.map((v) => v.fecha).toList();
    dates.sort();
    
    final firstDate = dates.first;
    final lastDate = dates.last;
    final totalDays = lastDate.difference(firstDate).inDays + 1;
    
    return {
      'first_date': firstDate.toIso8601String(),
      'last_date': lastDate.toIso8601String(),
      'total_days': totalDays,
      'data_span_months': (totalDays / 30).round(),
    };
  }

  double _calculateDatasetOverallScore(
    Map<String, dynamic> productMetrics,
    Map<String, dynamic> salesMetrics,
    Map<String, dynamic> customerMetrics
  ) {
    final productScore = productMetrics['overall_quality_score'] as double? ?? 0.0;
    final salesScore = salesMetrics['overall_quality_score'] as double? ?? 0.0;
    final customerScore = customerMetrics['overall_quality_score'] as double? ?? 0.0;
    
    // Ponderar según importancia para ML
    return (productScore * 0.4 + salesScore * 0.5 + customerScore * 0.1);
  }

  List<String> _generateOverallRecommendations(
    Map<String, dynamic> productMetrics,
    Map<String, dynamic> salesMetrics,
    Map<String, dynamic> customerMetrics,
    double overallScore
  ) {
    final recommendations = <String>[];
    
    if (overallScore < 0.7) {
      recommendations.add('Calidad general de datos baja - revisar todos los datasets');
    }
    
    final productScore = productMetrics['overall_quality_score'] as double? ?? 0.0;
    if (productScore < 0.8) {
      recommendations.add('Mejorar calidad de datos de productos');
    }
    
    final salesScore = salesMetrics['overall_quality_score'] as double? ?? 0.0;
    if (salesScore < 0.8) {
      recommendations.add('Mejorar calidad de datos de ventas');
    }
    
    final customerScore = customerMetrics['overall_quality_score'] as double? ?? 0.0;
    if (customerScore < 0.7) {
      recommendations.add('Mejorar calidad de datos de clientes');
    }
    
    if (overallScore >= 0.9) {
      recommendations.add('Excelente calidad de datos - listo para entrenamiento ML');
    }
    
    return recommendations;
  }

  double _calculateOverallQualityScore(Map<String, dynamic> metrics) {
    final completeness = metrics['completeness_score'] as double? ?? 0.0;
    final consistency = metrics['consistency_score'] as double? ?? 0.0;
    final accuracy = metrics['accuracy_score'] as double? ?? 0.0;
    
    return (completeness * 0.4 + consistency * 0.3 + accuracy * 0.3);
  }

  Map<String, dynamic> _createEmptyMetrics(String dataType) {
    return {
      'total_count': 0,
      'completeness_score': 0.0,
      'consistency_score': 0.0,
      'accuracy_score': 0.0,
      'overall_quality_score': 0.0,
      'data_quality_issues': ['Sin datos disponibles'],
      'recommendations': ['Agregar datos de $dataType para análisis'],
    };
  }

  double _calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }

  double _calculateLinearRegressionSlope(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length || xValues.length < 2) return 0.0;
    
    final n = xValues.length;
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => xValues[i] * yValues[i]).reduce((a, b) => a + b);
    final sumX2 = List.generate(n, (i) => xValues[i] * xValues[i]).reduce((a, b) => a + b);
    
    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return 0.0;
    
    return (n * sumXY - sumX * sumY) / denominator;
  }
}
