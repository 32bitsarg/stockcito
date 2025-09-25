import 'package:flutter/material.dart';
import '../../system/logging_service.dart';
import '../../../screens/dashboard/models/dashboard_menu_items.dart';

/// Servicio que maneja el estado del dashboard
class DashboardStateService extends ChangeNotifier {
  static final DashboardStateService _instance = DashboardStateService._internal();
  factory DashboardStateService() => _instance;
  DashboardStateService._internal() {
    print('🔍 [DEBUG] DashboardStateService inicializado con selectedIndex: $_selectedIndex');
  }

  // Estado del dashboard
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  String _currentSearchQuery = '';

  // Getters
  int get selectedIndex => _selectedIndex;
  TextEditingController get searchController => _searchController;
  bool get isSearchActive => _isSearchActive;
  String get currentSearchQuery => _currentSearchQuery;

  /// Cambiar la pantalla seleccionada
  void selectScreen(int index) {
    print('🔍 [DEBUG] DashboardStateService.selectScreen:');
    print('   - Estado actual: $_selectedIndex');
    print('   - Nuevo índice: $index');
    print('   - Pantalla anterior: ${DashboardMenuItems.getLabel(_selectedIndex)}');
    print('   - Pantalla nueva: ${DashboardMenuItems.getLabel(index)}');
    
    _selectedIndex = index;
    LoggingService.info('📱 Pantalla seleccionada: $index');
    notifyListeners();
    
    print('🔍 [DEBUG] DashboardStateService.selectScreen: Estado actualizado a $_selectedIndex');
  }
  
  /// Forzar selección de pantalla (sin verificar si es diferente)
  void forceSelectScreen(int index) {
    print('🔍 [DEBUG] DashboardStateService.forceSelectScreen: Forzando selección a $index');
    _selectedIndex = index;
    LoggingService.info('📱 Pantalla forzada: $index');
    notifyListeners();
  }

  /// Activar búsqueda
  void activateSearch() {
    if (!_isSearchActive) {
      _isSearchActive = true;
      LoggingService.info('🔍 Búsqueda activada');
      notifyListeners();
    }
  }

  /// Desactivar búsqueda
  void deactivateSearch() {
    if (_isSearchActive) {
      _isSearchActive = false;
      _currentSearchQuery = '';
      _searchController.clear();
      LoggingService.info('🔍 Búsqueda desactivada');
      notifyListeners();
    }
  }

  /// Actualizar query de búsqueda
  void updateSearchQuery(String query) {
    if (_currentSearchQuery != query) {
      _currentSearchQuery = query;
      LoggingService.info('🔍 Query de búsqueda actualizada: $query');
      notifyListeners();
    }
  }

  /// Limpiar búsqueda
  void clearSearch() {
    _currentSearchQuery = '';
    _searchController.clear();
    _isSearchActive = false;
    LoggingService.info('🧹 Búsqueda limpiada');
    notifyListeners();
  }

  /// Volver al dashboard
  void goToDashboard() {
    selectScreen(0);
    clearSearch();
  }

  /// Verificar si estamos en el dashboard
  bool get isDashboardSelected => _selectedIndex == 0;

  /// Verificar si hay búsqueda activa
  bool get hasActiveSearch => _isSearchActive && _currentSearchQuery.isNotEmpty;

  @override
  void dispose() {
    LoggingService.info('🧹 Limpiando DashboardStateService...');
    _searchController.dispose();
    super.dispose();
  }
}
