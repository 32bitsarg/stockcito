import 'dart:math';
import '../system/logging_service.dart';
import '../../models/venta.dart';
import 'ml_data_validation_service.dart';

/// Servicio para análisis estadístico real sin simulaciones
class StatisticalAnalysisService {
  static final StatisticalAnalysisService _instance = StatisticalAnalysisService._internal();
  factory StatisticalAnalysisService() => _instance;
  StatisticalAnalysisService._internal();
  
  final MLDataValidationService _validationService = MLDataValidationService();

  /// Calcula la tendencia de ventas usando regresión lineal
  double calculateSalesTrend(List<Venta> ventas, int days) {
    if (ventas.length < 2) return 0.0;

    try {
      // Agrupar ventas por día
      final Map<int, int> dailySales = {};
      final now = DateTime.now();
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dayKey = date.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
        dailySales[dayKey] = 0;
      }

      // Contar ventas por día
      for (final venta in ventas) {
        final dayKey = venta.fecha.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
        if (dailySales.containsKey(dayKey)) {
          dailySales[dayKey] = dailySales[dayKey]! + 1;
        }
      }

      // Calcular regresión lineal
      final sortedDays = dailySales.keys.toList()..sort();
      final xValues = <double>[];
      final yValues = <double>[];

      for (int i = 0; i < sortedDays.length; i++) {
        xValues.add(i.toDouble());
        yValues.add(dailySales[sortedDays[i]]!.toDouble());
      }

      return _calculateLinearRegressionSlope(xValues, yValues);
    } catch (e) {
      LoggingService.error('Error calculando tendencia de ventas: $e');
      return 0.0;
    }
  }

  /// Calcula la elasticidad de precio real
  double calculatePriceElasticity(List<Venta> ventas, double currentPrice) {
    if (ventas.length < 10) return 0.0;

    try {
      // Agrupar ventas por precio (con tolerancia)
      final Map<double, List<Venta>> priceGroups = {};
      const double priceTolerance = 0.05; // 5% de tolerancia

      for (final venta in ventas) {
        final price = venta.total / venta.items.fold(0, (sum, item) => sum + item.cantidad);
        final roundedPrice = _roundToNearest(price, priceTolerance);
        
        priceGroups[roundedPrice] = priceGroups[roundedPrice] ?? [];
        priceGroups[roundedPrice]!.add(venta);
      }

      if (priceGroups.length < 2) return 0.0;

      // Calcular elasticidad usando fórmula: E = (ΔQ/Q) / (ΔP/P)
      final sortedPrices = priceGroups.keys.toList()..sort();
      double totalElasticity = 0.0;
      int elasticityCount = 0;

      for (int i = 1; i < sortedPrices.length; i++) {
        final price1 = sortedPrices[i - 1];
        final price2 = sortedPrices[i];
        final quantity1 = priceGroups[price1]!.length.toDouble();
        final quantity2 = priceGroups[price2]!.length.toDouble();

        if (quantity1 > 0 && quantity2 > 0) {
          final priceChange = (price2 - price1) / price1;
          final quantityChange = (quantity2 - quantity1) / quantity1;
          
          if (priceChange != 0) {
            final elasticity = quantityChange / priceChange;
            totalElasticity += elasticity;
            elasticityCount++;
          }
        }
      }

      return elasticityCount > 0 ? totalElasticity / elasticityCount : 0.0;
    } catch (e) {
      LoggingService.error('Error calculando elasticidad de precio: $e');
      return 0.0;
    }
  }

  /// Calcula factores estacionales reales basados en datos históricos
  Map<int, double> calculateSeasonalFactors(List<Venta> ventas) {
    final Map<int, List<int>> monthlySales = {};
    
    // Agrupar ventas por mes
    for (final venta in ventas) {
      final month = venta.fecha.month;
      monthlySales[month] = monthlySales[month] ?? [];
      monthlySales[month]!.add(venta.items.fold(0, (sum, item) => sum + item.cantidad));
    }

    // Calcular promedio mensual
    final Map<int, double> monthlyAverages = {};
    for (final month in monthlySales.keys) {
      final sales = monthlySales[month]!;
      if (_validationService.canUseReduce(sales)) {
        monthlyAverages[month] = _validationService.safeSum(sales.map((v) => v.toDouble()).toList()) / sales.length;
      } else {
        monthlyAverages[month] = 0.0;
      }
    }

    // Calcular promedio general
    if (_validationService.canUseReduce(monthlyAverages.values.toList())) {
      final totalAverage = _validationService.safeSum(monthlyAverages.values.toList()) / monthlyAverages.length;

      // Calcular factores estacionales
      final Map<int, double> seasonalFactors = {};
      for (final month in monthlyAverages.keys) {
        seasonalFactors[month] = monthlyAverages[month]! / totalAverage;
      }

      return seasonalFactors;
    } else {
      // Retornar factores neutros si no hay datos suficientes
      final Map<int, double> seasonalFactors = {};
      for (int month = 1; month <= 12; month++) {
        seasonalFactors[month] = 1.0; // Factor neutro
      }
      return seasonalFactors;
    }
  }

  /// Calcula la demanda promedio por día de la semana
  Map<int, double> calculateWeeklyPattern(List<Venta> ventas) {
    final Map<int, List<int>> weeklySales = {};
    
    for (final venta in ventas) {
      final weekday = venta.fecha.weekday;
      weeklySales[weekday] = weeklySales[weekday] ?? [];
      weeklySales[weekday]!.add(venta.items.fold(0, (sum, item) => sum + item.cantidad));
    }

    final Map<int, double> weeklyAverages = {};
    for (final weekday in weeklySales.keys) {
      final sales = weeklySales[weekday]!;
      if (_validationService.canUseReduce(sales)) {
        weeklyAverages[weekday] = _validationService.safeSum(sales.map((v) => v.toDouble()).toList()) / sales.length;
      } else {
        weeklyAverages[weekday] = 0.0;
      }
    }

    return weeklyAverages;
  }

  /// Calcula la volatilidad de ventas
  double calculateSalesVolatility(List<Venta> ventas, int days) {
    if (ventas.length < 2) return 0.0;

    try {
      // Agrupar ventas por día
      final Map<int, int> dailySales = {};
      final now = DateTime.now();
      
      for (int i = 0; i < days; i++) {
        final date = now.subtract(Duration(days: i));
        final dayKey = date.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
        dailySales[dayKey] = 0;
      }

      for (final venta in ventas) {
        final dayKey = venta.fecha.millisecondsSinceEpoch ~/ (24 * 60 * 60 * 1000);
        if (dailySales.containsKey(dayKey)) {
          dailySales[dayKey] = dailySales[dayKey]! + 1;
        }
      }

      final salesValues = dailySales.values.toList();
      if (!_validationService.canUseReduce(salesValues)) {
        return 0.0;
      }
      
      final mean = _validationService.safeSum(salesValues.map((v) => v.toDouble()).toList()) / salesValues.length;
      
      final variance = salesValues.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / salesValues.length;
      return sqrt(variance) / mean; // Coeficiente de variación
    } catch (e) {
      LoggingService.error('Error calculando volatilidad de ventas: $e');
      return 0.0;
    }
  }

  /// Calcula la correlación entre precio y cantidad vendida
  double calculatePriceQuantityCorrelation(List<Venta> ventas) {
    if (ventas.length < 2) return 0.0;

    try {
      final List<double> prices = [];
      final List<double> quantities = [];

      for (final venta in ventas) {
        final avgPrice = venta.total / venta.items.fold(0, (sum, item) => sum + item.cantidad);
        final totalQuantity = venta.items.fold(0, (sum, item) => sum + item.cantidad);
        
        prices.add(avgPrice);
        quantities.add(totalQuantity.toDouble());
      }

      return _calculateCorrelation(prices, quantities);
    } catch (e) {
      LoggingService.error('Error calculando correlación precio-cantidad: $e');
      return 0.0;
    }
  }

  /// Calcula el valor de vida del cliente (CLV)
  double calculateCustomerLifetimeValue(List<Venta> ventas, List<dynamic> clientes) {
    if (ventas.isEmpty || clientes.isEmpty) return 0.0;

    try {
      // Agrupar ventas por cliente
      final Map<String, List<Venta>> customerSales = {};
      
      for (final venta in ventas) {
        final customerId = venta.id.toString(); // Usar ID de venta como identificador temporal
        customerSales[customerId] = customerSales[customerId] ?? [];
        customerSales[customerId]!.add(venta);
      }

      double totalCLV = 0.0;
      int customerCount = 0;

      for (final customerId in customerSales.keys) {
        final sales = customerSales[customerId]!;
        if (sales.length > 1) {
          // Calcular promedio de compra
          final avgPurchase = _validationService.safeAverage(sales.map((v) => v.total).toList());
          
          // Calcular frecuencia de compra (compras por mes)
          final firstPurchase = _validationService.safeFirst(sales.map((v) => v.fecha).toList());
          final lastPurchase = _validationService.safeLast(sales.map((v) => v.fecha).toList());
          
          if (firstPurchase != null && lastPurchase != null) {
            final monthsActive = lastPurchase.difference(firstPurchase).inDays / 30.0;
            final purchaseFrequency = monthsActive > 0 ? sales.length / monthsActive : 0;
            
            // Calcular CLV: promedio de compra * frecuencia * meses estimados
            final estimatedMonths = 12.0; // Asumir 12 meses de vida del cliente
            final clv = avgPurchase * purchaseFrequency * estimatedMonths;
            
            totalCLV += clv;
            customerCount++;
          }
        }
      }

      return customerCount > 0 ? totalCLV / customerCount : 0.0;
    } catch (e) {
      LoggingService.error('Error calculando CLV: $e');
      return 0.0;
    }
  }

  /// Calcula la tasa de retención de clientes
  double calculateRetentionRate(List<Venta> ventas, List<dynamic> clientes) {
    if (ventas.isEmpty || clientes.isEmpty) return 0.0;

    try {
      final Map<String, List<DateTime>> customerPurchaseDates = {};
      
      for (final venta in ventas) {
        final customerId = venta.id.toString(); // Usar ID de venta como identificador temporal
        customerPurchaseDates[customerId] = customerPurchaseDates[customerId] ?? [];
        customerPurchaseDates[customerId]!.add(venta.fecha);
      }

      int retainedCustomers = 0;
      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(days: 90)); // Últimos 90 días

      for (final customerId in customerPurchaseDates.keys) {
        final purchases = customerPurchaseDates[customerId]!;
        if (purchases.length > 1) {
          // Verificar si el cliente hizo una compra en los últimos 90 días
          final hasRecentPurchase = purchases.any((date) => date.isAfter(cutoffDate));
          if (hasRecentPurchase) {
            retainedCustomers++;
          }
        }
      }

      return customerPurchaseDates.length > 0 ? retainedCustomers / customerPurchaseDates.length : 0.0;
    } catch (e) {
      LoggingService.error('Error calculando tasa de retención: $e');
      return 0.0;
    }
  }

  // Métodos auxiliares privados
  double _calculateLinearRegressionSlope(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length || xValues.length < 2) return 0.0;

    final n = xValues.length;
    final sumX = _validationService.safeSum(xValues);
    final sumY = _validationService.safeSum(yValues);
    final sumXY = xValues.asMap().entries.map((e) => e.value * yValues[e.key]).reduce((a, b) => a + b);
    final sumXX = xValues.map((x) => x * x).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    return slope;
  }

  double _calculateCorrelation(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length || xValues.length < 2) return 0.0;

    final n = xValues.length;
    final sumX = _validationService.safeSum(xValues);
    final sumY = _validationService.safeSum(yValues);
    final sumXY = xValues.asMap().entries.map((e) => e.value * yValues[e.key]).reduce((a, b) => a + b);
    final sumXX = xValues.map((x) => x * x).reduce((a, b) => a + b);
    final sumYY = yValues.map((y) => y * y).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt((n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY));

    return denominator != 0 ? numerator / denominator : 0.0;
  }

  double _roundToNearest(double value, double nearest) {
    return (value / nearest).round() * nearest;
  }
}
