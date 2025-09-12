import 'package:flutter/material.dart';
import 'package:ricitosdebb/config/app_theme.dart';
import 'package:ricitosdebb/models/smart_alert.dart';
import '../services/datos/smart_alerts_service.dart';
import 'package:ricitosdebb/services/notification_service.dart';

/// Widget de notificaciones inteligentes que se integra con el header
class SmartNotificationsWidget extends StatefulWidget {
  const SmartNotificationsWidget({Key? key}) : super(key: key);

  @override
  State<SmartNotificationsWidget> createState() => _SmartNotificationsWidgetState();
}

class _SmartNotificationsWidgetState extends State<SmartNotificationsWidget> {
  final SmartAlertsService _alertsService = SmartAlertsService();
  final NotificationService _notificationService = NotificationService();
  
  List<SmartAlert> _alerts = [];
  bool _isLoading = true;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _alertsService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      print('🔔 DEBUG: Inicializando SmartNotificationsWidget...');
      await _alertsService.initialize();
      await _notificationService.initialize();
      _loadAlerts();
      _startPeriodicCheck();
      print('🔔 DEBUG: SmartNotificationsWidget inicializado correctamente');
    } catch (e) {
      print('Error inicializando servicios de notificaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadAlerts() {
    if (!mounted) return;
    
    try {
      setState(() {
        _alerts = _alertsService.getAlerts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando alertas: $e');
      if (mounted) {
        setState(() {
          _alerts = [];
          _isLoading = false;
        });
      }
    }
  }

  void _startPeriodicCheck() {
    // Verificar alertas cada 30 segundos
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadAlerts();
        _checkForNewAlerts();
        _startPeriodicCheck();
      }
    });
  }

  void _checkForNewAlerts() {
    final newAlerts = _alerts.where((a) => !a.isRead && !a.isDismissed).toList();
    
    for (final alert in newAlerts) {
      if (alert.isCritical) {
        _showWindowsNotification(alert);
      }
    }
  }

  Future<void> _showWindowsNotification(SmartAlert alert) async {
    try {
      await _notificationService.showNotification(
        title: '🚨 ${alert.title}',
        body: alert.message,
      );
    } catch (e) {
      print('Error mostrando notificación de Windows: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => !a.isRead && !a.isDismissed).length;
    final criticalCount = _alerts.where((a) => a.isCritical && !a.isDismissed).length;

    print('🔔 DEBUG: SmartNotificationsWidget build - unreadCount: $unreadCount, criticalCount: $criticalCount');

    return GestureDetector(
      onTap: () {
        // Cerrar dropdown si está abierto
        if (_isDropdownOpen) {
          setState(() {
            _isDropdownOpen = false;
          });
        }
      },
      child: Stack(
        children: [
        // Botón de notificaciones
        GestureDetector(
          onTap: () {
            print('🔔 DEBUG: Botón de notificaciones clickeado - _isDropdownOpen: $_isDropdownOpen');
            setState(() {
              _isDropdownOpen = !_isDropdownOpen;
            });
            print('🔔 DEBUG: Después del click - _isDropdownOpen: $_isDropdownOpen');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: criticalCount > 0 ? AppTheme.errorColor : AppTheme.borderColor,
                width: criticalCount > 0 ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: criticalCount > 0 
                    ? AppTheme.errorColor.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    criticalCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                    color: criticalCount > 0 ? AppTheme.errorColor : AppTheme.textSecondary,
                    size: 20,
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Dropdown de notificaciones
        if (_isDropdownOpen)
          Positioned(
            top: 50,
            right: 0,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 320,
                constraints: const BoxConstraints(maxHeight: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header del dropdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.notifications, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Notificaciones ($unreadCount)',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de notificaciones
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      )
                    else if (_alerts.isEmpty)
                      _buildEmptyState()
                    else
                      Container(
                        height: 200, // Altura fija para evitar overflow
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _alerts.length,
                          itemBuilder: (context, index) {
                            final alert = _alerts[index];
                            return _buildAlertItem(alert);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            color: AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(SmartAlert alert) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.isRead ? AppTheme.backgroundColor : alert.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.isRead ? AppTheme.borderColor : alert.typeColor.withOpacity(0.3),
        ),
      ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            children: [
              Icon(alert.typeIcon, color: alert.typeColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: alert.typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (alert.isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CRÍTICA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!alert.isRead) ...[
                Flexible(
                  child: _buildActionButton(
                    'Marcar como leída',
                    Icons.visibility,
                    AppTheme.primaryColor,
                    () => _markAsRead(alert.id),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (!alert.isDismissed) ...[
                Flexible(
                  child: _buildActionButton(
                    'Descartar',
                    Icons.cancel,
                    AppTheme.errorColor,
                    () => _dismissAlert(alert.id),
                  ),
                ),
              ],
              const Spacer(),
              Flexible(
                child: Text(
                  alert.timeElapsedDescription,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(String alertId) async {
    await _alertsService.markAsRead(alertId);
    _loadAlerts();
  }

  Future<void> _dismissAlert(String alertId) async {
    await _alertsService.dismissAlert(alertId);
    _loadAlerts();
  }

}
