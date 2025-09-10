import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';

class ModernHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextEditingController? searchController;
  final VoidCallback? onSearch;
  final List<Widget>? actions;

  const ModernHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchController,
    this.onSearch,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Search bar
          if (searchController != null) ...[
            Container(
              width: 320,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (_) => onSearch?.call(),
                decoration: InputDecoration(
                  hintText: 'Buscar productos, clientes...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: searchController!.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.xmark,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            searchController!.clear();
                            onSearch?.call();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Actions
          if (actions != null) ...[
            Row(
              children: actions!,
            ),
            const SizedBox(width: 16),
          ],
          
          // Profile section
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              FontAwesomeIcons.user,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
