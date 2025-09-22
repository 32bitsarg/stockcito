import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../calcularprecios_screen/modern_calculadora_precios_screen.dart';
import '../../inventario_screen/modern_inventario_screen.dart';
import '../../reportes_screen/modern_reportes_screen.dart';
import '../../ventas_screen/modern_ventas_screen.dart';
import '../../clientes_screen/gestión_clientes_screen.dart';
import '../../configuracion_screen/modern_configuracion_screen.dart';

class DashboardMenuItems {
  static const List<Map<String, dynamic>> _menuItems = [
    {
      'label': 'Dashboard',
      'icon': FontAwesomeIcons.house,
      'color': AppTheme.primaryColor,
    },
    {
      'label': 'Inventario',
      'icon': FontAwesomeIcons.boxesStacked,
      'color': AppTheme.successColor,
    },
    {
      'label': 'Ventas',
      'icon': FontAwesomeIcons.chartLine,
      'color': AppTheme.warningColor,
    },
    {
      'label': 'Clientes',
      'icon': FontAwesomeIcons.users,
      'color': AppTheme.accentColor,
    },
    {
      'label': 'Reportes',
      'icon': FontAwesomeIcons.chartBar,
      'color': AppTheme.primaryColor,
    },
    {
      'label': 'Cálculo de Precios',
      'icon': FontAwesomeIcons.calculator,
      'color': AppTheme.errorColor,
    },
    {
      'label': 'Configuración',
      'icon': FontAwesomeIcons.gear,
      'color': AppTheme.textSecondary,
    },
  ];

  static String getLabel(int index) {
    if (index >= 0 && index < _menuItems.length) {
      return _menuItems[index]['label'];
    }
    return '';
  }

  static IconData getIcon(int index) {
    if (index >= 0 && index < _menuItems.length) {
      return _menuItems[index]['icon'];
    }
    return FontAwesomeIcons.house;
  }

  static Color getColor(int index) {
    if (index >= 0 && index < _menuItems.length) {
      return _menuItems[index]['color'];
    }
    return AppTheme.primaryColor;
  }

  static String getSubtitle(int index) {
    switch (index) {
      case 1:
        return 'Gestiona tu inventario de productos';
      case 2:
        return 'Registra y consulta las ventas';
      case 3:
        return 'Administra tu base de clientes';
      case 4:
        return 'Genera reportes y análisis';
      case 5:
        return 'Calcula precios y costos';
      case 6:
        return 'Configura la aplicación';
      default:
        return 'Panel principal de control';
    }
  }

  static Widget getScreen(int index) {
    switch (index) {
      case 1:
        return const ModernInventarioScreen();
      case 2:
        return const ModernVentasScreen();
      case 3:
        return const GestionClientesScreen();
      case 4:
        return const ModernReportesScreen();
      case 5:
        return const ModernCalculadoraPreciosScreen();
      case 6:
        return const ModernConfiguracionScreen();
      default:
        return const SizedBox();
    }
  }

  static List<Map<String, dynamic>> get allItems => _menuItems;
}
