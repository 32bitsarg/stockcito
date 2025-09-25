import 'package:flutter/material.dart';
import '../../services/ui/configuracion/configuracion_state_service.dart';
import '../../services/ui/configuracion/configuracion_logic_service.dart';
import '../../services/ui/configuracion/configuracion_navigation_service.dart';
import '../../services/ui/configuracion/configuracion_data_service.dart';
import '../../widgets/ui/configuracion/configuracion_provider.dart';
import '../../widgets/ui/configuracion/configuracion_layout_widget.dart';

/// Pantalla de configuración refactorizada con separación de lógica y UI
class ModernConfiguracionScreenRefactored extends StatefulWidget {
  const ModernConfiguracionScreenRefactored({super.key});

  @override
  State<ModernConfiguracionScreenRefactored> createState() => _ModernConfiguracionScreenRefactoredState();
}

class _ModernConfiguracionScreenRefactoredState extends State<ModernConfiguracionScreenRefactored> {
  late final ConfiguracionStateService _stateService;
  late final ConfiguracionLogicService _logicService;
  late final ConfiguracionNavigationService _navigationService;
  late final ConfiguracionDataService _dataService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _stateService = ConfiguracionStateService();
    _logicService = ConfiguracionLogicService(_stateService);
    _navigationService = ConfiguracionNavigationService();
    _dataService = ConfiguracionDataService();
    
    // Cargar configuración inicial
    _loadInitialConfiguracion();
  }

  Future<void> _loadInitialConfiguracion() async {
    try {
      await _logicService.loadConfiguracion();
    } catch (e) {
      // El error se maneja en el servicio
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConfiguracionProvider(
      stateService: _stateService,
      logicService: _logicService,
      navigationService: _navigationService,
      dataService: _dataService,
      child: ConfiguracionLayoutWidget(
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
