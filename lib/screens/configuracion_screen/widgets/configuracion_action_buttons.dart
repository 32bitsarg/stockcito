import 'package:flutter/material.dart';
import '../../../widgets/ui/utility/windows_button.dart';

class ConfiguracionActionButtons extends StatelessWidget {
  final VoidCallback onRestaurar;
  final VoidCallback onExportar;
  final VoidCallback onImportar;

  const ConfiguracionActionButtons({
    super.key,
    required this.onRestaurar,
    required this.onExportar,
    required this.onImportar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: WindowsButton(
            text: 'Restaurar Valores',
            type: ButtonType.secondary,
            onPressed: onRestaurar,
            icon: Icons.restore,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: WindowsButton(
            text: 'Exportar Configuración',
            type: ButtonType.secondary,
            onPressed: onExportar,
            icon: Icons.download,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: WindowsButton(
            text: 'Importar Configuración',
            type: ButtonType.secondary,
            onPressed: onImportar,
            icon: Icons.upload,
          ),
        ),
      ],
    );
  }
}
