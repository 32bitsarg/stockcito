import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockcito/services/system/logging_service.dart';

class MLPersistenceService {
  static final MLPersistenceService _instance = MLPersistenceService._internal();
  factory MLPersistenceService() => _instance;
  MLPersistenceService._internal();

  SupabaseClient? _supabase;

  // Colecciones de Supabase
  static const String _trainingDataCollection = 'ml_training_data';
  static const String _modelsCollection = 'ml_models';
  static const String _predictionsCollection = 'ml_predictions';
  static const String _insightsCollection = 'ml_insights';

  /// Inicializa Supabase
  Future<void> initialize() async {
    try {
      if (_supabase != null) {
        LoggingService.info('Supabase ya está inicializado');
        return;
      }
      
      LoggingService.info('Inicializando Supabase para persistencia ML');
      _supabase = Supabase.instance.client;
      LoggingService.info('Supabase inicializado correctamente para ML');
    } catch (e) {
      LoggingService.error('Error inicializando Supabase: $e');
      // No rethrow para evitar crashes, solo log
    }
  }

  /// Guarda datos de entrenamiento en Supabase
  Future<void> saveTrainingData(Map<String, dynamic> data) async {
    try {
      if (_supabase == null) await initialize();
      
      await _supabase!.from(_trainingDataCollection).insert({
        'features': data['features'] ?? [],
        'target': data['target'] ?? 0.0,
        'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      
      LoggingService.info('Datos de entrenamiento guardados en Supabase');
    } catch (e) {
      LoggingService.error('Error guardando datos de entrenamiento: $e');
      rethrow;
    }
  }

  /// Carga datos de entrenamiento desde Supabase
  Future<List<Map<String, dynamic>>> loadTrainingData({int limit = 1000}) async {
    try {
      if (_supabase == null) await initialize();
      
      final querySnapshot = await _supabase!
          .from(_trainingDataCollection)
          .select()
          .limit(limit);

      final trainingData = querySnapshot.map((doc) {
        return doc as Map<String, dynamic>;
      }).toList();

      LoggingService.info('${trainingData.length} datos de entrenamiento cargados desde Supabase');
      return trainingData;
    } catch (e) {
      LoggingService.error('Error cargando datos de entrenamiento: $e');
      return [];
    }
  }

  /// Guarda modelo ML en Supabase
  Future<void> saveMLModel(Map<String, dynamic> modelData, String modelId) async {
    try {
      if (_supabase == null) await initialize();
      
      final data = {
        'id': modelId,
        'type': modelData['type'] ?? 'unknown',
        'parameters': modelData['parameters'] ?? {},
        'accuracy': modelData['accuracy'] ?? 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase!
          .from(_modelsCollection)
          .upsert({
            'id': modelId,
            ...data,
          });

      LoggingService.info('Modelo ML $modelId guardado en Supabase');
    } catch (e) {
      LoggingService.error('Error guardando modelo ML: $e');
      rethrow;
    }
  }

  /// Carga modelo ML desde Supabase
  Future<Map<String, dynamic>?> loadMLModel(String modelId) async {
    try {
      if (_supabase == null) await initialize();
      
      final response = await _supabase!
          .from(_modelsCollection)
          .select();

      // Buscar el modelo por ID en la respuesta
      Map<String, dynamic>? data;
      for (final item in response) {
        final itemMap = item as Map<String, dynamic>;
        if (itemMap['id'] == modelId) {
          data = itemMap;
          break;
        }
      }

      if (data == null) {
        LoggingService.warning('Modelo ML $modelId no encontrado en Supabase');
        return null;
      }

      LoggingService.info('Modelo ML $modelId cargado desde Supabase');
      return data as Map<String, dynamic>;
    } catch (e) {
      LoggingService.error('Error cargando modelo ML: $e');
      return null;
    }
  }

  /// Guarda predicción ML en Supabase
  Future<void> savePrediction(Map<String, dynamic> prediction, String productId) async {
    try {
      if (_supabase == null) await initialize();
      
      await _supabase!
          .from(_predictionsCollection)
          .insert({
        'product_id': productId,
        'value': prediction['value'] ?? 0.0,
        'confidence': prediction['confidence'] ?? 0.0,
        'factors': prediction['factors'] ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      LoggingService.info('Predicción ML guardada en Supabase');
    } catch (e) {
      LoggingService.error('Error guardando predicción ML: $e');
      rethrow;
    }
  }

  /// Carga predicciones ML desde Supabase
  Future<List<Map<String, dynamic>>> loadPredictions(String productId, {int limit = 100}) async {
    try {
      if (_supabase == null) await initialize();
      
      final querySnapshot = await _supabase!
          .from(_predictionsCollection)
          .select();

      final predictions = querySnapshot.map((doc) {
        return doc as Map<String, dynamic>;
      }).toList();

      LoggingService.info('${predictions.length} predicciones ML cargadas desde Supabase');
      return predictions;
    } catch (e) {
      LoggingService.error('Error cargando predicciones ML: $e');
      return [];
    }
  }

  /// Guarda insights ML en Supabase
  Future<void> saveInsight(Map<String, dynamic> insight) async {
    try {
      if (_supabase == null) await initialize();
      
      await _supabase!
          .from(_insightsCollection)
          .insert({
        'type': insight['type'] ?? 'general',
        'title': insight['title'] ?? '',
        'description': insight['description'] ?? '',
        'data': insight['data'] ?? {},
        'created_at': DateTime.now().toIso8601String(),
      });
      
      LoggingService.info('Insight ML guardado en Supabase');
    } catch (e) {
      LoggingService.error('Error guardando insight ML: $e');
      rethrow;
    }
  }

  /// Carga insights ML desde Supabase
  Future<List<Map<String, dynamic>>> loadInsights({int limit = 50}) async {
    try {
      if (_supabase == null) await initialize();
      
      final querySnapshot = await _supabase!
          .from(_insightsCollection)
          .select()
          .limit(limit);

      final insights = querySnapshot.map((doc) {
        return doc as Map<String, dynamic>;
      }).toList();

      LoggingService.info('${insights.length} insights ML cargados desde Supabase');
      return insights;
    } catch (e) {
      LoggingService.error('Error cargando insights ML: $e');
      return [];
    }
  }

  /// Limpia datos antiguos
  Future<void> cleanupOldData() async {
    try {
      if (_supabase == null) await initialize();
      
      // Por ahora, solo logueamos que se ejecutó la limpieza
      // En el futuro se puede implementar lógica de limpieza más sofisticada
      LoggingService.info('Limpieza de datos antiguos ejecutada');
    } catch (e) {
      LoggingService.error('Error limpiando datos antiguos: $e');
    }
  }

  /// Obtiene estadísticas de ML
  Future<Map<String, dynamic>> getMLStats() async {
    try {
      if (_supabase == null) await initialize();
      
      print('🔍 DEBUG: Obteniendo estadísticas de ML desde Supabase...');
      final trainingData = await _supabase!.from(_trainingDataCollection).select();
      final modelsData = await _supabase!.from(_modelsCollection).select();
      final predictionsData = await _supabase!.from(_predictionsCollection).select();

      final result = {
        'training_data_count': trainingData.length,
        'models_count': modelsData.length,
        'predictions_count': predictionsData.length,
        'last_updated': DateTime.now().toIso8601String(),
      };

      LoggingService.info('Estadísticas ML obtenidas: $result');
      return result;
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas ML: $e');
      return {
        'training_data_count': 0,
        'models_count': 0,
        'predictions_count': 0,
        'last_updated': DateTime.now().toIso8601String(),
      };
    }
  }
}