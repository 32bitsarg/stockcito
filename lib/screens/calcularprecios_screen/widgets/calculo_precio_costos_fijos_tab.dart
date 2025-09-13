import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import 'calculo_precio_input_fields.dart';
import 'calculo_precio_navigation_buttons.dart';

class CalculoPrecioCostosFijosTab extends StatelessWidget {
  final TextEditingController alquilerMensualController;
  final TextEditingController serviciosController;
  final TextEditingController gastosAdminController;
  final TextEditingController productosEstimadosController;
  final TabController tabController;

  const CalculoPrecioCostosFijosTab({
    super.key,
    required this.alquilerMensualController,
    required this.serviciosController,
    required this.gastosAdminController,
    required this.productosEstimadosController,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila de inputs
          Row(
            children: [
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: alquilerMensualController,
                  label: 'Alquiler Mensual (\$)',
                  hint: '500',
                  icon: FontAwesomeIcons.house,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: serviciosController,
                  label: 'Servicios (\$)',
                  hint: '150',
                  icon: FontAwesomeIcons.bolt,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segunda fila de inputs
          Row(
            children: [
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: gastosAdminController,
                  label: 'Gastos Admin (\$)',
                  hint: '100',
                  icon: FontAwesomeIcons.building,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CalculoPrecioInputFields.buildInputField(
                  controller: productosEstimadosController,
                  label: 'Productos/Mes',
                  hint: '50',
                  icon: FontAwesomeIcons.boxesStacked,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Resumen compacto
          _buildResumenCostosFijosCompacto(),
          const Spacer(),
          CalculoPrecioNavigationButtons(
            currentIndex: 3,
            tabController: tabController,
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCostosFijosCompacto() {
    final alquiler = double.tryParse(alquilerMensualController.text) ?? 0;
    final servicios = double.tryParse(serviciosController.text) ?? 0;
    final gastosAdmin = double.tryParse(gastosAdminController.text) ?? 0;
    final productosEstimados = double.tryParse(productosEstimadosController.text) ?? 1;
    final costoFijoPorProducto = (alquiler + servicios + gastosAdmin) / productosEstimados;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Costos Fijos:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '\$${(alquiler + servicios + gastosAdmin).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Por Producto:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${costoFijoPorProducto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
