import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/notifications/notification_service.dart';

class NotificationSettingsWidget extends StatefulWidget {
  const NotificationSettingsWidget({super.key});

  @override
  State<NotificationSettingsWidget> createState() => _NotificationSettingsWidgetState();
}

class _NotificationSettingsWidgetState extends State<NotificationSettingsWidget> {
  final NotificationService _notificationService = NotificationService();
  
  bool _notificationsEnabled = true;
  bool _stockAlertsEnabled = true;
  bool _taskRemindersEnabled = true;
  bool _saleAlertsEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    await _notificationService.initialize();
    
    setState(() {
      _notificationsEnabled = _notificationService.notificationsEnabled;
      _stockAlertsEnabled = _notificationService.stockAlertsEnabled;
      _taskRemindersEnabled = _notificationService.taskRemindersEnabled;
      _saleAlertsEnabled = _notificationService.saleAlertsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _updateSettings() async {
    setState(() => _isLoading = true);
    
    await _notificationService.updateSettings(
      notificationsEnabled: _notificationsEnabled,
      stockAlertsEnabled: _stockAlertsEnabled,
      taskRemindersEnabled: _taskRemindersEnabled,
      saleAlertsEnabled: _saleAlertsEnabled,
    );
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de notificaciones actualizada'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showNotification(
      title: '🧪 Notificación de Prueba',
      body: 'Esta es una notificación de prueba de Stockcito',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.bell,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Notificaciones',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Personaliza las notificaciones del sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              )
            else
              Column(
                children: [
                  // Notificaciones generales
                  _buildSettingTile(
                    title: 'Notificaciones Generales',
                    subtitle: 'Activar/desactivar todas las notificaciones',
                    icon: FontAwesomeIcons.bell,
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        if (!value) {
                          _stockAlertsEnabled = false;
                          _taskRemindersEnabled = false;
                          _saleAlertsEnabled = false;
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Alertas de stock
                  _buildSettingTile(
                    title: 'Alertas de Stock Bajo',
                    subtitle: 'Notificaciones cuando el stock esté bajo',
                    icon: FontAwesomeIcons.triangleExclamation,
                    value: _stockAlertsEnabled,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _stockAlertsEnabled = value;
                        if (value) {
                          _notificationsEnabled = true;
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recordatorios de tareas
                  _buildSettingTile(
                    title: 'Recordatorios de Tareas',
                    subtitle: 'Notificaciones para tareas pendientes',
                    icon: FontAwesomeIcons.listCheck,
                    value: _taskRemindersEnabled,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _taskRemindersEnabled = value;
                        if (value) {
                          _notificationsEnabled = true;
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Alertas de ventas
                  _buildSettingTile(
                    title: 'Alertas de Ventas',
                    subtitle: 'Notificaciones de ventas importantes',
                    icon: FontAwesomeIcons.chartLine,
                    value: _saleAlertsEnabled,
                    enabled: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _saleAlertsEnabled = value;
                        if (value) {
                          _notificationsEnabled = true;
                        }
                      });
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _testNotification,
                          icon: const FaIcon(FontAwesomeIcons.flask, size: 16),
                          label: const Text('Probar Notificación'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _updateSettings,
                          icon: const FaIcon(FontAwesomeIcons.floppyDisk, size: 16),
                          label: const Text('Guardar Cambios'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circleInfo,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Las notificaciones solo están disponibles en Windows. En otras plataformas, las notificaciones se mostrarán en la interfaz de la aplicación.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? AppTheme.borderColor : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: enabled 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FaIcon(
              icon,
              color: enabled ? AppTheme.primaryColor : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled ? AppTheme.textPrimary : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? AppTheme.textSecondary : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppTheme.primaryColor,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
