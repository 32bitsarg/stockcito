import 'package:flutter/material.dart';
import '../../../services/ui/reportes/reportes_state_service.dart';
import '../../../services/ui/reportes/reportes_logic_service.dart';
import '../../../services/ui/reportes/reportes_navigation_service.dart';
import '../../../services/ui/reportes/reportes_data_service.dart';
import '../dashboard/dashboard_glassmorphism_widget.dart';
import 'reportes_content_widget.dart';

/// Widget que define el layout principal de la pantalla de reportes
class ReportesLayoutWidget extends StatelessWidget {
  final ReportesStateService stateService;
  final ReportesLogicService logicService;
  final ReportesNavigationService navigationService;
  final ReportesDataService dataService;

  const ReportesLayoutWidget({
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
        child: const ReportesContentWidget(),
      ),
    );
  }
}

