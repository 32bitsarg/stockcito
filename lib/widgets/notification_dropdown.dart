import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ricitosdebb/config/app_theme.dart';
import 'package:ricitosdebb/services/notification_service.dart';

class NotificationDropdown extends StatefulWidget {
  const NotificationDropdown({Key? key}) : super(key: key);

  @override
  State<NotificationDropdown> createState() => _NotificationDropdownState();
}

class _NotificationDropdownState extends State<NotificationDropdown> {
  final NotificationService _notificationService = NotificationService();
  bool _isOpen = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simular notificaciones por ahora
    setState(() {
      _notifications = [
        {
          'id': '1',
          'title': 'Stock bajo detectado',
          'message': 'El producto "Camiseta Azul" tiene stock bajo (5 unidades)',
          'time': DateTime.now().subtract(const Duration(minutes: 30)),
          'type': 'stock_low',
          'isRead': false,
        },
        {
          'id': '2',
          'title': 'Recomendación de IA',
          'message': 'La IA sugiere aumentar el stock de "Pantalón Negro"',
          'time': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'ai_recommendation',
          'isRead': false,
        },
        {
          'id': '3',
          'title': 'Venta registrada',
          'message': 'Nueva venta por \$150.00 registrada exitosamente',
          'time': DateTime.now().subtract(const Duration(hours: 4)),
          'type': 'sale',
          'isRead': true,
        },
      ];
    });
  }

  int get _unreadCount => _notifications.where((n) => !n['isRead']).length;

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'stock_low':
        return AppTheme.errorColor;
      case 'ai_recommendation':
        return AppTheme.warningColor;
      case 'sale':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'stock_low':
        return FontAwesomeIcons.triangleExclamation;
      case 'ai_recommendation':
        return FontAwesomeIcons.lightbulb;
      case 'sale':
        return FontAwesomeIcons.checkCircle;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Botón de notificaciones
        IconButton(
          onPressed: () {
            setState(() {
              _isOpen = !_isOpen;
            });
          },
          icon: Icon(
            FontAwesomeIcons.bell,
            color: AppTheme.textPrimary,
            size: 20,
          ),
        ),
        
        // Badge de notificaciones no leídas
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.errorColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        
        // Desplegable de notificaciones
        if (_isOpen)
          Positioned(
            right: 0,
            top: 50,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 350,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header del desplegable
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.bell,
                            color: AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Notificaciones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (_unreadCount > 0)
                            TextButton(
                              onPressed: _markAllAsRead,
                              child: Text(
                                'Marcar todas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Lista de notificaciones
                    Expanded(
                      child: _notifications.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return _buildNotificationItem(notification);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FontAwesomeIcons.bellSlash,
            color: AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = !notification['isRead'];
    final color = _getNotificationColor(notification['type']);
    final icon = _getNotificationIcon(notification['type']);
    
    return InkWell(
      onTap: () => _markAsRead(notification['id']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnread 
              ? AppTheme.primaryColor.withOpacity(0.05)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.borderColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono de notificación
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            // Contenido de la notificación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification['time']),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
