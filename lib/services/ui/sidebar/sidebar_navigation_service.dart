import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

/// Servicio que maneja la lógica de navegación del sidebar
class SidebarNavigationService {
  static final SidebarNavigationService _instance = SidebarNavigationService._internal();
  factory SidebarNavigationService() => _instance;
  SidebarNavigationService._internal();

  /// Obtiene los elementos del menú con su configuración
  List<SidebarMenuItem> getMenuItems() {
    return [
      SidebarMenuItem(
        icon: Icons.dashboard_outlined,
        label: 'Dashboard',
        color: AppTheme.primaryColor,
        index: 0,
      ),
      SidebarMenuItem(
        icon: Icons.inventory_2_outlined,
        label: 'Inventario',
        color: AppTheme.successColor,
        index: 1,
      ),
      SidebarMenuItem(
        icon: Icons.trending_up_outlined,
        label: 'Ventas',
        color: AppTheme.warningColor,
        index: 2,
      ),
      SidebarMenuItem(
        icon: Icons.people_outline,
        label: 'Clientes',
        color: AppTheme.accentColor,
        index: 3,
      ),
      SidebarMenuItem(
        icon: Icons.analytics_outlined,
        label: 'Reportes',
        color: AppTheme.primaryColor,
        index: 4,
      ),
      SidebarMenuItem(
        icon: Icons.calculate_outlined,
        label: 'Cálculo de Precios',
        color: AppTheme.errorColor,
        index: 5,
      ),
      SidebarMenuItem(
        icon: Icons.settings_outlined,
        label: 'Configuración',
        color: AppTheme.textSecondary,
        index: 6,
      ),
    ];
  }

  /// Valida si un índice de menú es válido
  bool isValidMenuIndex(int index) {
    final menuItems = getMenuItems();
    return index >= 0 && index < menuItems.length;
  }

  /// Obtiene un elemento del menú por su índice
  SidebarMenuItem? getMenuItemByIndex(int index) {
    if (!isValidMenuIndex(index)) return null;
    return getMenuItems()[index];
  }

  /// Obtiene el índice del elemento activo basado en la ruta actual
  int getActiveIndexFromRoute(String routeName) {
    switch (routeName) {
      case '/dashboard':
        return 0;
      case '/inventario':
        return 1;
      case '/ventas':
        return 2;
      case '/clientes':
        return 3;
      case '/reportes':
        return 4;
      case '/calcular-precios':
        return 5;
      case '/configuracion':
        return 6;
      default:
        return 0;
    }
  }
}

/// Modelo para los elementos del menú del sidebar
class SidebarMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final int index;

  const SidebarMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.index,
  });

  /// Verifica si este elemento está activo
  bool isActive(int selectedIndex) {
    return index == selectedIndex;
  }

  /// Obtiene el color apropiado basado en el estado
  Color getDisplayColor(int selectedIndex) {
    return isActive(selectedIndex) ? color : AppTheme.textSecondary;
  }
}
