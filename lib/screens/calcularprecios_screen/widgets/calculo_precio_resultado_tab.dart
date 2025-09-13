import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../functions/calculo_precio_functions.dart';

class CalculoPrecioResultadoTab extends StatelessWidget {
  final Map<String, double> costos;
  final double margenGanancia;
  final double iva;
  final Function() onGuardarProducto;
  final Function() onNuevoCalculo;
  final TabController tabController;

  const CalculoPrecioResultadoTab({
    super.key,
    required this.costos,
    required this.margenGanancia,
    required this.iva,
    required this.onGuardarProducto,
    required this.onNuevoCalculo,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final precios = CalculoPrecioFunctions.calcularPrecioFinal(
      costoTotal: costos['costoTotal'] ?? 0,
      margenGanancia: margenGanancia,
      iva: iva,
    );

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Layout horizontal para aprovechar mejor el espacio
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda - Desglose de costos
                Expanded(
                  flex: 3,
                  child: _buildDesgloseCostosCompacto(costos),
                ),
                const SizedBox(width: 12),
                // Columna derecha - Precio y análisis
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPrecioFinalCompacto(precios),
                      const SizedBox(height: 12),
                      _buildAnalisisRentabilidadCompacto(precios),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botones en la parte inferior
          _buildBotonesFinalesCompactos(),
        ],
      ),
    );
  }

  Widget _buildDesgloseCostosCompacto(Map<String, double> costos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.chartLine,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Desglose de Costos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid 2x2 más compacto
          Row(
            children: [
              Expanded(
                child: _buildCostoItemCompacto('Materiales', costos['materiales'] ?? 0, AppTheme.primaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostoItemCompacto('Mano Obra', costos['manoObra'] ?? 0, AppTheme.secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCostoItemCompacto('Equipos', costos['equipos'] ?? 0, AppTheme.accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostoItemCompacto('Fijos', costos['costosFijos'] ?? 0, AppTheme.warningColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total más compacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor.withOpacity(0.1),
                  AppTheme.successColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.successColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de Costos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${CalculoPrecioFunctions.formatearPrecio(costos['costoTotal'] ?? 0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoItemCompacto(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecioFinalCompacto(Map<String, double> precios) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.dollarSign,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Precio Sugerido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${CalculoPrecioFunctions.formatearPrecio(precios['precioConIva'] ?? 0)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'IVA ${iva}% incluido',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Margen',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${margenGanancia}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: AppTheme.borderColor,
                ),
                Column(
                  children: [
                    const Text(
                      'Ganancia',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${(precios['ganancia'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisRentabilidadCompacto(Map<String, double> precios) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.arrowTrendUp,
                  color: AppTheme.successColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rentabilidad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ganancia Neta',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '\$${(precios['ganancia'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Margen de Ganancia',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${(precios['porcentajeGanancia'] ?? 0).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesFinalesCompactos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextButton(
            onPressed: () => tabController.animateTo(tabController.index - 1),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: onGuardarProducto,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.floppyDisk, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: onNuevoCalculo,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16, color: AppTheme.successColor),
                    SizedBox(width: 6),
                    Text(
                      'Nuevo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
