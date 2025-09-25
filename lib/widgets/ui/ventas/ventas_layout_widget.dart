import 'package:flutter/material.dart';
import '../../../services/ui/ventas/ventas_state_service.dart';
import '../../../services/ui/ventas/ventas_logic_service.dart';
import '../../../services/ui/ventas/ventas_navigation_service.dart';
import '../../../services/ui/ventas/ventas_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'ventas_content_widget.dart';

/// Widget que define el layout principal de la pantalla de ventas
class VentasLayoutWidget extends StatelessWidget {
  final VentasStateService stateService;
  final VentasLogicService logicService;
  final VentasNavigationService navigationService;
  final VentasDataService dataService;

  const VentasLayoutWidget({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo completamente blanco
      body: DashboardGlassmorphismWidget(
        child: VentasContentWidget(
          onNuevaVenta: () => navigationService.navigateToNuevaVenta(context),
        ),
      ),
    );
  }
}
