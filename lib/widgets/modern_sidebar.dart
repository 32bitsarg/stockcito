import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/system/update_service.dart';
import '../widgets/update_notification_widget.dart';

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
  final UpdateService _updateService = UpdateService();
  UpdateInfo? _pendingUpdate;
  bool _isCheckingUpdates = false;
  OverlayEntry? _currentOverlayEntry;

  @override
  void initState() {
    super.initState();
    print('🚀 [MODERN SIDEBAR] initState() llamado');
    try {
      _checkForUpdates();
      print('✅ [MODERN SIDEBAR] _checkForUpdates() ejecutado');
    } catch (e) {
      print('❌ [MODERN SIDEBAR] Error en initState: $e');
    }
  }

  @override
  void dispose() {
    print('🛑 [MODERN SIDEBAR] dispose() llamado');
    try {
      _dismissCurrentNotification();
      print('✅ [MODERN SIDEBAR] _dismissCurrentNotification() ejecutado');
    } catch (e) {
      print('❌ [MODERN SIDEBAR] Error en dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [MODERN SIDEBAR] build() llamado - _pendingUpdate: ${_pendingUpdate?.version}');
    print('🔍 [MODERN SIDEBAR] selectedIndex: ${widget.selectedIndex}');
    
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': FontAwesomeIcons.house,
        'label': 'Dashboard',
        'color': AppTheme.primaryColor,
      },
      {
        'icon': FontAwesomeIcons.boxesStacked,
        'label': 'Inventario',
        'color': AppTheme.successColor,
      },
      {
        'icon': FontAwesomeIcons.chartLine,
        'label': 'Ventas',
        'color': AppTheme.warningColor,
      },
      {
        'icon': FontAwesomeIcons.users,
        'label': 'Clientes',
        'color': AppTheme.accentColor,
      },
      {
        'icon': FontAwesomeIcons.chartBar,
        'label': 'Reportes',
        'color': AppTheme.primaryColor,
      },
      {
        'icon': FontAwesomeIcons.calculator,
        'label': 'Cálculo de Precios',
        'color': AppTheme.errorColor,
      },
      {
        'icon': FontAwesomeIcons.gear,
        'label': 'Configuración',
        'color': AppTheme.textSecondary,
      },
    ];

    return Stack(
      children: [
        Container(
          width: 70,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              right: BorderSide(
                color: AppTheme.borderColor.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
        children: [
          // Logo section - Minimalista
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Menu items - Minimalistas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = widget.selectedIndex == index;
                
                return GestureDetector(
                  onTap: () {
                    print('🎯 [MODERN SIDEBAR] Tap en item $index: ${item['label']}');
                    try {
                      widget.onItemSelected(index);
                      print('✅ [MODERN SIDEBAR] onItemSelected($index) ejecutado exitosamente');
                    } catch (e) {
                      print('❌ [MODERN SIDEBAR] Error al seleccionar item $index: $e');
                      print('❌ [MODERN SIDEBAR] Stack trace: ${StackTrace.current}');
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? item['color'].withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected ? Border.all(
                        color: item['color'].withOpacity(0.3),
                        width: 1,
                      ) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'],
                          color: isSelected ? item['color'] : AppTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'],
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? item['color'] : AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom section - Minimalista
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Indicadores de estado - Ultra minimalistas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Estado de conectividad
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.wifi,
                        color: Colors.green.shade700,
                        size: 10,
                      ),
                    ),
                    // Estado de sincronización
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.sync,
                        color: Colors.blue.shade700,
                        size: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Icono de actualizaciones - Minimalista
                GestureDetector(
                  onTap: _isCheckingUpdates ? null : () => _checkForUpdates(forceCheck: true),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getUpdateIconColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _isCheckingUpdates
                        ? SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor: AlwaysStoppedAnimation<Color>(_getUpdateIconTextColor()),
                            ),
                          )
                        : Icon(
                            _getUpdateIcon(),
                            color: _getUpdateIconTextColor(),
                            size: 12,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    
  ],
);
  }

  // ==================== MÉTODOS DE ACTUALIZACIONES ====================

  /// Muestra la notificación de actualización usando Overlay
  void _showUpdateNotification(UpdateInfo updateInfo) {
    // Eliminar tooltip anterior si existe
    _dismissCurrentNotification();
    
    final overlay = Overlay.of(context);
    
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => UpdateNotificationWidget(
        updateInfo: updateInfo,
        isMandatory: updateInfo.isMandatory,
        onDismiss: () {
          _dismissCurrentNotification();
        },
      ),
    );
    
    overlay.insert(_currentOverlayEntry!);
  }

  /// Elimina la notificación actual si existe
  void _dismissCurrentNotification() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry!.remove();
      _currentOverlayEntry = null;
    }
    setState(() {
      _pendingUpdate = null;
    });
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> _checkForUpdates({bool forceCheck = false}) async {
    print('🔄 [MODERN SIDEBAR] _checkForUpdates() llamado - forceCheck: $forceCheck');
    if (_isCheckingUpdates) {
      print('⏳ [MODERN SIDEBAR] Ya se está verificando actualizaciones, omitiendo...');
      return;
    }
    
    print('🔄 [MODERN SIDEBAR] Iniciando verificación de actualizaciones...');
    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      print('🔄 [MODERN SIDEBAR] Llamando a _updateService.checkForUpdates()...');
      final updateInfo = await _updateService.checkForUpdates(forceCheck: forceCheck);
      print('✅ [MODERN SIDEBAR] _updateService.checkForUpdates() completado - updateInfo: ${updateInfo?.version}');
      
      if (updateInfo != null) {
        print('🔄 [MODERN SIDEBAR] Actualización detectada, actualizando estado...');
        setState(() {
          _pendingUpdate = updateInfo;
        });
        print('✅ [MODERN SIDEBAR] Estado actualizado - _pendingUpdate: ${_pendingUpdate?.version}');
        print('🎯 [MODERN SIDEBAR] _pendingUpdate != null: ${_pendingUpdate != null}');
        
        // Mostrar el tooltip usando Overlay
        _showUpdateNotification(updateInfo);
      } else if (forceCheck) {
        // Si es una verificación forzada y no hay actualizaciones, mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Aplicación actualizada - No hay nuevas versiones disponibles'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (forceCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error verificando actualizaciones: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isCheckingUpdates = false;
      });
    }
  }

  /// Obtiene el icono según el estado de actualizaciones
  IconData _getUpdateIcon() {
    if (_pendingUpdate != null) {
      return _pendingUpdate!.isMandatory ? Icons.system_update : Icons.system_update_alt;
    }
    return Icons.system_update;
  }

  /// Obtiene el color del icono según el estado
  Color _getUpdateIconColor() {
    if (_pendingUpdate != null) {
      return _pendingUpdate!.isMandatory 
          ? Colors.red.shade50 
          : Colors.blue.shade50;
    }
    return AppTheme.surfaceColor;
  }

  /// Obtiene el color del texto del icono
  Color _getUpdateIconTextColor() {
    if (_pendingUpdate != null) {
      return _pendingUpdate!.isMandatory 
          ? Colors.red.shade500 
          : Colors.blue.shade500;
    }
    return AppTheme.textSecondary;
  }

}

