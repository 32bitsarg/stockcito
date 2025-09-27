import 'package:flutter/material.dart';
import '../../services/ui/reportes/reportes_state_service.dart';
import '../../services/ui/reportes/reportes_logic_service.dart';
import '../../services/ui/reportes/reportes_navigation_service.dart';
import '../../services/ui/reportes/reportes_data_service.dart';
import '../../widgets/ui/reportes/reportes_provider.dart';
import '../../widgets/ui/reportes/reportes_layout_widget.dart';

/// Pantalla de reportes refactorizada con separación de lógica y UI
class ModernReportesScreenRefactored extends StatefulWidget {
  const ModernReportesScreenRefactored({super.key});

  @override
  State<ModernReportesScreenRefactored> createState() => _ModernReportesScreenRefactoredState();
}

class _ModernReportesScreenRefactoredState extends State<ModernReportesScreenRefactored> {
  late final ReportesStateService _stateService;
  late final ReportesLogicService _logicService;
  late final ReportesNavigationService _navigationService;
  late final ReportesDataService _dataService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _stateService = ReportesStateService();
    _logicService = ReportesLogicService(_stateService);
    _navigationService = ReportesNavigationService();
    _dataService = ReportesDataService();
    
    // Inicializar y cargar datos
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _logicService.initialize();
      await _dataService.initialize();
      await _logicService.loadAllData();
    } catch (e) {
      // El error se maneja en los servicios
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportesProvider(
      stateService: _stateService,
      logicService: _logicService,
      navigationService: _navigationService,
      dataService: _dataService,
      child: ReportesLayoutWidget(
        stateService: _stateService,
        logicService: _logicService,
        navigationService: _navigationService,
        dataService: _dataService,
      ),
    );
  }

  @override
  void dispose() {
    _stateService.dispose();
    super.dispose();
  }
}


