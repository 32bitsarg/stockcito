import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class WindowsButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isEnabled;

  const WindowsButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.type = ButtonType.primary,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isWindows = Theme.of(context).platform == TargetPlatform.windows ||
                     Theme.of(context).platform == TargetPlatform.linux ||
                     Theme.of(context).platform == TargetPlatform.macOS;

    if (!isWindows) {
      // En móviles usar botones normales
      return ElevatedButton.icon(
        onPressed: isEnabled ? onPressed : null,
        icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
        label: Text(text),
      );
    }

    // En Windows usar estilo más profesional
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
        color: _getBackgroundColor(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (type == ButtonType.primary)
            BoxShadow(
              color: _getBackgroundColor().withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: _getTextColor(),
                  ),
                  const SizedBox(width: 10),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: _getTextColor(),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (!isEnabled) return Colors.grey[300]!;
    
    switch (type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.danger:
        return AppTheme.errorColor;
      case ButtonType.warning:
        return AppTheme.warningColor;
    }
  }

  Color _getTextColor() {
    if (!isEnabled) return Colors.grey[600]!;
    
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return AppTheme.textPrimary;
      case ButtonType.danger:
        return Colors.white;
      case ButtonType.warning:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    if (!isEnabled) return Colors.grey[400]!;
    
    switch (type) {
      case ButtonType.primary:
        return AppTheme.primaryColor;
      case ButtonType.secondary:
        return Colors.grey[300]!;
      case ButtonType.danger:
        return AppTheme.errorColor;
      case ButtonType.warning:
        return AppTheme.warningColor;
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  danger,
  warning,
}
