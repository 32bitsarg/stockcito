import 'package:flutter/material.dart';
import '../../services/ui/calculadora/calculadora_state_service.dart';
import '../../services/ui/calculadora/calculadora_logic_service.dart';
import '../../services/ui/calculadora/calculadora_navigation_service.dart';
import '../../services/ui/calculadora/calculadora_data_service.dart';
import '../../widgets/ui/calculadora/calculadora_provider.dart';
import '../../widgets/ui/calculadora/calculadora_layout_widget.dart';

/// Pantalla de calculadora de precios refactorizada con separación de lógica y UI
class ModernCalculadoraPreciosScreenRefactored extends StatefulWidget {
  final bool showCloseButton;
  
  const ModernCalculadoraPreciosScreenRefactored({
    super.key,
    this.showCloseButton = false,
  });

  @override
  State<ModernCalculadoraPreciosScreenRefactored> createState() => _ModernCalculadoraPreciosScreenRefactoredState();
}

class _ModernCalculadoraPreciosScreenRefactoredState extends State<ModernCalculadoraPreciosScreenRefactored> {
  late final CalculadoraStateService _stateService;
  late final CalculadoraLogicService _logicService;
  late final CalculadoraNavigationService _navigationService;
  late final CalculadoraDataService _dataService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _stateService = CalculadoraStateService();
    _logicService = CalculadoraLogicService(_stateService);
    _navigationService = CalculadoraNavigationService();
    _dataService = CalculadoraDataService();
    
    // Inicializar y cargar datos
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _logicService.initialize();
      await _dataService.initialize();
    } catch (e) {
      // El error se maneja en los servicios
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalculadoraProvider(
      stateService: _stateService,
      logicService: _logicService,
      navigationService: _navigationService,
      dataService: _dataService,
      child: CalculadoraLayoutWidget(
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
