import 'package:flutter/material.dart';
import '../../system/logging_service.dart';
import '../../../screens/dashboard/models/dashboard_menu_items.dart';

/// Servicio que maneja la navegación del dashboard
class DashboardNavigationService {
  static final DashboardNavigationService _instance = DashboardNavigationService._internal();
  factory DashboardNavigationService() => _instance;
  DashboardNavigationService._internal();

  /// Navegar a una pantalla específica
  void navigateToScreen(int index, VoidCallback onNavigation) {
    try {
      LoggingService.info('🧭 Navegando a pantalla: $index');
      onNavigation();
    } catch (e) {
      LoggingService.error('❌ Error navegando a pantalla $index: $e');
    }
  }

  /// Obtener información de la pantalla actual
  Map<String, String> getScreenInfo(int selectedIndex) {
    final title = DashboardMenuItems.getLabel(selectedIndex);
    final subtitle = DashboardMenuItems.getSubtitle(selectedIndex);
    final context = selectedIndex == 0 ? 'dashboard' : DashboardMenuItems.getLabel(selectedIndex).toLowerCase();
    
    // 🔍 DEBUG: Log del servicio de navegación
    print('🔍 [DEBUG] DashboardNavigationService.getScreenInfo:');
    print('   - selectedIndex: $selectedIndex');
    print('   - title: $title');
    print('   - subtitle: $subtitle');
    print('   - context: $context');
    
    return {
      'title': title,
      'subtitle': subtitle,
      'context': context,
    };
  }

  /// Verificar si una pantalla está disponible
  bool isScreenAvailable(int index) {
    return index >= 0 && index < DashboardMenuItems.allItems.length;
  }

  /// Obtener la pantalla correspondiente
  Widget getScreen(int index) {
    if (!isScreenAvailable(index)) {
      LoggingService.warning('⚠️ Pantalla no disponible: $index');
      return const Center(
        child: Text('Pantalla no disponible'),
      );
    }

    return DashboardMenuItems.getScreen(index);
  }

  /// Obtener todas las pantallas disponibles
  List<Map<String, dynamic>> getAvailableScreens() {
    final screens = <Map<String, dynamic>>[];
    
    for (int i = 0; i < DashboardMenuItems.allItems.length; i++) {
      screens.add({
        'index': i,
        'title': DashboardMenuItems.getLabel(i),
        'subtitle': DashboardMenuItems.getSubtitle(i),
        'context': i == 0 ? 'dashboard' : DashboardMenuItems.getLabel(i).toLowerCase(),
      });
    }
    
    return screens;
  }

  /// Obtener estadísticas de navegación
  Map<String, dynamic> getNavigationStats() {
    return {
      'totalScreens': DashboardMenuItems.allItems.length,
      'availableScreens': getAvailableScreens(),
      'currentScreen': 'dashboard', // Se actualiza dinámicamente
    };
  }
}
