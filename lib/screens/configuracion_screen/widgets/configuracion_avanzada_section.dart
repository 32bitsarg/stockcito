import 'package:flutter/material.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';

class ConfiguracionAvanzadaSection extends StatelessWidget {
  final bool exportarAutomatico;
  final bool respaldoAutomatico;
  final Function(bool) onExportarAutomaticoChanged;
  final Function(bool) onRespaldoAutomaticoChanged;

  const ConfiguracionAvanzadaSection({
    super.key,
    required this.exportarAutomatico,
    required this.respaldoAutomatico,
    required this.onExportarAutomaticoChanged,
    required this.onRespaldoAutomaticoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConfiguracionCard(
      title: 'Configuración Avanzada',
      icon: Icons.tune,
      children: [
        ConfiguracionControls.buildSwitchConfig(
          context,
          'Exportación Automática',
          exportarAutomatico,
          onExportarAutomaticoChanged,
          'Exporta reportes automáticamente cada semana',
        ),
        const SizedBox(height: 16),
        ConfiguracionControls.buildSwitchConfig(
          context,
          'Respaldo Automático',
          respaldoAutomatico,
          onRespaldoAutomaticoChanged,
          'Crea respaldos automáticos de la base de datos',
        ),
      ],
    );
  }
}
