import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/sidebar/sidebar_data_service.dart';
import '../../../services/ui/sidebar/sidebar_state_service.dart';

/// Widget que muestra la sección de estado en el sidebar
class SidebarStatusSection extends StatefulWidget {
  final bool isExpanded;

  const SidebarStatusSection({
    super.key,
    this.isExpanded = false,
  });

  @override
  State<SidebarStatusSection> createState() => _SidebarStatusSectionState();
}

class _SidebarStatusSectionState extends State<SidebarStatusSection> {
  final SidebarStateService _stateService = SidebarStateService();
  
  @override
  void initState() {
    super.initState();
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _stateService.updateStream.listen((updateInfo) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = SidebarDataService().getSidebarStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.borderColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Estado de sincronización
          _buildSyncStatus(context, stats),
        ],
      ),
    );
  }

  Widget _buildSyncStatus(BuildContext context, SidebarStats stats) {
    return Row(
      children: [
        // Icono de estado
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.successColor,
            shape: BoxShape.circle,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Texto de estado
        Expanded(
          child: Text(
            'Sincronizado',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        
      ],
    );
  }

}
