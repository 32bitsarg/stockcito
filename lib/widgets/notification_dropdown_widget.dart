import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/notification_service.dart';

class NotificationDropdownWidget extends StatefulWidget {
  const NotificationDropdownWidget({Key? key}) : super(key: key);

  @override
  State<NotificationDropdownWidget> createState() => _NotificationDropdownWidgetState();
}

class _NotificationDropdownWidgetState extends State<NotificationDropdownWidget> {
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Map<String, Timer> _autoRemoveTimers = {};

  // Servicio de notificaciones
  final NotificationService _notificationService = NotificationService();
  
  // Lista de notificaciones reales
  List<NotificationItem> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRealNotifications();
  }

  // Cargar notificaciones reales del sistema
  Future<void> _loadRealNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener notificaciones programadas del sistema
      final scheduledNotifications = _notificationService.scheduledNotifications;
      
      // Convertir a NotificationItem para el dropdown
      final List<NotificationItem> realNotifications = [];
      
      for (final notification in scheduledNotifications) {
        realNotifications.add(NotificationItem(
          id: notification.id,
          title: notification.title,
          message: notification.body,
          icon: _getIconForType(notification.type),
          color: _getColorForType(notification.type),
          time: _formatTime(notification.scheduledTime),
          isRead: false,
        ));
      }

      // No agregar notificaciones de ejemplo - solo mostrar reales

      if (mounted) {
        setState(() {
          _notifications = realNotifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si hay error, mostrar lista vacía
      if (mounted) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
      }
    }
  }

  // Obtener icono basado en el tipo de notificación
  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.stockLow:
        return FontAwesomeIcons.triangleExclamation;
      case NotificationType.saleAlert:
        return FontAwesomeIcons.cartShopping;
      case NotificationType.taskReminder:
        return FontAwesomeIcons.clock;
      case NotificationType.systemUpdate:
        return FontAwesomeIcons.gear;
      case NotificationType.general:
        return FontAwesomeIcons.bell;
    }
  }

  // Obtener color basado en el tipo de notificación
  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.stockLow:
        return Colors.orange;
      case NotificationType.saleAlert:
        return Colors.green;
      case NotificationType.taskReminder:
        return Colors.blue;
      case NotificationType.systemUpdate:
        return Colors.purple;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  // Formatear tiempo relativo
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    }
  }


  @override
  void dispose() {
    // Solo remover overlay sin setState
    _overlayEntry?.remove();
    _overlayEntry = null;
    // Cancelar todos los timers activos
    _autoRemoveTimers.values.forEach((timer) => timer.cancel());
    _autoRemoveTimers.clear();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      // Recargar notificaciones reales al abrir
      _loadRealNotifications();
      _showOverlay();
    }
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  void _updateOverlay() {
    if (_isOpen && _overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: 320,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header del dropdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.bell,
                          color: Colors.blue.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Notificaciones',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: Text(
                            'Marcar todas',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Lista de notificaciones
                  Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                      child: _isLoading
                        ? _buildLoadingState()
                        : _notifications.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationItem(_notifications[index]);
                              },
                            ),
                  ),
                  
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cargando notificaciones...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.bellSlash,
            color: Colors.grey.shade400,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: notification.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            notification.icon,
            color: notification.color,
            size: 14,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              notification.time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeNotification(notification.id),
              child: Icon(
                FontAwesomeIcons.xmark,
                color: Colors.grey.shade400,
                size: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          _markAsRead(notification.id);
        },
      ),
    );
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        // Iniciar timer para eliminar la notificación leída después de 5 segundos
        _startAutoRemoveTimer(id);
      }
    });
    // Actualizar el overlay para reflejar los cambios
    _updateOverlay();
  }

  void _startAutoRemoveTimer(String notificationId) {
    // Cancelar timer existente para esta notificación si existe
    _autoRemoveTimers[notificationId]?.cancel();
    
    // Crear nuevo timer para esta notificación específica
    _autoRemoveTimers[notificationId] = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
          _autoRemoveTimers.remove(notificationId);
        });
        // Actualizar el overlay para reflejar los cambios
        _updateOverlay();
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        // Iniciar timer para eliminar cada notificación leída después de 5 segundos
        _startAutoRemoveTimer(_notifications[i].id);
      }
    });
    // Cerrar el dropdown después de marcar todas como leídas
    _removeOverlay();
  }

  void _removeNotification(String id) {
    // Cancelar timer específico para esta notificación
    _autoRemoveTimers[id]?.cancel();
    _autoRemoveTimers.remove(id);
    
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
    // Actualizar el overlay para reflejar los cambios
    _updateOverlay();
  }


  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Icon(
                FontAwesomeIcons.bell,
                color: Colors.grey.shade600,
                size: 14,
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
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
    );
  }
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final String time;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.time,
    required this.isRead,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    IconData? icon,
    Color? color,
    String? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}
