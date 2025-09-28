import 'package:flutter/material.dart';
import '../../services/ui/clientes/clientes_state_service.dart';
import '../../services/ui/clientes/clientes_logic_service.dart';
import '../../services/ui/clientes/clientes_navigation_service.dart';
import '../../services/ui/clientes/clientes_data_service.dart';
import '../../widgets/ui/clientes/clientes_provider.dart';
import '../../widgets/ui/clientes/clientes_layout_widget.dart';

/// Pantalla de clientes refactorizada con separación de lógica y UI
class ModernClientesScreenRefactored extends StatefulWidget {
  const ModernClientesScreenRefactored({super.key});

  @override
  State<ModernClientesScreenRefactored> createState() => _ModernClientesScreenRefactoredState();
}

class _ModernClientesScreenRefactoredState extends State<ModernClientesScreenRefactored> {
  late final ClientesStateService _stateService;
  late final ClientesLogicService _logicService;
  late final ClientesNavigationService _navigationService;
  late final ClientesDataService _dataService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    _stateService = ClientesStateService();
    _logicService = ClientesLogicService(_stateService);
    _navigationService = ClientesNavigationService();
    _dataService = ClientesDataService();
    
    // Inicializar y cargar datos
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _logicService.initialize();
      await _dataService.initialize();
      await _logicService.loadClientes();
    } catch (e) {
      // El error se maneja en los servicios
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClientesProvider(
      stateService: _stateService,
      logicService: _logicService,
      navigationService: _navigationService,
      dataService: _dataService,
      child: ClientesLayoutWidget(
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




