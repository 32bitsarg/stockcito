import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/theme_manager_service.dart';
import '../config/app_theme.dart';

class ThemeSelectorWidget extends StatefulWidget {
  const ThemeSelectorWidget({super.key});

  @override
  State<ThemeSelectorWidget> createState() => _ThemeSelectorWidgetState();
}

class _ThemeSelectorWidgetState extends State<ThemeSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManagerService>(
      builder: (context, themeManager, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeManager.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.palette,
                      color: themeManager.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalización',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Personaliza la apariencia de tu aplicación',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Modo Oscuro
              _buildSection(
                'Modo Oscuro',
                FontAwesomeIcons.moon,
                Switch(
                  value: themeManager.isDarkMode,
                  onChanged: (value) => themeManager.toggleDarkMode(),
                  activeColor: themeManager.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Selección de Tema
              _buildSection(
                'Tema de Colores',
                FontAwesomeIcons.paintbrush,
                _buildThemeSelector(themeManager),
              ),
              const SizedBox(height: 24),

              // Selección de Fuente
              _buildSection(
                'Fuente',
                FontAwesomeIcons.font,
                _buildFontSelector(themeManager),
              ),
              const SizedBox(height: 24),

              // Tamaño de Fuente
              _buildSection(
                'Tamaño de Fuente',
                FontAwesomeIcons.textHeight,
                _buildFontSizeSelector(themeManager),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              icon,
              size: 18,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildThemeSelector(ThemeManagerService themeManager) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ThemeManagerService.availableThemes.map((theme) {
        final isSelected = theme['id'] == themeManager.currentTheme;
        return GestureDetector(
          onTap: () => themeManager.setTheme(theme['id']),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme['primary'] as Color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme['primary'] as Color,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  theme['name'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (isSelected)
                  const FaIcon(
                    FontAwesomeIcons.check,
                    color: Colors.white,
                    size: 16,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontSelector(ThemeManagerService themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: themeManager.currentFontFamily,
          isExpanded: true,
          items: ThemeManagerService.availableFonts.map((font) {
            return DropdownMenuItem<String>(
              value: font['family'],
              child: Text(
                font['name'],
                style: TextStyle(
                  fontFamily: font['family'],
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              themeManager.setFontFamily(value);
            }
          },
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector(ThemeManagerService themeManager) {
    return Row(
      children: ThemeManagerService.availableFontSizes.map((size) {
        final isSelected = size['size'] == themeManager.currentFontSize;
        return Expanded(
          child: GestureDetector(
            onTap: () => themeManager.setFontSize(size['size'] as double),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? themeManager.primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected 
                      ? themeManager.primaryColor 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'A',
                    style: TextStyle(
                      fontSize: size['size'] as double,
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? themeManager.primaryColor 
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    size['name'] as String,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected 
                          ? themeManager.primaryColor 
                          : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
