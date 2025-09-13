import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/theme_service.dart';
import '../functions/configuracion_functions.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';
import 'configuracion_tema_preview.dart';

class ConfiguracionTemaSection extends StatelessWidget {
  const ConfiguracionTemaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return ConfiguracionCard(
          title: 'Apariencia',
          icon: Icons.palette,
          children: [
            ConfiguracionControls.buildDropdownConfig(
              context,
              'Tema',
              themeService.themeName,
              ConfiguracionFunctions.getTemas(),
              (value) => themeService.setTheme(value!),
            ),
            const SizedBox(height: 20),
            ConfiguracionTemaPreview(temaActual: themeService.themeName),
          ],
        );
      },
    );
  }
}
