import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/sidebar/sidebar_data_service.dart';

/// Widget que muestra la sección del logo en el sidebar
class SidebarLogoSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback? onTap;

  const SidebarLogoSection({
    super.key,
    this.isExpanded = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoInfo = SidebarDataService().getLogoInfo();
    
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF3C096C), // Púrpura oscuro
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Logo icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      logoInfo.logoText,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                
                // App name (solo si está expandido)
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logoInfo.appName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'v${logoInfo.version}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
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
