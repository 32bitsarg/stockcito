import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/ventas/ventas_state_service.dart';
import '../../../services/ui/ventas/ventas_logic_service.dart';
import '../../../services/ui/ventas/ventas_navigation_service.dart';
import '../../../services/ui/ventas/ventas_data_service.dart';

/// Provider que hace accesibles los servicios de ventas a los widgets descendientes
class VentasProvider extends StatelessWidget {
  final VentasStateService stateService;
  final VentasLogicService logicService;
  final VentasNavigationService navigationService;
  final VentasDataService dataService;
  final Widget child;

  const VentasProvider({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VentasStateService>.value(value: stateService),
        Provider<VentasLogicService>.value(value: logicService),
        Provider<VentasNavigationService>.value(value: navigationService),
        Provider<VentasDataService>.value(value: dataService),
      ],
      child: child,
    );
  }
}
