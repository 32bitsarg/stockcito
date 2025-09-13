import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ricitosdebb/models/smart_alert.dart';
import 'datos.dart';
import 'package:ricitosdebb/services/system/logging_service.dart';

/// Servicio para gestionar alertas inteligentes
class SmartAlertsService {
  static final SmartAlertsService _instance = SmartAlertsService._internal();
  factory SmartAlertsService() => _instance;
  SmartAlertsService._internal();

  final DatosService _datosService = DatosService();
  static const String _alertsKey = 'smart_alerts';
  static const Duration _checkInterval = Duration(minutes: 5); // Verificar cada 5 minutos

  List<SmartAlert> _alerts = [];
  Timer? _checkTimer;
  int _minStockLevel = 5; // Nivel mínimo de stock configurable

  /// Inicializa el servicio
  Future<void> initialize() async {
    try {
      await _loadAlerts();
      await _loadSettings();
      _startPeriodicCheck();
      LoggingService.info('SmartAlertsService inicializado');
    } catch (e) {
      LoggingService.error('Error inicializando SmartAlertsService: $e');
    }
  }

  /// Carga alertas desde SharedPreferences
  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? alertsJson = prefs.getString(_alertsKey);
      
      if (alertsJson != null) {
        final List<dynamic> alertsList = json.decode(alertsJson);
        _alerts = alertsList
            .map((json) => SmartAlert.fromMap(json))
            .where((alert) => !alert.isDismissed) // Solo alertas activas
            .toList();
        
        // Ordenar por prioridad y fecha
        _alerts.sort((a, b) {
          if (a.priority != b.priority) {
            return a.priority.index.compareTo(b.priority.index);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        
        LoggingService.info('Cargadas ${_alerts.length} alertas inteligentes');
      }
    } catch (e) {
      LoggingService.error('Error cargando alertas: $e');
      _alerts = [];
    }
  }

  /// Guarda alertas en SharedPreferences
  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String alertsJson = json.encode(
        _alerts.map((a) => a.toMap()).toList()
      );
      await prefs.setString(_alertsKey, alertsJson);
      LoggingService.info('Alertas guardadas localmente');
    } catch (e) {
      LoggingService.error('Error guardando alertas: $e');
    }
  }

  /// Carga configuración
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _minStockLevel = prefs.getInt('min_stock_level') ?? 5;
      LoggingService.info('Configuración de alertas cargada - Stock mínimo: $_minStockLevel');
    } catch (e) {
      LoggingService.error('Error cargando configuración de alertas: $e');
    }
  }

  /// Recarga configuración desde SharedPreferences
  Future<void> reloadSettings() async {
    await _loadSettings();
  }

  /// Guarda configuración
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('min_stock_level', _minStockLevel);
      LoggingService.info('Configuración de alertas guardada');
    } catch (e) {
      LoggingService.error('Error guardando configuración de alertas: $e');
    }
  }

  /// Inicia la verificación periódica
  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_checkInterval, (timer) {
      _checkForAlerts();
    });
  }

  /// Verifica y genera alertas
  Future<void> _checkForAlerts() async {
    try {
      LoggingService.info('Verificando alertas inteligentes...');
      
      // Obtener datos actuales
      final productos = await _datosService.getProductos();
      final ventas = await _datosService.getVentas();
      
      // Verificar alertas de stock bajo
      await _checkStockAlerts(productos);
      
      // Verificar alertas de precios anómalos
      await _checkPricingAlerts(productos);
      
      // Verificar alertas de rentabilidad
      await _checkProfitabilityAlerts(productos);
      
      // Verificar alertas de tendencias
      await _checkTrendAlerts(ventas, productos);
      
      LoggingService.info('Verificación de alertas completada');
    } catch (e) {
      LoggingService.error('Error verificando alertas: $e');
    }
  }

  /// Verifica alertas de stock bajo
  Future<void> _checkStockAlerts(List<dynamic> productos) async {
    try {
      final lowStockProducts = productos.where((p) => p.stock <= _minStockLevel).toList();
      
      for (final product in lowStockProducts) {
        // Verificar si ya existe una alerta activa para este producto
        final existingAlert = _alerts.any((alert) => 
          alert.type == AlertType.stockBajo && 
          alert.productId == product.id.toString() &&
          !alert.isDismissed
        );
        
        if (!existingAlert) {
          final alert = SmartAlert(
            id: 'stock_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Stock Bajo - ${product.nombre}',
            message: 'Solo quedan ${product.stock} unidades de ${product.nombre}. Nivel mínimo: $_minStockLevel',
            productId: product.id.toString(),
            productName: product.nombre,
            type: AlertType.stockBajo,
            priority: product.stock <= 1 ? AlertPriority.critica : 
                     product.stock <= 3 ? AlertPriority.alta : AlertPriority.media,
            createdAt: DateTime.now(),
            metadata: {
              'current_stock': product.stock,
              'min_stock': _minStockLevel,
              'product_id': product.id,
            },
          );
          
          _alerts.add(alert);
          LoggingService.info('Alerta de stock bajo creada para ${product.nombre}');
        }
      }
      
      await _saveAlerts();
    } catch (e) {
      LoggingService.error('Error verificando alertas de stock: $e');
    }
  }

  /// Verifica alertas de precios anómalos
  Future<void> _checkPricingAlerts(List<dynamic> productos) async {
    try {
      if (productos.length < 3) return;
      
      // Calcular estadísticas de precios
      final prices = productos.map((p) => p.precioVenta).toList();
      final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
      final stdDev = _calculateStandardDeviation(prices.cast<double>(), avgPrice);
      
      // Buscar precios anómalos (más de 2 desviaciones estándar)
      final threshold = 2 * stdDev;
      
      for (final product in productos) {
        final priceDiff = (product.precioVenta - avgPrice).abs();
        
        if (priceDiff > threshold) {
          // Verificar si ya existe una alerta activa para este producto
          final existingAlert = _alerts.any((alert) => 
            alert.type == AlertType.precioAnomalo && 
            alert.productId == product.id.toString() &&
            !alert.isDismissed
          );
          
          if (!existingAlert) {
            final isHigh = product.precioVenta > avgPrice;
            final alert = SmartAlert(
              id: 'pricing_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Precio ${isHigh ? 'Alto' : 'Bajo'} - ${product.nombre}',
              message: '${product.nombre} tiene un precio ${isHigh ? 'muy alto' : 'muy bajo'} (${product.precioVenta.toStringAsFixed(2)}). Precio promedio: ${avgPrice.toStringAsFixed(2)}',
              productId: product.id.toString(),
              productName: product.nombre,
              type: AlertType.precioAnomalo,
              priority: AlertPriority.media,
              createdAt: DateTime.now(),
              metadata: {
                'current_price': product.precioVenta,
                'average_price': avgPrice,
                'price_difference': priceDiff,
                'is_high': isHigh,
              },
            );
            
            _alerts.add(alert);
            LoggingService.info('Alerta de precio anómalo creada para ${product.nombre}');
          }
        }
      }
      
      await _saveAlerts();
    } catch (e) {
      LoggingService.error('Error verificando alertas de precios: $e');
    }
  }

  /// Verifica alertas de rentabilidad
  Future<void> _checkProfitabilityAlerts(List<dynamic> productos) async {
    try {
      for (final product in productos) {
        final totalCost = product.costoMateriales + product.costoManoObra + product.gastosGenerales;
        final margin = (product.precioVenta - totalCost) / product.precioVenta;
        
        // Alertar si el margen es menor al 5%
        if (margin < 0.05) {
          // Verificar si ya existe una alerta activa para este producto
          final existingAlert = _alerts.any((alert) => 
            alert.type == AlertType.rentabilidad && 
            alert.productId == product.id.toString() &&
            !alert.isDismissed
          );
          
          if (!existingAlert) {
            final alert = SmartAlert(
              id: 'profitability_${product.id}_${DateTime.now().millisecondsSinceEpoch}',
              title: 'Baja Rentabilidad - ${product.nombre}',
              message: '${product.nombre} tiene un margen de ganancia del ${(margin * 100).toStringAsFixed(1)}%. Revisa costos o precios.',
              productId: product.id.toString(),
              productName: product.nombre,
              type: AlertType.rentabilidad,
              priority: margin < 0.02 ? AlertPriority.critica : AlertPriority.alta,
              createdAt: DateTime.now(),
              metadata: {
                'margin_percentage': margin * 100,
                'total_cost': totalCost,
                'selling_price': product.precioVenta,
                'product_id': product.id,
              },
            );
            
            _alerts.add(alert);
            LoggingService.info('Alerta de rentabilidad creada para ${product.nombre}');
          }
        }
      }
      
      await _saveAlerts();
    } catch (e) {
      LoggingService.error('Error verificando alertas de rentabilidad: $e');
    }
  }

  /// Verifica alertas de tendencias
  Future<void> _checkTrendAlerts(List<dynamic> ventas, List<dynamic> productos) async {
    try {
      if (ventas.length < 10) return;
      
      // Analizar tendencia de ventas de los últimos 7 días
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final recentSales = ventas.where((v) => v.fecha.isAfter(weekAgo)).toList();
      
      if (recentSales.length < 5) return;
      
      // Calcular ventas por día
      final Map<int, int> salesByDay = {};
      for (final sale in recentSales) {
        final day = sale.fecha.day;
        salesByDay[day] = (salesByDay[day] ?? 0) + 1;
      }
      
      // Verificar si hay una tendencia descendente
      final days = salesByDay.keys.toList()..sort();
      if (days.length >= 3) {
        int decreasingDays = 0;
        for (int i = 1; i < days.length; i++) {
          if (salesByDay[days[i]]! < salesByDay[days[i-1]]!) {
            decreasingDays++;
          }
        }
        
        // Si hay 3 o más días consecutivos de disminución
        if (decreasingDays >= 3) {
          final alert = SmartAlert(
            id: 'trend_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Tendencia Descendente Detectada',
            message: 'Las ventas han disminuido en los últimos días. Considera revisar estrategias de marketing.',
            type: AlertType.tendencia,
            priority: AlertPriority.media,
            createdAt: DateTime.now(),
            metadata: {
              'decreasing_days': decreasingDays,
              'total_sales_week': recentSales.length,
              'sales_by_day': salesByDay,
            },
          );
          
          _alerts.add(alert);
          LoggingService.info('Alerta de tendencia descendente creada');
        }
      }
      
      await _saveAlerts();
    } catch (e) {
      LoggingService.error('Error verificando alertas de tendencias: $e');
    }
  }

  /// Calcula la desviación estándar
  double _calculateStandardDeviation(List<double> values, double mean) {
    if (values.isEmpty) return 0.0;
    
    final variance = values
        .map((value) => (value - mean) * (value - mean))
        .reduce((a, b) => a + b) / values.length;
    
    return variance > 0 ? variance : 0.0;
  }

  /// Obtiene todas las alertas
  List<SmartAlert> getAlerts() {
    return List.from(_alerts);
  }

  /// Obtiene alertas no leídas
  List<SmartAlert> getUnreadAlerts() {
    return _alerts.where((alert) => !alert.isRead).toList();
  }

  /// Obtiene alertas críticas
  List<SmartAlert> getCriticalAlerts() {
    return _alerts.where((alert) => alert.isCritical && !alert.isDismissed).toList();
  }

  /// Marca una alerta como leída
  Future<void> markAsRead(String alertId) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isRead: true);
        await _saveAlerts();
        LoggingService.info('Alerta marcada como leída: $alertId');
      }
    } catch (e) {
      LoggingService.error('Error marcando alerta como leída: $e');
    }
  }

  /// Descarta una alerta
  Future<void> dismissAlert(String alertId) async {
    try {
      final index = _alerts.indexWhere((a) => a.id == alertId);
      if (index != -1) {
        _alerts[index] = _alerts[index].copyWith(isDismissed: true);
        await _saveAlerts();
        LoggingService.info('Alerta descartada: $alertId');
      }
    } catch (e) {
      LoggingService.error('Error descartando alerta: $e');
    }
  }

  /// Elimina una alerta
  Future<void> deleteAlert(String alertId) async {
    try {
      _alerts.removeWhere((a) => a.id == alertId);
      await _saveAlerts();
      LoggingService.info('Alerta eliminada: $alertId');
    } catch (e) {
      LoggingService.error('Error eliminando alerta: $e');
    }
  }

  /// Actualiza el nivel mínimo de stock
  Future<void> updateMinStockLevel(int newLevel) async {
    try {
      _minStockLevel = newLevel;
      await _saveSettings();
      LoggingService.info('Nivel mínimo de stock actualizado a: $newLevel');
    } catch (e) {
      LoggingService.error('Error actualizando nivel mínimo de stock: $e');
    }
  }

  /// Obtiene el nivel mínimo de stock
  int get minStockLevel => _minStockLevel;

  /// Obtiene estadísticas de alertas
  Map<String, dynamic> getStats() {
    final total = _alerts.length;
    final unread = _alerts.where((a) => !a.isRead).length;
    final critical = _alerts.where((a) => a.isCritical).length;
    final dismissed = _alerts.where((a) => a.isDismissed).length;

    return {
      'total': total,
      'unread': unread,
      'critical': critical,
      'dismissed': dismissed,
      'active': total - dismissed,
    };
  }

  /// Limpia alertas antiguas (más de 30 días)
  Future<void> cleanOldAlerts() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      _alerts.removeWhere((a) => 
        a.createdAt.isBefore(cutoffDate) && a.isDismissed
      );
      await _saveAlerts();
      LoggingService.info('Alertas antiguas limpiadas');
    } catch (e) {
      LoggingService.error('Error limpiando alertas antiguas: $e');
    }
  }

  /// Dispone del servicio
  void dispose() {
    _checkTimer?.cancel();
  }
}
