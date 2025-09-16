import 'dart:io';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockcito/services/system/logging_service.dart';

enum NotificationType {
  stockLow,
  taskReminder,
  saleAlert,
  systemUpdate,
  general,
}

class NotificationData {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime scheduledTime;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.scheduledTime,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'scheduledTime': scheduledTime.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      scheduledTime: DateTime.parse(map['scheduledTime']),
      data: map['data'],
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _notificationsKey = 'scheduled_notifications';

  bool _isInitialized = false;
  bool _notificationsEnabled = true;
  bool _stockAlertsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _saleAlertsEnabled = true;
  List<NotificationData> _scheduledNotifications = [];

  // Getters
  bool get isInitialized => _isInitialized;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get stockAlertsEnabled => _stockAlertsEnabled;
  bool get taskRemindersEnabled => _taskRemindersEnabled;
  bool get saleAlertsEnabled => _saleAlertsEnabled;
  List<NotificationData> get scheduledNotifications => List.unmodifiable(_scheduledNotifications);

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      LoggingService.info('Inicializando servicio de notificaciones');

      // Solo inicializar en Windows
      if (!Platform.isWindows) {
        LoggingService.warning('Notificaciones solo disponibles en Windows');
        return;
      }

      // Configurar notificaciones locales
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      // Cargar configuración guardada
      await _loadSettings();

      // Cargar notificaciones programadas
      await _loadScheduledNotifications();

      _isInitialized = true;
      LoggingService.info('Servicio de notificaciones inicializado correctamente');
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error inicializando servicio de notificaciones',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Carga la configuración de notificaciones
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _stockAlertsEnabled = prefs.getBool('stock_alerts_enabled') ?? true;
      _taskRemindersEnabled = prefs.getBool('task_reminders_enabled') ?? true;
      _saleAlertsEnabled = prefs.getBool('sale_alerts_enabled') ?? true;
    } catch (e) {
      LoggingService.error('Error cargando configuración de notificaciones', error: e);
    }
  }

  /// Guarda la configuración de notificaciones
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setBool('stock_alerts_enabled', _stockAlertsEnabled);
      await prefs.setBool('task_reminders_enabled', _taskRemindersEnabled);
      await prefs.setBool('sale_alerts_enabled', _saleAlertsEnabled);
    } catch (e) {
      LoggingService.error('Error guardando configuración de notificaciones', error: e);
    }
  }

  /// Carga las notificaciones programadas
  Future<void> _loadScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];
      
      _scheduledNotifications = notificationsJson
          .map((json) => NotificationData.fromMap(Map<String, dynamic>.from(
              jsonDecode(json))))
          .toList();
    } catch (e) {
      LoggingService.error('Error cargando notificaciones programadas', error: e);
    }
  }

  /// Guarda las notificaciones programadas
  Future<void> _saveScheduledNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _scheduledNotifications
          .map((notification) => jsonEncode(notification.toMap()))
          .toList();
      
      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      LoggingService.error('Error guardando notificaciones programadas', error: e);
    }
  }

  /// Muestra una notificación inmediata
  Future<void> showNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      // Verificar si el tipo de notificación está habilitado
      if (!_isNotificationTypeEnabled(type)) return;

      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidDetails = AndroidNotificationDetails(
        'stockcito_channel',
        'Stockcito Notifications',
        channelDescription: 'Notificaciones de Stockcito',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
      );

      LoggingService.info('Notificación mostrada: $title');
    } catch (e) {
      LoggingService.error('Error mostrando notificación', error: e);
    }
  }

  /// Programa una notificación para el futuro
  Future<void> scheduleNotification({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    if (!_isInitialized || !_notificationsEnabled) return;

    try {
      // Verificar si el tipo de notificación está habilitado
      if (!_isNotificationTypeEnabled(type)) return;

      // Crear objeto de notificación
      final notification = NotificationData(
        id: id,
        title: title,
        body: body,
        type: type,
        scheduledTime: scheduledTime,
        data: data,
      );

      // Agregar a la lista de notificaciones programadas
      _scheduledNotifications.add(notification);
      await _saveScheduledNotifications();

      // Programar la notificación
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      const androidDetails = AndroidNotificationDetails(
        'stockcito_scheduled',
        'Stockcito Scheduled',
        channelDescription: 'Notificaciones programadas de Stockcito',
        importance: Importance.high,
        priority: Priority.high,
      );
      
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      await flutterLocalNotificationsPlugin.zonedSchedule(
        scheduledTime.millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );

      LoggingService.info('Notificación programada: $title para ${scheduledTime.toString()}');
    } catch (e) {
      LoggingService.error('Error programando notificación', error: e);
    }
  }

  /// Cancela una notificación programada
  Future<void> cancelNotification(String id) async {
    try {
      _scheduledNotifications.removeWhere((notification) => notification.id == id);
      await _saveScheduledNotifications();
      
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.cancel(0); // Cancelar todas las notificaciones programadas
      
      LoggingService.info('Notificación cancelada: $id');
    } catch (e) {
      LoggingService.error('Error cancelando notificación', error: e);
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    try {
      _scheduledNotifications.clear();
      await _saveScheduledNotifications();
      
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin.cancel(0);
      
      LoggingService.info('Todas las notificaciones canceladas');
    } catch (e) {
      LoggingService.error('Error cancelando todas las notificaciones', error: e);
    }
  }

  /// Verifica si un tipo de notificación está habilitado
  bool _isNotificationTypeEnabled(NotificationType type) {
    switch (type) {
      case NotificationType.stockLow:
        return _stockAlertsEnabled;
      case NotificationType.taskReminder:
        return _taskRemindersEnabled;
      case NotificationType.saleAlert:
        return _saleAlertsEnabled;
      case NotificationType.systemUpdate:
      case NotificationType.general:
        return _notificationsEnabled;
    }
  }

  /// Configura las preferencias de notificaciones
  Future<void> updateSettings({
    bool? notificationsEnabled,
    bool? stockAlertsEnabled,
    bool? taskRemindersEnabled,
    bool? saleAlertsEnabled,
  }) async {
    if (notificationsEnabled != null) _notificationsEnabled = notificationsEnabled;
    if (stockAlertsEnabled != null) _stockAlertsEnabled = stockAlertsEnabled;
    if (taskRemindersEnabled != null) _taskRemindersEnabled = taskRemindersEnabled;
    if (saleAlertsEnabled != null) _saleAlertsEnabled = saleAlertsEnabled;

    await _saveSettings();
    LoggingService.info('Configuración de notificaciones actualizada');
  }

  /// Muestra notificación de stock bajo
  Future<void> showStockLowAlert(String productName, int currentStock) async {
    await showNotification(
      title: '⚠️ Stock Bajo',
      body: '$productName tiene solo $currentStock unidades en stock',
      type: NotificationType.stockLow,
      data: {
        'productName': productName,
        'currentStock': currentStock,
        'action': 'check_inventory',
      },
    );
  }

  /// Muestra notificación de venta importante
  Future<void> showSaleAlert(String customerName, double amount) async {
    await showNotification(
      title: '💰 Nueva Venta',
      body: 'Venta de \$${amount.toStringAsFixed(2)} a $customerName',
      type: NotificationType.saleAlert,
      data: {
        'customerName': customerName,
        'amount': amount,
        'action': 'view_sale',
      },
    );
  }

  /// Muestra recordatorio de tarea
  Future<void> showTaskReminder(String taskDescription) async {
    await showNotification(
      title: '📋 Recordatorio',
      body: taskDescription,
      type: NotificationType.taskReminder,
      data: {
        'taskDescription': taskDescription,
        'action': 'view_tasks',
      },
    );
  }

  /// Muestra notificación del sistema
  Future<void> showSystemNotification(String title, String body) async {
    await showNotification(
      title: '🔧 $title',
      body: body,
      type: NotificationType.systemUpdate,
    );
  }

  /// Limpia notificaciones expiradas
  Future<void> cleanExpiredNotifications() async {
    final now = DateTime.now();
    _scheduledNotifications.removeWhere(
      (notification) => notification.scheduledTime.isBefore(now),
    );
    await _saveScheduledNotifications();
  }

  /// Obtiene estadísticas de notificaciones
  Map<String, dynamic> getNotificationStats() {
    return {
      'totalScheduled': _scheduledNotifications.length,
      'notificationsEnabled': _notificationsEnabled,
      'stockAlertsEnabled': _stockAlertsEnabled,
      'taskRemindersEnabled': _taskRemindersEnabled,
      'saleAlertsEnabled': _saleAlertsEnabled,
      'isInitialized': _isInitialized,
    };
  }
}
