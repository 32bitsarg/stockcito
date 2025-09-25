import 'package:flutter/material.dart';
import '../../../services/ui/calculadora/calculadora_state_service.dart';
import '../../../services/ui/calculadora/calculadora_logic_service.dart';
import '../../../services/ui/calculadora/calculadora_navigation_service.dart';
import '../../../services/ui/calculadora/calculadora_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'calculadora_content_widget.dart';

/// Widget que define el layout principal de la pantalla de calculadora
class CalculadoraLayoutWidget extends StatelessWidget {
  final CalculadoraStateService stateService;
  final CalculadoraLogicService logicService;
  final CalculadoraNavigationService navigationService;
  final CalculadoraDataService dataService;

  const CalculadoraLayoutWidget({
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
        child: const CalculadoraContentWidget(),
      ),
    );
  }
}
