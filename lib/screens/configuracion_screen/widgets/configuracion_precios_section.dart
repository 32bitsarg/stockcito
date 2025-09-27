import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';

class ConfiguracionPreciosSection extends StatelessWidget {
  final double margenDefecto;
  final double iva;
  final Function(double) onMargenChanged;
  final Function(double) onIvaChanged;

  const ConfiguracionPreciosSection({
    super.key,
    required this.margenDefecto,
    required this.iva,
    required this.onMargenChanged,
    required this.onIvaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ConfiguracionCard(
      title: 'Configuración de Precios',
      icon: Icons.attach_money,
      children: [
        ConfiguracionControls.buildSliderConfig(
          context,
          'Margen de Ganancia por Defecto',
          margenDefecto,
          0.0,
          200.0,
          '%',
          onMargenChanged,
        ),
        const SizedBox(height: 20),
        ConfiguracionControls.buildSliderConfig(
          context,
          'IVA',
          iva,
          0.0,
          50.0,
          '%',
          onIvaChanged,
        ),
        const SizedBox(height: 20),
        // Información de moneda fija
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.infoColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Moneda: Peso Argentino (ARS)',
                  style: TextStyle(
                    color: AppTheme.infoColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
