import 'package:tflite_flutter/tflite_flutter.dart';
import 'datos.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/venta.dart';
import 'package:stockcito/models/ml_prediction_models.dart';
import 'package:stockcito/services/ml/ml_prediction_engine.dart';

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  final DatosService _datosService = DatosService();
  final MLPredictionEngine _predictionEngine = MLPredictionEngine();
  
  // Modelos de TensorFlow Lite (para futuras implementaciones)
  Interpreter? _demandModel;
  Interpreter? _priceModel;
  Interpreter? _customerModel;
  
  // Estado del servicio
  bool _isInitialized = false;
  DateTime? _lastModelUpdate;
  

  /// Inicializa los modelos de ML
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando servicio de Machine Learning');
      
      // Inicializar servicios de análisis estadístico
      await _initializeStatisticalServices();
      
      // Cargar modelos TensorFlow Lite (si están disponibles)
      await _loadTensorFlowModels();
      
      _isInitialized = true;
      _lastModelUpdate = DateTime.now();
      
      LoggingService.info('✅ Servicio de ML inicializado correctamente');
      
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicio de ML: $e');
      // Continuar sin modelos TensorFlow si hay error
      _isInitialized = true;
    }
  }

  /// Inicializa servicios de análisis estadístico
  Future<void> _initializeStatisticalServices() async {
    try {
      LoggingService.info('📊 Inicializando servicios de análisis estadístico');
      
      // Los servicios estadísticos son singletons y se inicializan automáticamente
      // No requieren inicialización adicional
      
      LoggingService.info('✅ Servicios estadísticos listos');
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicios estadísticos: $e');
      rethrow;
    }
  }

  /// Carga los modelos de TensorFlow Lite (opcional)
  Future<void> _loadTensorFlowModels() async {
    try {
      LoggingService.info('🤖 Intentando cargar modelos TensorFlow Lite...');
      
      // Intentar cargar modelos disponibles
      try {
        _demandModel = await Interpreter.fromAsset('models/demand_model.tflite');
        LoggingService.info('✅ Modelo de demanda cargado exitosamente');
      } catch (e) {
        LoggingService.warning('⚠️ Modelo de demanda no disponible: $e');
        _demandModel = null;
      }
      
      try {
        _priceModel = await Interpreter.fromAsset('models/price_model.tflite');
        LoggingService.info('✅ Modelo de precios cargado exitosamente');
      } catch (e) {
        LoggingService.warning('⚠️ Modelo de precios no disponible: $e');
        _priceModel = null;
      }
      
      try {
        _customerModel = await Interpreter.fromAsset('models/customer_model.tflite');
        LoggingService.info('✅ Modelo de clientes cargado exitosamente');
      } catch (e) {
        LoggingService.warning('⚠️ Modelo de clientes no disponible: $e');
        _customerModel = null;
      }
      
      // Verificar si al menos un modelo se cargó
      final modelosCargados = [_demandModel, _priceModel, _customerModel].where((m) => m != null).length;
      
      if (modelosCargados > 0) {
        LoggingService.info('✅ $modelosCargados modelos TensorFlow Lite cargados exitosamente');
      } else {
        LoggingService.info('ℹ️ Ningún modelo TensorFlow Lite disponible - usando análisis estadístico');
      }
      
    } catch (e) {
      LoggingService.warning('⚠️ Error general cargando modelos TensorFlow: $e');
      // Continuar sin modelos TensorFlow
    }
  }

  /// Predice la demanda de un producto usando ML real
  Future<MLDemandPrediction> predictDemandML(int productoId, int daysAhead) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      LoggingService.info('🔮 Prediciendo demanda real para producto $productoId');
      
      // Obtener datos históricos
      final ventas = await _getProductSalesHistory(productoId);
      final producto = await _getProductById(productoId);
      
      if (ventas.isEmpty || producto == null) {
        LoggingService.warning('⚠️ Sin datos suficientes para producto $productoId');
        return MLDemandPrediction(
          productoId: productoId,
          predictedDemand: 0,
          confidence: 0.0,
          factors: ['Sin datos históricos suficientes'],
          recommendation: 'Agregar más datos para predicción precisa',
          predictionDate: DateTime.now(),
          featureImportance: {},
          seasonalFactor: 1.0,
          trendFactor: 0.0,
          daysAhead: daysAhead,
        );
      }

      // Usar el motor de predicción real
      final prediction = _predictionEngine.predictDemand(ventas, producto, daysAhead);
      
      LoggingService.info('✅ Predicción de demanda completada: ${prediction.predictedDemand} unidades (confianza: ${(prediction.confidence * 100).toStringAsFixed(1)}%)');
      
      return prediction;
      
    } catch (e) {
      LoggingService.error('❌ Error en predicción de demanda: $e');
      return MLDemandPrediction(
        productoId: productoId,
        predictedDemand: 0,
        confidence: 0.0,
        factors: ['Error en predicción: $e'],
        recommendation: 'Reintentar más tarde',
        predictionDate: DateTime.now(),
        featureImportance: {},
        seasonalFactor: 1.0,
        trendFactor: 0.0,
        daysAhead: daysAhead,
      );
    }
  }

  /// Predice el precio óptimo usando ML real
  Future<MLPricePrediction> predictOptimalPrice(int productoId) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      LoggingService.info('💰 Prediciendo precio óptimo real para producto $productoId');
      
      final ventas = await _getProductSalesHistory(productoId);
      final producto = await _getProductById(productoId);
      
      if (ventas.isEmpty || producto == null) {
        LoggingService.warning('⚠️ Sin datos suficientes para análisis de precio del producto $productoId');
        return MLPricePrediction(
          productoId: productoId,
          currentPrice: producto?.precioVenta ?? 0,
          optimalPrice: producto?.precioVenta ?? 0,
          confidence: 0.0,
          factors: ['Sin datos suficientes'],
          recommendation: 'Agregar más ventas para análisis',
          predictionDate: DateTime.now(),
          priceElasticity: 0.0,
          demandSensitivity: 0.0,
          marketFactors: {},
        );
      }

      // Usar el motor de predicción real
      final prediction = _predictionEngine.predictOptimalPrice(ventas, producto);
      
      LoggingService.info('✅ Predicción de precio completada: \$${prediction.optimalPrice.toStringAsFixed(2)} (confianza: ${(prediction.confidence * 100).toStringAsFixed(1)}%)');
      
      return prediction;
      
    } catch (e) {
      LoggingService.error('❌ Error en predicción de precio: $e');
      return MLPricePrediction(
        productoId: productoId,
        currentPrice: 0,
        optimalPrice: 0,
        confidence: 0.0,
        factors: ['Error en predicción: $e'],
        recommendation: 'Reintentar más tarde',
        predictionDate: DateTime.now(),
        priceElasticity: 0.0,
        demandSensitivity: 0.0,
        marketFactors: {},
      );
    }
  }

  /// Analiza patrones de clientes usando ML real
  Future<MLCustomerAnalysis> analyzeCustomerPatterns() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      LoggingService.info('👥 Analizando patrones de clientes reales');
      
      final ventas = await _datosService.getAllVentas();
      final clientes = await _datosService.getAllClientes();
      
      if (ventas.isEmpty || clientes.isEmpty) {
        LoggingService.warning('⚠️ Sin datos suficientes para análisis de clientes');
        return MLCustomerAnalysis(
          totalCustomers: clientes.length,
          segments: [],
          insights: ['Sin datos de clientes suficientes'],
          recommendations: ['Agregar más ventas para análisis'],
          analysisDate: DateTime.now(),
          segmentMetrics: {},
          customerLifetimeValue: 0.0,
          retentionRate: 0.0,
        );
      }

      // Usar el motor de predicción real
      final analysis = _predictionEngine.analyzeCustomerPatterns(ventas, clientes);
      
      LoggingService.info('✅ Análisis de clientes completado: ${analysis.segments.length} segmentos identificados');
      
      return analysis;
      
    } catch (e) {
      LoggingService.error('❌ Error en análisis de clientes: $e');
      return MLCustomerAnalysis(
        totalCustomers: 0,
        segments: [],
        insights: ['Error en análisis: $e'],
        recommendations: ['Reintentar más tarde'],
        analysisDate: DateTime.now(),
        segmentMetrics: {},
        customerLifetimeValue: 0.0,
        retentionRate: 0.0,
      );
    }
  }

  // Métodos auxiliares para obtener datos
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

  /// Obtiene métricas de rendimiento del servicio ML
  Map<String, dynamic> getServiceMetrics() {
    return {
      'is_initialized': _isInitialized,
      'last_model_update': _lastModelUpdate?.toIso8601String(),
      'tensorflow_models_available': _demandModel != null && _priceModel != null && _customerModel != null,
      'prediction_engine_ready': true,
      'statistical_services_ready': true,
    };
  }

  /// Valida si hay suficientes datos para predicciones confiables
  bool hasEnoughDataForPrediction(List<Venta> ventas, int minVentas) {
    return ventas.length >= minVentas;
  }

  /// Obtiene estadísticas de calidad de datos
  Map<String, dynamic> getDataQualityStats(List<Venta> ventas) {
    if (ventas.isEmpty) {
      return {
        'total_ventas': 0,
        'data_quality_score': 0.0,
        'recommendations': ['Agregar más datos de ventas'],
      };
    }

    final now = DateTime.now();
    final ventasRecientes = ventas.where((v) => 
      v.fecha.isAfter(now.subtract(const Duration(days: 30)))
    ).length;

    final dataQualityScore = (ventasRecientes / ventas.length).clamp(0.0, 1.0);
    
    final recommendations = <String>[];
    if (dataQualityScore < 0.5) {
      recommendations.add('Datos históricos desactualizados');
    }
    if (ventas.length < 10) {
      recommendations.add('Necesitas más ventas para predicciones confiables');
    }

    return {
      'total_ventas': ventas.length,
      'ventas_recientes_30d': ventasRecientes,
      'data_quality_score': dataQualityScore,
      'recommendations': recommendations,
    };
  }

  void dispose() {
    _demandModel?.close();
    _priceModel?.close();
    _customerModel?.close();
  }
}
