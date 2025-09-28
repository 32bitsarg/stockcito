import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/configuracion/configuracion_state_service.dart';
import '../../../services/ui/configuracion/configuracion_logic_service.dart';
import '../../../services/ui/configuracion/configuracion_navigation_service.dart';
import '../../../services/ui/configuracion/configuracion_data_service.dart';

/// Provider que hace accesibles los servicios de configuración a los widgets descendientes
class ConfiguracionProvider extends StatelessWidget {
  final ConfiguracionStateService stateService;
  final ConfiguracionLogicService logicService;
  final ConfiguracionNavigationService navigationService;
  final ConfiguracionDataService dataService;
  final Widget child;

  const ConfiguracionProvider({
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
        ChangeNotifierProvider<ConfiguracionStateService>.value(value: stateService),
        Provider<ConfiguracionLogicService>.value(value: logicService),
        Provider<ConfiguracionNavigationService>.value(value: navigationService),
        Provider<ConfiguracionDataService>.value(value: dataService),
      ],
      child: child,
    );
  }
}




