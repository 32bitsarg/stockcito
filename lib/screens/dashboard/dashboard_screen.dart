import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/ui/dashboard/dashboard_layout_widget.dart';
import '../../widgets/ui/dashboard/dashboard_provider.dart';
import '../../services/ui/dashboard/dashboard_state_service.dart';
import '../../services/ui/dashboard/dashboard_logic_service.dart';
import '../../services/ui/dashboard/dashboard_navigation_service.dart';
import '../../services/system/logging_service.dart';

class DashboardScreen extends StatefulWidget {
  final int? initialIndex;
  
  const DashboardScreen({super.key, this.initialIndex});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Servicios del dashboard
  late final DashboardStateService _stateService;
  late final DashboardLogicService _logicService;
  late final DashboardNavigationService _navigationService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  // Nota: No disponemos el DashboardStateService porque es un singleton
  // compartido a nivel de app. Disponerlo aquí causa "used after being disposed"
  // al volver al Dashboard desde otras pantallas.
  @override
  void dispose() {
    super.dispose();
  }

  /// Inicializar servicios del dashboard
  Future<void> _initializeServices() async {
    try {
      LoggingService.info('🚀 Inicializando DashboardScreen...');
      
      // Inicializar servicios
      _stateService = DashboardStateService();
      _logicService = DashboardLogicService();
      _navigationService = DashboardNavigationService();
      
      // Inicializar lógica del dashboard
      await _logicService.initialize();
      
      // Si hay un índice inicial, seleccionarlo
      if (widget.initialIndex != null) {
        LoggingService.info('🎯 Seleccionando pantalla inicial: ${widget.initialIndex}');
        LoggingService.info('🔍 Estado actual del servicio: ${_stateService.selectedIndex}');
        _stateService.forceSelectScreen(widget.initialIndex!);
        LoggingService.info('🔍 Estado después de seleccionar: ${_stateService.selectedIndex}');
      }
      
      LoggingService.info('✅ DashboardScreen inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando DashboardScreen: $e');
    }
  }

  /// Manejar búsqueda
  void _handleSearch(String query) {
    _logicService.performSearch(query);
  }

  void _navigateToInventario() {
    _stateService.selectScreen(1); // Índice del inventario
  }

  void _handleActivityTap(Map<String, dynamic> actividad) {
    final tipo = actividad['tipo'] as String;
    
    switch (tipo.toLowerCase()) {
      case 'venta':
        _stateService.selectScreen(2); // Navegar a Ventas
        break;
      case 'producto':
        _stateService.selectScreen(1); // Navegar a Inventario
        break;
      case 'cliente':
        _stateService.selectScreen(3); // Navegar a Clientes
        break;
      default:
        // No hacer nada para otros tipos
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardStateService>.value(
      value: _stateService,
      child: DashboardProvider(
        stateService: _stateService,
        logicService: _logicService,
        navigationService: _navigationService,
        child: DashboardLayoutWidget(
          stateService: _stateService,
          navigationService: _navigationService,
          onSidebarItemSelected: () {
            setState(() {});
          },
          onSearch: _handleSearch,
          onNavigateToInventario: _navigateToInventario,
          onActivityTap: _handleActivityTap,
        ),
      ),
    );
  }

}
