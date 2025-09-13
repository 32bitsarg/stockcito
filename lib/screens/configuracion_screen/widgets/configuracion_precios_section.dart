import 'package:flutter/material.dart';
import '../functions/configuracion_functions.dart';
import 'configuracion_card.dart';
import 'configuracion_controls.dart';

class ConfiguracionPreciosSection extends StatelessWidget {
  final double margenDefecto;
  final double iva;
  final String moneda;
  final Function(double) onMargenChanged;
  final Function(double) onIvaChanged;
  final Function(String) onMonedaChanged;

  const ConfiguracionPreciosSection({
    super.key,
    required this.margenDefecto,
    required this.iva,
    required this.moneda,
    required this.onMargenChanged,
    required this.onIvaChanged,
    required this.onMonedaChanged,
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
        ConfiguracionControls.buildDropdownConfig(
          context,
          'Moneda',
          moneda,
          ConfiguracionFunctions.getMonedas(),
          (value) => onMonedaChanged(value!),
        ),
      ],
    );
  }
}
