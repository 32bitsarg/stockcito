import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../functions/calculo_precio_functions.dart';
import 'calculo_precio_input_fields.dart';
import 'calculo_precio_navigation_buttons.dart';

class CalculoPrecioProduccionTab extends StatelessWidget {
  final TextEditingController tiempoConfeccionController;
  final TextEditingController tarifaHoraController;
  final TextEditingController costoEquiposController;
  final TabController tabController;

  const CalculoPrecioProduccionTab({
    super.key,
    required this.tiempoConfeccionController,
    required this.tarifaHoraController,
    required this.costoEquiposController,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: tiempoConfeccionController,
                  label: 'Tiempo de Confección (horas)',
                  hint: '2.5',
                  icon: FontAwesomeIcons.clock,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: tarifaHoraController,
                  label: 'Tarifa por Hora (\$)',
                  hint: '15.0',
                  icon: FontAwesomeIcons.dollarSign,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CalculoPrecioInputFields.buildInputField(
            controller: costoEquiposController,
            label: 'Costos de Equipos/Máquinas (\$)',
            hint: '0',
            icon: FontAwesomeIcons.hammer,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildResumenCostos(),
          const Spacer(),
          CalculoPrecioNavigationButtons(
            currentIndex: 2,
            tabController: tabController,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCostos() {
    final tiempoConfeccion = double.tryParse(tiempoConfeccionController.text) ?? 0;
    final tarifaHora = double.tryParse(tarifaHoraController.text) ?? 0;
    final costoEquipos = double.tryParse(costoEquiposController.text) ?? 0;
    final costoManoObra = tiempoConfeccion * tarifaHora;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Costos de Producción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mano de Obra:'),
                Text('\$${CalculoPrecioFunctions.formatearPrecio(costoManoObra)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Equipos/Máquinas:'),
                Text('\$${CalculoPrecioFunctions.formatearPrecio(costoEquipos)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Producción:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '\$${CalculoPrecioFunctions.formatearPrecio(costoManoObra + costoEquipos)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
