import 'package:flutter/material.dart';
import '../../../services/ui/inventario/inventario_state_service.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../../../services/ui/inventario/inventario_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'inventario_provider.dart';
import 'inventario_content_widget.dart';

/// Widget que maneja el layout principal del inventario
class InventarioLayoutWidget extends StatelessWidget {
  final InventarioStateService stateService;
  final InventarioLogicService logicService;
  final InventarioNavigationService navigationService;
  final InventarioDataService dataService;

  const InventarioLayoutWidget({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return InventarioProvider(
      stateService: stateService,
      logicService: logicService,
      navigationService: navigationService,
      dataService: dataService,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: DashboardGlassmorphismWidget(
          child: InventarioContentWidget(),
        ),
      ),
    );
  }
}
