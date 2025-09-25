import 'package:flutter/material.dart';
import '../../services/ui/ventas/ventas_state_service.dart';
import '../../services/ui/ventas/ventas_logic_service.dart';
import '../../services/ui/ventas/ventas_navigation_service.dart';
import '../../services/ui/ventas/ventas_data_service.dart';
import '../../widgets/ui/ventas/ventas_provider.dart';
import '../../widgets/ui/ventas/ventas_layout_widget.dart';

/// Pantalla de ventas refactorizada con separación de lógica y UI
class ModernVentasScreenRefactored extends StatefulWidget {
  const ModernVentasScreenRefactored({super.key});

  @override
  State<ModernVentasScreenRefactored> createState() => _ModernVentasScreenRefactoredState();
}

class _ModernVentasScreenRefactoredState extends State<ModernVentasScreenRefactored> {
  late final VentasStateService _stateService;
  late final VentasLogicService _logicService;
  late final VentasNavigationService _navigationService;
  late final VentasDataService _dataService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _stateService = VentasStateService();
    _logicService = VentasLogicService(_stateService);
    _navigationService = VentasNavigationService();
    _dataService = VentasDataService();
    
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
    return VentasProvider(
      stateService: _stateService,
      logicService: _logicService,
      navigationService: _navigationService,
      dataService: _dataService,
      child: VentasLayoutWidget(
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
