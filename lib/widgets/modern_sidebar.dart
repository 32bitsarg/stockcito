import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';

class ModernSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const ModernSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

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

    return Container(
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
                final isSelected = selectedIndex == index;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onItemSelected(index),
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
          
          // Bottom section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    FontAwesomeIcons.circleQuestion,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ayuda',
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
    );
  }
}

