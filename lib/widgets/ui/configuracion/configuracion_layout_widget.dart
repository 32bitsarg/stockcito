import 'package:flutter/material.dart';
import '../../../services/ui/configuracion/configuracion_state_service.dart';
import '../../../services/ui/configuracion/configuracion_logic_service.dart';
import '../../../services/ui/configuracion/configuracion_navigation_service.dart';
import '../../../services/ui/configuracion/configuracion_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'configuracion_content_widget.dart';

/// Widget que define el layout principal de la pantalla de configuración
class ConfiguracionLayoutWidget extends StatelessWidget {
  final ConfiguracionStateService stateService;
  final ConfiguracionLogicService logicService;
  final ConfiguracionNavigationService navigationService;
  final ConfiguracionDataService dataService;

  const ConfiguracionLayoutWidget({
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
        child: const ConfiguracionContentWidget(),
      ),
    );
  }
}

