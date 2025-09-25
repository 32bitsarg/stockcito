import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/calculadora/calculadora_state_service.dart';
import '../../../services/ui/calculadora/calculadora_logic_service.dart';
import '../../../services/ui/calculadora/calculadora_navigation_service.dart';
import '../../../services/ui/calculadora/calculadora_data_service.dart';

/// Provider que hace accesibles los servicios de calculadora a los widgets descendientes
class CalculadoraProvider extends StatelessWidget {
  final CalculadoraStateService stateService;
  final CalculadoraLogicService logicService;
  final CalculadoraNavigationService navigationService;
  final CalculadoraDataService dataService;
  final Widget child;

  const CalculadoraProvider({
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
        ChangeNotifierProvider<CalculadoraStateService>.value(value: stateService),
        Provider<CalculadoraLogicService>.value(value: logicService),
        Provider<CalculadoraNavigationService>.value(value: navigationService),
        Provider<CalculadoraDataService>.value(value: dataService),
      ],
      child: child,
    );
  }
}
