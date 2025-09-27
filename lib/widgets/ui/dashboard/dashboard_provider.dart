import 'package:flutter/material.dart';
import '../../../services/ui/dashboard/dashboard_state_service.dart';
import '../../../services/ui/dashboard/dashboard_logic_service.dart';
import '../../../services/ui/dashboard/dashboard_navigation_service.dart';

/// Provider que maneja todos los servicios del dashboard
class DashboardProvider extends InheritedWidget {
  final DashboardStateService stateService;
  final DashboardLogicService logicService;
  final DashboardNavigationService navigationService;

  const DashboardProvider({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required super.child,
  });

  static DashboardProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardProvider>();
  }

  static DashboardProvider require(BuildContext context) {
    final provider = of(context);
    assert(provider != null, 'DashboardProvider not found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(DashboardProvider oldWidget) {
    return stateService != oldWidget.stateService ||
           logicService != oldWidget.logicService ||
           navigationService != oldWidget.navigationService;
  }
}


