import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/reportes/reportes_state_service.dart';
import '../../../services/ui/reportes/reportes_logic_service.dart';
import '../../../services/ui/reportes/reportes_navigation_service.dart';
import '../../../services/ui/reportes/reportes_data_service.dart';

/// Provider que hace accesibles los servicios de reportes a los widgets descendientes
class ReportesProvider extends StatelessWidget {
  final ReportesStateService stateService;
  final ReportesLogicService logicService;
  final ReportesNavigationService navigationService;
  final ReportesDataService dataService;
  final Widget child;

  const ReportesProvider({
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
        ChangeNotifierProvider<ReportesStateService>.value(value: stateService),
        Provider<ReportesLogicService>.value(value: logicService),
        Provider<ReportesNavigationService>.value(value: navigationService),
        Provider<ReportesDataService>.value(value: dataService),
      ],
      child: child,
    );
  }
}


