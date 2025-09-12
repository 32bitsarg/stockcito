import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../logging_service.dart';
import 'sync_service.dart';

/// Servicio de notificaciones para sincronización
class SyncNotificationService {
  static final SyncNotificationService _instance = SyncNotificationService._internal();
  factory SyncNotificationService() => _instance;
  SyncNotificationService._internal();

  final SyncService _syncService = SyncService();
  
  // Callbacks para notificaciones
  Function(String message, NotificationType type)? _onNotification;
  Function(SyncStatus status)? _onStatusChange;

  /// Configura el callback de notificaciones
  void setNotificationCallback(Function(String message, NotificationType type) callback) {
    _onNotification = callback;
  }

  /// Configura el callback de cambios de estado
  void setStatusChangeCallback(Function(SyncStatus status) callback) {
    _onStatusChange = callback;
  }

  /// Muestra una notificación
  void _showNotification(String message, NotificationType type) {
    _onNotification?.call(message, type);
    LoggingService.info('Notificación: $message (${type.toString()})');
  }

  /// Notifica un cambio de estado
  void _notifyStatusChange(SyncStatus status) {
    _onStatusChange?.call(status);
  }

  /// Inicia el monitoreo de sincronización
  void startMonitoring() {
    // Monitorear cambios de estado
    _monitorSyncStatus();
  }

  /// Monitorea el estado de sincronización
  void _monitorSyncStatus() {
    // En una implementación real, usarías un Stream o Timer
    // Por ahora, simulamos el monitoreo
    _checkSyncStatus();
  }

  /// Verifica el estado de sincronización
  void _checkSyncStatus() {
    final status = _syncService.syncStatus;
    
    switch (status) {
      case SyncStatus.synced:
        _showNotification('Datos sincronizados correctamente', NotificationType.success);
        break;
      case SyncStatus.syncing:
        _showNotification('Sincronizando datos...', NotificationType.info);
        break;
      case SyncStatus.pending:
        final pending = _syncService.pendingOperations;
        _showNotification('$pending operaciones pendientes de sincronizar', NotificationType.warning);
        break;
      case SyncStatus.offline:
        _showNotification('Sin conexión. Los datos se sincronizarán cuando se restaure la conexión', NotificationType.error);
        break;
    }
    
    _notifyStatusChange(status);
  }

  /// Muestra notificación de error de sincronización
  void notifySyncError(String error) {
    _showNotification('Error de sincronización: $error', NotificationType.error);
  }

  /// Muestra notificación de éxito de sincronización
  void notifySyncSuccess(int operationsCount) {
    _showNotification('$operationsCount operaciones sincronizadas exitosamente', NotificationType.success);
  }

  /// Muestra notificación de respaldo creado
  void notifyBackupCreated(String backupId) {
    _showNotification('Respaldo creado: $backupId', NotificationType.success);
  }

  /// Muestra notificación de respaldo restaurado
  void notifyBackupRestored(String backupId) {
    _showNotification('Respaldo restaurado: $backupId', NotificationType.success);
  }

  /// Muestra notificación de datos exportados
  void notifyDataExported() {
    _showNotification('Datos exportados exitosamente', NotificationType.success);
  }

  /// Muestra notificación de datos importados
  void notifyDataImported() {
    _showNotification('Datos importados exitosamente', NotificationType.success);
  }
}

/// Tipos de notificaciones
enum NotificationType {
  success,
  info,
  warning,
  error,
}

/// Widget de notificación de sincronización
class SyncNotificationWidget extends StatefulWidget {
  final Function(String message, NotificationType type)? onNotification;
  final Function(SyncStatus status)? onStatusChange;

  const SyncNotificationWidget({
    super.key,
    this.onNotification,
    this.onStatusChange,
  });

  @override
  State<SyncNotificationWidget> createState() => _SyncNotificationWidgetState();
}

class _SyncNotificationWidgetState extends State<SyncNotificationWidget> {
  final SyncNotificationService _notificationService = SyncNotificationService();
  String _lastMessage = '';
  NotificationType _lastType = NotificationType.info;

  @override
  void initState() {
    super.initState();
    _setupNotificationService();
  }

  void _setupNotificationService() {
    _notificationService.setNotificationCallback(_onNotification);
    _notificationService.setStatusChangeCallback(_onStatusChange);
    _notificationService.startMonitoring();
  }

  void _onNotification(String message, NotificationType type) {
    setState(() {
      _lastMessage = message;
      _lastType = type;
    });
  }

  void _onStatusChange(SyncStatus status) {
    setState(() {
      // Status actualizado
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_lastMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getBorderColor(),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getIconColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _lastMessage,
              style: TextStyle(
                color: _getTextColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _lastMessage = '';
              });
            },
            icon: const Icon(Icons.close, size: 18),
            color: _getTextColor(),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_lastType) {
      case NotificationType.success:
        return Colors.green.withOpacity(0.1);
      case NotificationType.info:
        return Colors.blue.withOpacity(0.1);
      case NotificationType.warning:
        return Colors.orange.withOpacity(0.1);
      case NotificationType.error:
        return Colors.red.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (_lastType) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
    }
  }

  Color _getTextColor() {
    switch (_lastType) {
      case NotificationType.success:
        return Colors.green.shade700;
      case NotificationType.info:
        return Colors.blue.shade700;
      case NotificationType.warning:
        return Colors.orange.shade700;
      case NotificationType.error:
        return Colors.red.shade700;
    }
  }

  Color _getIconColor() {
    return _getTextColor();
  }

  IconData _getIcon() {
    switch (_lastType) {
      case NotificationType.success:
        return FontAwesomeIcons.checkCircle;
      case NotificationType.info:
        return FontAwesomeIcons.infoCircle;
      case NotificationType.warning:
        return FontAwesomeIcons.exclamationTriangle;
      case NotificationType.error:
        return FontAwesomeIcons.exclamationCircle;
    }
  }
}
