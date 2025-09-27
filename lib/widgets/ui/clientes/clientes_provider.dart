import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/clientes/clientes_state_service.dart';
import '../../../services/ui/clientes/clientes_logic_service.dart';
import '../../../services/ui/clientes/clientes_navigation_service.dart';
import '../../../services/ui/clientes/clientes_data_service.dart';

/// Provider que hace accesibles los servicios de clientes a los widgets descendientes
class ClientesProvider extends StatelessWidget {
  final ClientesStateService stateService;
  final ClientesLogicService logicService;
  final ClientesNavigationService navigationService;
  final ClientesDataService dataService;
  final Widget child;

  const ClientesProvider({
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
        ChangeNotifierProvider<ClientesStateService>.value(value: stateService),
        Provider<ClientesLogicService>.value(value: logicService),
        Provider<ClientesNavigationService>.value(value: navigationService),
        Provider<ClientesDataService>.value(value: dataService),
      ],
      child: child,
    );
  }
}


