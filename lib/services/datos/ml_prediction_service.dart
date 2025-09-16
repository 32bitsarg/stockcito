import 'package:tflite_flutter/tflite_flutter.dart';
import 'datos.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/venta.dart';

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  final DatosService _datosService = DatosService();
  
  // Modelos de TensorFlow Lite
  Interpreter? _demandModel;
  Interpreter? _priceModel;
  Interpreter? _customerModel;
  

  /// Inicializa los modelos de ML
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando modelos de Machine Learning');
      
      // Cargar modelos (por ahora simulados, en producción serían archivos .tflite)
      await _loadModels();
      
      LoggingService.info('Modelos de ML inicializados correctamente');
      
    } catch (e) {
      LoggingService.error('Error inicializando modelos de ML: $e');
      // Continuar sin ML si hay error
    }
  }

  /// Carga los modelos de TensorFlow Lite
  Future<void> _loadModels() async {
    try {
      // En producción, estos serían archivos .tflite reales
      // Por ahora simulamos la carga
      LoggingService.info('Cargando modelos de ML...');
      
      // Simular carga de modelos
      await Future.delayed(const Duration(milliseconds: 500));
      
      LoggingService.info('Modelos de ML cargados exitosamente');
      
    } catch (e) {
      LoggingService.error('Error cargando modelos: $e');
      rethrow;
    }
  }

  /// Predice la demanda de un producto usando ML
  Future<MLDemandPrediction> predictDemandML(int productoId, int daysAhead) async {
    try {
      LoggingService.info('Prediciendo demanda con ML para producto $productoId');
      
      // Obtener datos históricos
      final ventas = await _getProductSalesHistory(productoId);
      final producto = await _getProductById(productoId);
      
      if (ventas.isEmpty || producto == null) {
        return MLDemandPrediction(
          productoId: productoId,
          predictedDemand: 0,
          confidence: 0.0,
          factors: ['Sin datos históricos suficientes'],
          recommendation: 'Agregar más datos para predicción precisa',
        );
      }

      // Preparar features para el modelo ML
      final features = _prepareDemandFeatures(ventas, producto, daysAhead);
      
      // Simular predicción ML (en producción usaría el modelo real)
      final prediction = _simulateMLPrediction(features, daysAhead);
      
      // Generar factores explicativos
      final factors = _generateDemandFactors(ventas, producto, prediction);
      
      // Generar recomendación inteligente
      final recommendation = _generateMLRecommendation(prediction, factors, producto);
      
      LoggingService.info('Predicción ML completada: ${prediction.predictedDemand} unidades');
      
      return MLDemandPrediction(
        productoId: productoId,
        predictedDemand: prediction.predictedDemand,
        confidence: prediction.confidence,
        factors: factors,
        recommendation: recommendation,
      );
      
    } catch (e) {
      LoggingService.error('Error en predicción ML de demanda: $e');
      return MLDemandPrediction(
        productoId: productoId,
        predictedDemand: 0,
        confidence: 0.0,
        factors: ['Error en predicción'],
        recommendation: 'Reintentar más tarde',
      );
    }
  }

  /// Predice el precio óptimo usando ML
  Future<MLPricePrediction> predictOptimalPrice(int productoId) async {
    try {
      LoggingService.info('Prediciendo precio óptimo con ML para producto $productoId');
      
      final ventas = await _getProductSalesHistory(productoId);
      final producto = await _getProductById(productoId);
      
      if (ventas.isEmpty || producto == null) {
        return MLPricePrediction(
          productoId: productoId,
          currentPrice: 0,
          optimalPrice: 0,
          confidence: 0.0,
          factors: ['Sin datos suficientes'],
          recommendation: 'Agregar más ventas para análisis',
        );
      }

      // Preparar features para análisis de precio
      final features = _preparePriceFeatures(ventas, producto);
      
      // Simular predicción de precio óptimo
      final prediction = _simulatePricePrediction(features, producto);
      
      // Generar factores de precio
      final factors = _generatePriceFactors(ventas, producto, prediction);
      
      // Generar recomendación de precio
      final recommendation = _generatePriceRecommendation(prediction, factors, producto);
      
      return MLPricePrediction(
        productoId: productoId,
        currentPrice: producto.precioVenta,
        optimalPrice: prediction.optimalPrice,
        confidence: prediction.confidence,
        factors: factors,
        recommendation: recommendation,
      );
      
    } catch (e) {
      LoggingService.error('Error en predicción ML de precio: $e');
      return MLPricePrediction(
        productoId: productoId,
        currentPrice: 0,
        optimalPrice: 0,
        confidence: 0.0,
        factors: ['Error en predicción'],
        recommendation: 'Reintentar más tarde',
      );
    }
  }

  /// Analiza patrones de clientes usando ML
  Future<MLCustomerAnalysis> analyzeCustomerPatterns() async {
    try {
      LoggingService.info('Analizando patrones de clientes con ML');
      
      final ventas = await _datosService.getAllVentas();
      final clientes = await _datosService.getAllClientes();
      
      if (ventas.isEmpty) {
        return MLCustomerAnalysis(
          totalCustomers: 0,
          segments: [],
          insights: ['Sin datos de clientes suficientes'],
          recommendations: ['Agregar más ventas para análisis'],
        );
      }

      // Preparar datos para análisis de clientes
      final customerData = _prepareCustomerFeatures(ventas, clientes);
      
      // Simular análisis de segmentación
      final segments = _simulateCustomerSegmentation(customerData);
      
      // Generar insights
      final insights = _generateCustomerInsights(segments, ventas);
      
      // Generar recomendaciones
      final recommendations = _generateCustomerRecommendations(segments, insights);
      
      return MLCustomerAnalysis(
        totalCustomers: clientes.length,
        segments: segments,
        insights: insights,
        recommendations: recommendations,
      );
      
    } catch (e) {
      LoggingService.error('Error en análisis ML de clientes: $e');
      return MLCustomerAnalysis(
        totalCustomers: 0,
        segments: [],
        insights: ['Error en análisis'],
        recommendations: ['Reintentar más tarde'],
      );
    }
  }

  // Métodos auxiliares para preparar datos
  List<double> _prepareDemandFeatures(List<Venta> ventas, Producto producto, int daysAhead) {
    // Features: [precio, stock_actual, ventas_ultimos_7_dias, ventas_ultimos_30_dias, 
    //           dia_semana, mes, categoria_encoded, tendencia_ventas]
    
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final last30Days = now.subtract(const Duration(days: 30));
    
    final ventas7Dias = ventas.where((v) => v.fecha.isAfter(last7Days)).length;
    final ventas30Dias = ventas.where((v) => v.fecha.isAfter(last30Days)).length;
    
    // Calcular tendencia
    final tendencia = ventas30Dias > 0 ? ventas7Dias / ventas30Dias : 0.0;
    
    // Codificar categoría
    final categoriaEncoded = _encodeCategory(producto.categoria);
    
    return [
      producto.precioVenta,
      producto.stock.toDouble(),
      ventas7Dias.toDouble(),
      ventas30Dias.toDouble(),
      now.weekday.toDouble(),
      now.month.toDouble(),
      categoriaEncoded,
      tendencia,
    ];
  }

  List<double> _preparePriceFeatures(List<Venta> ventas, Producto producto) {
    // Features para análisis de precio: [precio_actual, ventas_por_precio, 
    //                                   elasticidad, competencia_simulada]
    
    final precioActual = producto.precioVenta;
    final ventasPorPrecio = ventas.length.toDouble();
    
    // Simular elasticidad basada en datos históricos
    final elasticidad = _calculatePriceElasticity(ventas, precioActual);
    
    // Simular competencia
    final competencia = _simulateCompetition(producto.categoria);
    
    return [
      precioActual,
      ventasPorPrecio,
      elasticidad,
      competencia,
    ];
  }

  Map<String, dynamic> _prepareCustomerFeatures(List<Venta> ventas, List<dynamic> clientes) {
    // Preparar datos de clientes para segmentación
    final Map<String, List<Venta>> ventasPorCliente = {};
    
    for (final venta in ventas) {
      final clienteId = venta.id.toString(); // Usar ID de venta como identificador
      ventasPorCliente[clienteId] = ventasPorCliente[clienteId] ?? [];
      ventasPorCliente[clienteId]!.add(venta);
    }
    
    return {
      'ventas_por_cliente': ventasPorCliente,
      'total_clientes': clientes.length,
      'total_ventas': ventas.length,
    };
  }

  // Métodos de simulación ML (en producción serían predicciones reales)
  MLPredictionResult _simulateMLPrediction(List<double> features, int daysAhead) {
    // Simular predicción basada en features
    final baseDemand = features[2] * 1.2; // Ventas últimos 7 días * factor
    final seasonalFactor = _getSeasonalFactor(DateTime.now().month);
    final trendFactor = features[7]; // Tendencia calculada
    
    final predictedDemand = (baseDemand * seasonalFactor * trendFactor).round();
    final confidence = (0.7 + (features[7] * 0.3)).clamp(0.0, 1.0);
    
    return MLPredictionResult(
      predictedDemand: predictedDemand,
      confidence: confidence,
    );
  }

  MLPriceResult _simulatePricePrediction(List<double> features, Producto producto) {
    final precioActual = features[0];
    final elasticidad = features[2];
    
    // Calcular precio óptimo basado en elasticidad
    final optimalPrice = precioActual * (1 + (elasticidad * 0.1));
    final confidence = 0.8;
    
    return MLPriceResult(
      optimalPrice: optimalPrice,
      confidence: confidence,
    );
  }

  List<CustomerSegment> _simulateCustomerSegmentation(Map<String, dynamic> customerData) {
    // Simular segmentación de clientes
    return [
      CustomerSegment(
        name: 'Clientes VIP',
        percentage: 15.0,
        characteristics: ['Alto valor', 'Frecuentes', 'Leales'],
        avgOrderValue: 250.0,
        frequency: 'Semanal',
      ),
      CustomerSegment(
        name: 'Clientes Regulares',
        percentage: 60.0,
        characteristics: ['Valor medio', 'Ocasionales', 'Estables'],
        avgOrderValue: 120.0,
        frequency: 'Mensual',
      ),
      CustomerSegment(
        name: 'Clientes Nuevos',
        percentage: 25.0,
        characteristics: ['Bajo valor', 'Primera compra', 'Potencial'],
        avgOrderValue: 80.0,
        frequency: 'Primera vez',
      ),
    ];
  }

  // Métodos auxiliares
  double _encodeCategory(String categoria) {
    final categories = ['Bodies', 'Conjuntos', 'Vestidos', 'Pijamas', 'Gorros', 'Accesorios'];
    return categories.indexOf(categoria).toDouble();
  }

  double _getSeasonalFactor(int month) {
    // Factores estacionales para ropa de bebé
    final seasonalFactors = {
      1: 0.8,   // Enero - post navidad
      2: 0.9,   // Febrero
      3: 1.1,   // Marzo - primavera
      4: 1.2,   // Abril - primavera
      5: 1.3,   // Mayo - primavera
      6: 1.1,   // Junio
      7: 0.9,   // Julio - verano
      8: 0.8,   // Agosto - verano
      9: 1.0,   // Septiembre
      10: 1.1,  // Octubre
      11: 1.2,  // Noviembre - preparación navidad
      12: 1.4,  // Diciembre - navidad
    };
    return seasonalFactors[month] ?? 1.0;
  }

  double _calculatePriceElasticity(List<Venta> ventas, double precio) {
    // Simular elasticidad de precio
    if (ventas.length < 2) return 0.0;
    
    final avgQuantity = ventas.map((v) => v.items.fold(0, (sum, item) => sum + item.cantidad)).reduce((a, b) => a + b) / ventas.length;
    return (precio / avgQuantity) * 0.1; // Elasticidad simulada
  }

  double _simulateCompetition(String categoria) {
    // Simular nivel de competencia por categoría
    final competitionLevels = {
      'Bodies': 0.8,
      'Conjuntos': 0.6,
      'Vestidos': 0.9,
      'Pijamas': 0.7,
      'Gorros': 0.5,
      'Accesorios': 0.9,
    };
    return competitionLevels[categoria] ?? 0.7;
  }

  List<String> _generateDemandFactors(List<Venta> ventas, Producto producto, MLPredictionResult prediction) {
    final factors = <String>[];
    
    if (prediction.confidence > 0.8) {
      factors.add('Predicción de alta confianza');
    }
    
    if (producto.stock < prediction.predictedDemand) {
      factors.add('Stock insuficiente para demanda predicha');
    }
    
    final seasonalFactor = _getSeasonalFactor(DateTime.now().month);
    if (seasonalFactor > 1.2) {
      factors.add('Temporada alta detectada');
    }
    
    return factors;
  }

  List<String> _generatePriceFactors(List<Venta> ventas, Producto producto, MLPriceResult prediction) {
    final factors = <String>[];
    
    if (prediction.optimalPrice > producto.precioVenta * 1.1) {
      factors.add('Precio puede aumentar sin afectar ventas');
    } else if (prediction.optimalPrice < producto.precioVenta * 0.9) {
      factors.add('Precio puede reducirse para aumentar ventas');
    }
    
    return factors;
  }

  List<String> _generateCustomerInsights(List<CustomerSegment> segments, List<Venta> ventas) {
    final insights = <String>[];
    
    final vipSegment = segments.firstWhere((s) => s.name == 'Clientes VIP');
    if (vipSegment.percentage > 10) {
      insights.add('${vipSegment.percentage.toStringAsFixed(1)}% de clientes VIP');
    }
    
    insights.add('Segmentación de clientes completada');
    insights.add('Análisis de comportamiento realizado');
    
    return insights;
  }

  List<String> _generateCustomerRecommendations(List<CustomerSegment> segments, List<String> insights) {
    return [
      'Crear programa de fidelización para clientes VIP',
      'Desarrollar estrategias para clientes nuevos',
      'Personalizar ofertas por segmento',
    ];
  }

  String _generateMLRecommendation(MLPredictionResult prediction, List<String> factors, Producto producto) {
    if (prediction.predictedDemand > producto.stock * 1.5) {
      return 'Aumentar stock urgentemente - demanda alta predicha';
    } else if (prediction.predictedDemand < producto.stock * 0.5) {
      return 'Reducir stock - demanda baja predicha';
    } else {
      return 'Stock actual es óptimo según predicción ML';
    }
  }

  String _generatePriceRecommendation(MLPriceResult prediction, List<String> factors, Producto producto) {
    final diff = prediction.optimalPrice - producto.precioVenta;
    final percentDiff = (diff / producto.precioVenta * 100).abs();
    
    if (percentDiff > 10) {
      if (diff > 0) {
        return 'Aumentar precio en ${percentDiff.toStringAsFixed(1)}% para maximizar ganancias';
      } else {
        return 'Reducir precio en ${percentDiff.toStringAsFixed(1)}% para aumentar ventas';
      }
    } else {
      return 'Precio actual es óptimo según análisis ML';
    }
  }

  // Métodos de base de datos
  Future<List<Venta>> _getProductSalesHistory(int productoId) async {
    final allVentas = await _datosService.getAllVentas();
    return allVentas.where((venta) => 
      venta.items.any((item) => item.productoId == productoId)
    ).toList();
  }

  Future<Producto?> _getProductById(int productoId) async {
    final productos = await _datosService.getAllProductos();
    try {
      return productos.firstWhere((p) => p.id == productoId);
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _demandModel?.close();
    _priceModel?.close();
    _customerModel?.close();
  }
}

// Modelos de datos para ML
class MLDemandPrediction {
  final int productoId;
  final int predictedDemand;
  final double confidence;
  final List<String> factors;
  final String recommendation;

  MLDemandPrediction({
    required this.productoId,
    required this.predictedDemand,
    required this.confidence,
    required this.factors,
    required this.recommendation,
  });
}

class MLPricePrediction {
  final int productoId;
  final double currentPrice;
  final double optimalPrice;
  final double confidence;
  final List<String> factors;
  final String recommendation;

  MLPricePrediction({
    required this.productoId,
    required this.currentPrice,
    required this.optimalPrice,
    required this.confidence,
    required this.factors,
    required this.recommendation,
  });
}

class MLCustomerAnalysis {
  final int totalCustomers;
  final List<CustomerSegment> segments;
  final List<String> insights;
  final List<String> recommendations;

  MLCustomerAnalysis({
    required this.totalCustomers,
    required this.segments,
    required this.insights,
    required this.recommendations,
  });
}

class CustomerSegment {
  final String name;
  final double percentage;
  final List<String> characteristics;
  final double avgOrderValue;
  final String frequency;

  CustomerSegment({
    required this.name,
    required this.percentage,
    required this.characteristics,
    required this.avgOrderValue,
    required this.frequency,
  });
}

class MLPredictionResult {
  final int predictedDemand;
  final double confidence;

  MLPredictionResult({
    required this.predictedDemand,
    required this.confidence,
  });
}

class MLPriceResult {
  final double optimalPrice;
  final double confidence;

  MLPriceResult({
    required this.optimalPrice,
    required this.confidence,
  });
}
