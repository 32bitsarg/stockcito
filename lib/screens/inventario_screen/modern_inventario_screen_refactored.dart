import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ui/inventario/inventario_state_service.dart';
import '../../services/ui/inventario/inventario_logic_service.dart';
import '../../services/ui/inventario/inventario_navigation_service.dart';
import '../../services/ui/inventario/inventario_data_service.dart';
import '../../widgets/ui/inventario/inventario_layout_widget.dart';

/// Pantalla moderna del inventario con arquitectura separada
class ModernInventarioScreenRefactored extends StatefulWidget {
  const ModernInventarioScreenRefactored({super.key});

  @override
  State<ModernInventarioScreenRefactored> createState() => _ModernInventarioScreenRefactoredState();
}

class _ModernInventarioScreenRefactoredState extends State<ModernInventarioScreenRefactored> with WidgetsBindingObserver {
  late final InventarioStateService _stateService;
  late final InventarioLogicService _logicService;
  late final InventarioNavigationService _navigationService;
  late final InventarioDataService _dataService;

  @override
  void initState() {
    super.initState();
    
    // Inicializar servicios
    _stateService = InventarioStateService();
    _logicService = InventarioLogicService();
    _navigationService = InventarioNavigationService();
    _dataService = InventarioDataService();
    
    // Configurar observador de ciclo de vida
    WidgetsBinding.instance.addObserver(this);
    
    // Cargar datos iniciales
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recargar datos cuando la app vuelve a estar activa
      _logicService.refreshData();
    }
  }

  /// Inicializar datos
  Future<void> _initializeData() async {
    try {
      await _dataService.initialize();
      await _logicService.loadAllData();
    } catch (e) {
      // Error manejado por los servicios
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<InventarioStateService>.value(
      value: _stateService,
      child: InventarioLayoutWidget(
        stateService: _stateService,
        logicService: _logicService,
        navigationService: _navigationService,
        dataService: _dataService,
      ),
    );
  }
}
