import 'dart:async';
import 'package:ricitosdebb/services/demand_prediction_service.dart';
import 'package:ricitosdebb/services/notification_service.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/models/producto.dart';

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final DemandPredictionService _demandService = DemandPredictionService();
  final NotificationService _notificationService = NotificationService();
  Timer? _predictionTimer;
  DateTime? _lastNotificationTime;
  
  // Configuración de notificaciones
  static const Duration _notificationInterval = Duration(hours: 6); // Cada 6 horas
  static const int _maxNotificationsPerDay = 3;
  int _notificationsSentToday = 0;
  DateTime? _lastResetDate;

  /// Inicializa el servicio de notificaciones inteligentes
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando servicio de notificaciones inteligentes');
      
      // Inicializar el servicio de notificaciones base
      await _notificationService.initialize();
      
      // Iniciar el timer para predicciones periódicas
      _startPredictionTimer();
      
      // Verificar si es un nuevo día para resetear contador
      _resetDailyCounterIfNeeded();
      
      LoggingService.info('Servicio de notificaciones inteligentes inicializado');
      
    } catch (e) {
      LoggingService.error('Error inicializando notificaciones inteligentes: $e');
    }
  }

  /// Inicia el timer para predicciones periódicas
  void _startPredictionTimer() {
    _predictionTimer?.cancel();
    _predictionTimer = Timer.periodic(_notificationInterval, (timer) {
      _checkAndSendRecommendations();
    });
  }

  /// Verifica y envía recomendaciones si es necesario
  Future<void> _checkAndSendRecommendations() async {
    try {
      // Verificar límite diario de notificaciones
      if (_notificationsSentToday >= _maxNotificationsPerDay) {
        LoggingService.info('Límite diario de notificaciones alcanzado');
        return;
      }

      // Verificar si ha pasado suficiente tiempo desde la última notificación
      if (_lastNotificationTime != null) {
        final timeSinceLastNotification = DateTime.now().difference(_lastNotificationTime!);
        if (timeSinceLastNotification < _notificationInterval) {
          return;
        }
      }

      // Obtener recomendaciones de stock
      final recommendations = await _demandService.getStockRecommendations();
      
      if (recommendations.isNotEmpty) {
        // Filtrar solo las recomendaciones más urgentes
        final urgentRecommendations = recommendations
            .where((rec) => rec.urgency == DemandUrgency.high)
            .take(2) // Máximo 2 productos por notificación
            .toList();
        
        if (urgentRecommendations.isNotEmpty) {
          await _sendStockRecommendationNotification(urgentRecommendations);
          _notificationsSentToday++;
          _lastNotificationTime = DateTime.now();
        }
      }
      
    } catch (e) {
      LoggingService.error('Error verificando recomendaciones: $e');
    }
  }

  /// Envía notificación de recomendación de stock
  Future<void> _sendStockRecommendationNotification(List<StockRecommendation> recommendations) async {
    try {
      if (recommendations.isEmpty) return;

      final producto = recommendations.first.producto;
      final title = '📈 Recomendación de Stock - IA';
      
      String body;
      if (recommendations.length == 1) {
        final rec = recommendations.first;
        body = '${producto.nombre}: Se recomienda aumentar stock de ${rec.currentStock} a ${rec.recommendedStock} unidades. Demanda esperada: ${rec.predictedDemand} unidades.';
      } else {
        body = 'Se recomienda revisar el stock de ${recommendations.length} productos con alta demanda esperada.';
      }

      await _notificationService.showNotification(
        title: title,
        body: body,
      );

      LoggingService.info('Notificación de recomendación enviada para ${recommendations.length} productos');
      
    } catch (e) {
      LoggingService.error('Error enviando notificación de recomendación: $e');
    }
  }

  /// Envía notificación inmediata para un producto específico
  Future<void> sendImmediateRecommendation(StockRecommendation recommendation) async {
    try {
      final title = '🚨 Stock Bajo - Acción Requerida';
      final body = '${recommendation.producto.nombre}: Solo quedan ${recommendation.currentStock} unidades. Se recomienda reabastecer a ${recommendation.recommendedStock} unidades.';

      await _notificationService.showNotification(
        title: title,
        body: body,
      );

      LoggingService.info('Notificación urgente enviada para ${recommendation.producto.nombre}');
      
    } catch (e) {
      LoggingService.error('Error enviando notificación urgente: $e');
    }
  }

  /// Envía notificación de análisis de tendencias
  Future<void> sendTrendAnalysisNotification() async {
    try {
      final title = '📊 Análisis de Tendencias - IA';
      final body = 'Se han identificado nuevas tendencias en las ventas. Revisa el dashboard para más detalles.';

      await _notificationService.showNotification(
        title: title,
        body: body,
      );

      LoggingService.info('Notificación de análisis de tendencias enviada');
      
    } catch (e) {
      LoggingService.error('Error enviando notificación de tendencias: $e');
    }
  }

  /// Envía notificación de oportunidad de negocio
  Future<void> sendBusinessOpportunityNotification(String opportunity) async {
    try {
      final title = '💡 Oportunidad de Negocio - IA';
      final body = opportunity;

      await _notificationService.showNotification(
        title: title,
        body: body,
      );

      LoggingService.info('Notificación de oportunidad enviada');
      
    } catch (e) {
      LoggingService.error('Error enviando notificación de oportunidad: $e');
    }
  }

  /// Verifica si se debe resetear el contador diario
  void _resetDailyCounterIfNeeded() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null || _lastResetDate!.isBefore(today)) {
      _notificationsSentToday = 0;
      _lastResetDate = today;
      LoggingService.info('Contador diario de notificaciones reseteado');
    }
  }

  /// Obtiene estadísticas de notificaciones
  Map<String, dynamic> getNotificationStats() {
    return {
      'notificationsSentToday': _notificationsSentToday,
      'maxNotificationsPerDay': _maxNotificationsPerDay,
      'lastNotificationTime': _lastNotificationTime?.toIso8601String(),
      'isTimerActive': _predictionTimer?.isActive ?? false,
    };
  }

  /// Pausa las notificaciones automáticas
  void pauseNotifications() {
    _predictionTimer?.cancel();
    LoggingService.info('Notificaciones automáticas pausadas');
  }

  /// Reanuda las notificaciones automáticas
  void resumeNotifications() {
    _startPredictionTimer();
    LoggingService.info('Notificaciones automáticas reanudadas');
  }

  /// Detiene el servicio
  void dispose() {
    _predictionTimer?.cancel();
    LoggingService.info('Servicio de notificaciones inteligentes detenido');
  }
}
