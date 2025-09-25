import 'package:flutter/material.dart';
import '../../../services/ui/inventario/inventario_state_service.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../../../services/ui/inventario/inventario_data_service.dart';

/// Provider que hace accesibles los servicios del inventario a los widgets hijos
class InventarioProvider extends InheritedWidget {
  final InventarioStateService stateService;
  final InventarioLogicService logicService;
  final InventarioNavigationService navigationService;
  final InventarioDataService dataService;

  const InventarioProvider({
    super.key,
    required this.stateService,
    required this.logicService,
    required this.navigationService,
    required this.dataService,
    required super.child,
  });

  /// Obtener el provider desde el contexto
  static InventarioProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InventarioProvider>();
  }

  /// Obtener el provider desde el contexto (con null safety)
  static InventarioProvider ofNotNull(BuildContext context) {
    final provider = of(context);
    if (provider == null) {
      throw FlutterError(
        'InventarioProvider not found in context. '
        'Make sure to wrap your widget with InventarioProvider.',
      );
    }
    return provider;
  }

  @override
  bool updateShouldNotify(InventarioProvider oldWidget) {
    return stateService != oldWidget.stateService ||
           logicService != oldWidget.logicService ||
           navigationService != oldWidget.navigationService ||
           dataService != oldWidget.dataService;
  }
}

