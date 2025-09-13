import 'package:flutter/material.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';
import 'configuracion_info_card.dart';

class ConfiguracionIASection extends StatelessWidget {
  final bool mlConsentimiento;
  final Function(bool) onMLConsentimientoChanged;

  const ConfiguracionIASection({
    super.key,
    required this.mlConsentimiento,
    required this.onMLConsentimientoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConfiguracionCard(
      title: 'IA y Privacidad',
      icon: Icons.psychology,
      children: [
        ConfiguracionControls.buildSwitchConfig(
          context,
          'Entrenamiento de IA con Datos',
          mlConsentimiento,
          onMLConsentimientoChanged,
          'Permite que la IA se entrene con tus datos para mejorar las recomendaciones. Los datos se envían de forma anónima y agregada.',
        ),
        const SizedBox(height: 16),
        ConfiguracionInfoCard(
          title: '¿Qué datos se comparten?',
          description: 'Solo se comparten datos agregados y anónimos para entrenar la IA: patrones de ventas, tendencias de productos y comportamiento de clientes. Nunca se comparten datos personales o identificables.',
        ),
        const SizedBox(height: 16),
        ConfiguracionInfoCard(
          title: 'Beneficios',
          description: 'Mejores recomendaciones de productos, predicciones de demanda más precisas y análisis de tendencias más inteligentes.',
        ),
      ],
    );
  }
}
