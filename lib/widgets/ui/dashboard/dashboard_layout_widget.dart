import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/sidebar/modern_sidebar.dart';
import '../../modern_header.dart';
import '../utility/connectivity_status_widget.dart';
import 'dashboard_glassmorphism_widget.dart';
import 'dashboard_content_widget.dart';
import '../../../services/ui/dashboard/dashboard_state_service.dart';
import '../../../services/ui/dashboard/dashboard_navigation_service.dart';

/// Widget que maneja el layout principal del dashboard
class DashboardLayoutWidget extends StatelessWidget {
  final DashboardStateService stateService;
  final DashboardNavigationService navigationService;
  final VoidCallback? onSidebarItemSelected;
  final Function(String)? onSearch;
  final VoidCallback? onNavigateToInventario;
  final Function(Map<String, dynamic> actividad)? onActivityTap;

  const DashboardLayoutWidget({
    super.key,
    required this.stateService,
    required this.navigationService,
    this.onSidebarItemSelected,
    this.onSearch,
    this.onNavigateToInventario,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar izquierdo
          Consumer<DashboardStateService>(
            builder: (context, stateService, child) {
              return ModernSidebar(
                selectedIndex: stateService.selectedIndex,
                onItemSelected: (index) {
                  stateService.selectScreen(index);
                  onSidebarItemSelected?.call();
                },
              );
            },
          ),
          
          // Contenido principal con efecto glassmorphism
          Expanded(
            child: DashboardGlassmorphismWidget(
              child: Column(
                children: [
                  // Header principal para todas las pantallas
                  Consumer<DashboardStateService>(
                    builder: (context, stateService, child) {
                      print('🔍 [DEBUG] DashboardLayoutWidget Consumer rebuild: selectedIndex = ${stateService.selectedIndex}');
                      return _buildHeader(stateService);
                    },
                  ),
                  
                  // Contenido principal
                  Expanded(
                    child: Consumer<DashboardStateService>(
                      builder: (context, stateService, child) {
                        return DashboardContentWidget(
                          stateService: stateService,
                          navigationService: navigationService,
                          onNavigateToInventario: onNavigateToInventario,
                          onActivityTap: onActivityTap,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(DashboardStateService stateService) {
    final screenInfo = navigationService.getScreenInfo(stateService.selectedIndex);
    
    // 🔍 DEBUG: Log del estado del header
    print('🔍 [DEBUG] DashboardLayoutWidget._buildHeader:');
    print('   - selectedIndex: ${stateService.selectedIndex}');
    print('   - title: ${screenInfo['title']}');
    print('   - subtitle: ${screenInfo['subtitle']}');
    print('   - context: ${screenInfo['context']}');
    
    return ModernHeader(
      title: screenInfo['title']!,
      subtitle: screenInfo['subtitle']!,
      searchController: stateService.searchController,
      onSearch: (query) {
        stateService.updateSearchQuery(query);
        onSearch?.call(query);
      },
      showGreeting: stateService.isDashboardSelected,
      context: screenInfo['context']!,
      actions: [
        // Widget de estado de conectividad
        const ConnectivityStatusWidget(showDetails: false),
      ],
    );
  }
}
