import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/ui/sidebar/sidebar_state_service.dart';
import 'sidebar_logo_section.dart';
import 'sidebar_menu_section.dart';
import 'sidebar_download_section.dart';
import 'migrate_section_widget.dart';

/// Widget principal del sidebar moderno y modular
class ModernSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ModernSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> {
  final SidebarStateService _stateService = SidebarStateService();
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _stateService.dispose();
    super.dispose();
  }

  /// Inicializa los servicios del sidebar
  Future<void> _initializeServices() async {
    try {
      await _stateService.initialize();
      
      // Escuchar cambios de estado
      _stateService.updateStream.listen((updateInfo) {
        if (mounted && updateInfo != null) {
          _stateService.showUpdateNotification(context);
        }
      });
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF10002B), // Color sólido sin transparencia
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          // Sombra principal (más intensa)
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: 2,
          ),
          // Sombra secundaria (más suave)
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 50,
            offset: const Offset(0, 25),
            spreadRadius: 5,
          ),
          // Sombra de elevación (muy suave)
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 80,
            offset: const Offset(0, 40),
            spreadRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          children: [
            // Sección del logo
            SidebarLogoSection(
              isExpanded: true,
              onTap: _onLogoTap,
            ),
            
            // Sección del menú
            SidebarMenuSection(
              selectedIndex: widget.selectedIndex,
              onItemSelected: widget.onItemSelected,
              isExpanded: true,
            ),
            
            // Sección de migración (solo para usuarios anónimos)
            const MigrateSectionWidget(),
            
            // Sección de actualizaciones
            SidebarUpdateSection(
              isExpanded: true,
              onUpdateTap: _onUpdateTap,
            ),
          ],
        ),
      ),
    );
  }


  /// Maneja el tap en el logo
  void _onLogoTap() {
    // Navegar al dashboard
    widget.onItemSelected(0);
  }

  /// Maneja el tap en el botón de actualización
  void _onUpdateTap() {
    final hasUpdate = _stateService.pendingUpdate != null;
    
    if (hasUpdate) {
      // Mostrar notificación de actualización
      _stateService.showUpdateNotification(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Actualización ${_stateService.pendingUpdate?.version} disponible'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ver detalles',
            onPressed: () {
              _stateService.showUpdateNotification(context);
            },
          ),
        ),
      );
    } else {
      // Forzar verificación de actualizaciones
      _stateService.forceUpdateCheck();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verificando actualizaciones...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

}
