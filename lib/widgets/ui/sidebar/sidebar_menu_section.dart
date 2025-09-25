import 'package:flutter/material.dart';
import '../../../services/ui/sidebar/sidebar_navigation_service.dart';

/// Widget que muestra la sección del menú en el sidebar
class SidebarMenuSection extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isExpanded;

  const SidebarMenuSection({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = SidebarNavigationService().getMenuItems();
    
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          final isActive = item.isActive(selectedIndex);
          
          return _buildMenuItem(context, item, isActive);
        },
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, SidebarMenuItem item, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(item.index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 16 : 8,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3C096C) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: isActive ? Border.all(
                color: const Color(0xFF3C096C).withOpacity(0.3),
                width: 1,
              ) : null,
            ),
            child: Row(
              children: [
                // Icon
                Icon(
                  item.icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                ),
                
                // Label (solo si está expandido)
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isActive ?  Colors.white : Colors.white.withOpacity(0.8),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
