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

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  @override
  Widget build(BuildContext context) {
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
          width: 80,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
        children: [
          // Logo section
          Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white70],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'S',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = widget.selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => widget.onItemSelected(index),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            // Línea indicadora de selección
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: isSelected ? 3 : 0,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? item['color'] : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(2),
                                  bottomRight: Radius.circular(2),
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: item['color'].withOpacity(0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                    offset: const Offset(2, 0),
                                  ),
                                ] : null,
                              ),
                            ),
                            // Contenido principal
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Icon(
                                      item['icon'],
                                      color: AppTheme.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['label'],
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom section - Icono de actualizaciones
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isCheckingUpdates ? null : _checkForUpdates,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getUpdateIconColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _isCheckingUpdates
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(_getUpdateIconTextColor()),
                            ),
                          )
                        : Icon(
                            _getUpdateIcon(),
                            color: _getUpdateIconTextColor(),
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getUpdateText(),
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    
    // Widget de notificación de actualización
    if (_pendingUpdate != null)
      UpdateNotificationWidget(
        updateInfo: _pendingUpdate!,
        isMandatory: _pendingUpdate!.isMandatory,
        onDismiss: () {
          setState(() {
            _pendingUpdate = null;
          });
        },
      ),
  ],
);
  }

  // ==================== MÉTODOS DE ACTUALIZACIONES ====================

  /// Verifica si hay actualizaciones disponibles
  Future<void> _checkForUpdates() async {
    if (_isCheckingUpdates) return;
    
    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      final updateInfo = await _updateService.checkForUpdates();
      
      if (updateInfo != null) {
        setState(() {
          _pendingUpdate = updateInfo;
        });
      }
    } catch (e) {
      // Error silencioso para no interrumpir la UI
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
      return _pendingUpdate!.isMandatory ? Colors.red.shade100 : Colors.blue.shade100;
    }
    return AppTheme.primaryColor.withOpacity(0.1);
  }

  /// Obtiene el color del texto del icono
  Color _getUpdateIconTextColor() {
    if (_pendingUpdate != null) {
      return _pendingUpdate!.isMandatory ? Colors.red.shade600 : Colors.blue.shade600;
    }
    return AppTheme.primaryColor;
  }

  /// Obtiene el texto según el estado
  String _getUpdateText() {
    if (_pendingUpdate != null) {
      return _pendingUpdate!.isMandatory ? 'Actualizar' : 'Actualizar';
    }
    return 'Actualizar';
  }
}

