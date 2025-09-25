import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/header/header_navigation_service.dart';

/// Widget para la sección de acciones del header
class HeaderActionsSection extends StatelessWidget {
  final List<HeaderNavigationAction> actions;
  final bool showNotifications;
  final String? notificationBadge;

  const HeaderActionsSection({
    super.key,
    required this.actions,
    this.showNotifications = true,
    this.notificationBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Solo acciones personalizadas
        ...actions.map((action) => _buildActionButton(context, action)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, HeaderNavigationAction action) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.isEnabled ? action.onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: action.color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 14,
                  color: action.isEnabled ? action.color : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: action.isEnabled ? action.color : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
                if (action.badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      action.badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

}
