import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/notification_service.dart';

class NotificationBanner extends StatefulWidget {
  final NotificationData notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const NotificationBanner({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onTap,
  });

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: _getBorderColor(),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icono
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getIconBackgroundColor(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: FaIcon(
                            _getIcon(),
                            color: _getIconColor(),
                            size: 20,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Contenido
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notification.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.notification.body,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(widget.notification.scheduledTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Botón de cerrar
                        IconButton(
                          onPressed: _dismiss,
                          icon: const FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor() {
    switch (widget.notification.type) {
      case NotificationType.stockLow:
        return AppTheme.warningColor.withOpacity(0.1);
      case NotificationType.saleAlert:
        return AppTheme.successColor.withOpacity(0.1);
      case NotificationType.taskReminder:
        return AppTheme.primaryColor.withOpacity(0.1);
      case NotificationType.systemUpdate:
        return AppTheme.accentColor.withOpacity(0.1);
      case NotificationType.general:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getBorderColor() {
    switch (widget.notification.type) {
      case NotificationType.stockLow:
        return AppTheme.warningColor.withOpacity(0.3);
      case NotificationType.saleAlert:
        return AppTheme.successColor.withOpacity(0.3);
      case NotificationType.taskReminder:
        return AppTheme.primaryColor.withOpacity(0.3);
      case NotificationType.systemUpdate:
        return AppTheme.accentColor.withOpacity(0.3);
      case NotificationType.general:
        return Colors.grey.withOpacity(0.3);
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.notification.type) {
      case NotificationType.stockLow:
        return AppTheme.warningColor.withOpacity(0.2);
      case NotificationType.saleAlert:
        return AppTheme.successColor.withOpacity(0.2);
      case NotificationType.taskReminder:
        return AppTheme.primaryColor.withOpacity(0.2);
      case NotificationType.systemUpdate:
        return AppTheme.accentColor.withOpacity(0.2);
      case NotificationType.general:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getIconColor() {
    switch (widget.notification.type) {
      case NotificationType.stockLow:
        return AppTheme.warningColor;
      case NotificationType.saleAlert:
        return AppTheme.successColor;
      case NotificationType.taskReminder:
        return AppTheme.primaryColor;
      case NotificationType.systemUpdate:
        return AppTheme.accentColor;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  IconData _getIcon() {
    switch (widget.notification.type) {
      case NotificationType.stockLow:
        return FontAwesomeIcons.triangleExclamation;
      case NotificationType.saleAlert:
        return FontAwesomeIcons.chartLine;
      case NotificationType.taskReminder:
        return FontAwesomeIcons.listCheck;
      case NotificationType.systemUpdate:
        return FontAwesomeIcons.gear;
      case NotificationType.general:
        return FontAwesomeIcons.bell;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}

class NotificationList extends StatefulWidget {
  final List<NotificationData> notifications;
  final Function(NotificationData)? onNotificationTap;
  final Function(NotificationData)? onNotificationDismiss;

  const NotificationList({
    super.key,
    required this.notifications,
    this.onNotificationTap,
    this.onNotificationDismiss,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  @override
  Widget build(BuildContext context) {
    if (widget.notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.bellSlash,
              size: 48,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No hay notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Las notificaciones aparecerán aquí',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.notifications.length,
      itemBuilder: (context, index) {
        final notification = widget.notifications[index];
        return NotificationBanner(
          notification: notification,
          onTap: () => widget.onNotificationTap?.call(notification),
          onDismiss: () => widget.onNotificationDismiss?.call(notification),
        );
      },
    );
  }
}
