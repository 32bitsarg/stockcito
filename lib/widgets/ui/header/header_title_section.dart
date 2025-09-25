import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Widget para la sección de título del header
class HeaderTitleSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showGreeting;
  final String? userName;

  const HeaderTitleSection({
    super.key,
    required this.title,
    this.subtitle,
    this.showGreeting = false,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Solo título principal - Sin saludo
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),

        // Subtítulo - Solo si existe
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ],
    );
  }
}
