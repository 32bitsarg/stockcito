import 'package:flutter/material.dart';
import '../../../services/ui/dashboard/dashboard_state_service.dart';
import '../../../services/ui/dashboard/dashboard_navigation_service.dart';
import 'modern_dashboard_content_widget.dart';

/// Widget que maneja el contenido del dashboard
class DashboardContentWidget extends StatelessWidget {
  final DashboardStateService stateService;
  final DashboardNavigationService navigationService;
  final VoidCallback? onNavigateToInventario;
  final Function(Map<String, dynamic> actividad)? onActivityTap;

  const DashboardContentWidget({
    super.key,
    required this.stateService,
    required this.navigationService,
    this.onNavigateToInventario,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return ModernDashboardContentWidget(
      stateService: stateService,
      navigationService: navigationService,
      onNavigateToInventario: onNavigateToInventario,
      onActivityTap: onActivityTap,
    );
  }
}
