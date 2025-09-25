import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/ui/utility/animated_widgets.dart';
import '../services/calculadora_service.dart';
import '../models/calculadora_state.dart';

/// Widget para mostrar el resultado final
class CalculadoraResultadoWidget extends StatelessWidget {
  final CalculadoraService calculadoraService;
  final VoidCallback onGuardar;
  final VoidCallback onNuevo;

  const CalculadoraResultadoWidget({
    super.key,
    required this.calculadoraService,
    required this.onGuardar,
    required this.onNuevo,
  });

  @override
  Widget build(BuildContext context) {
    final state = calculadoraService.currentState;
    if (state == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del paso
          _buildStepHeader(),
          const SizedBox(height: 24),
          
          // Contenido del resultado
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Resumen del producto
                  _buildProductSummary(state),
                  const SizedBox(height: 24),
                  
                  // Análisis de costos (solo modo avanzado)
                  if (state.config.modoAvanzado) ...[
                    _buildCostAnalysis(state),
                    const SizedBox(height: 24),
                  ],
                  
                  // Precio final
                  _buildFinalPrice(state),
                  const SizedBox(height: 24),
                  
                  // Análisis de rentabilidad (solo modo avanzado)
                  if (state.config.modoAvanzado) ...[
                    _buildProfitabilityAnalysis(state),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recomendaciones
                  _buildRecommendations(state),
                ],
              ),
            ),
          ),
          
          // Botones de acción
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chartLine,
                color: AppTheme.successColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Resultado Final',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Revisa el análisis completo y guarda tu producto',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductSummary(CalculadoraState state) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del Producto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nombre', state.producto.nombre),
          _buildInfoRow('Categoría', state.producto.categoria),
          _buildInfoRow('Talla', state.producto.talla),
          _buildInfoRow('Stock', state.producto.stock.toString()),
          if (state.producto.descripcion.isNotEmpty)
            _buildInfoRow('Descripción', state.producto.descripcion),
        ],
      ),
    );
  }

  Widget _buildCostAnalysis(CalculadoraState state) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis de Costos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Costos directos
          if (state.costosDirectos.isNotEmpty) ...[
            _buildCostSection(
              title: 'Costos Directos',
              costos: state.costosDirectos,
              total: state.totalCostosDirectos,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
          ],
          
          // Costos indirectos
          if (state.costosIndirectos.isNotEmpty) ...[
            _buildCostSection(
              title: 'Costos Indirectos',
              costos: state.costosIndirectos,
              total: state.totalCostosIndirectos,
              color: AppTheme.secondaryColor,
            ),
            const SizedBox(height: 16),
          ],
          
          // Total de costos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total de Costos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${state.costoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene el costo total según el tipo de costo
  double _getCostoTotal(dynamic costo) {
    if (costo.toString().contains('CostoDirecto')) {
      return costo.costoTotal;
    } else if (costo.toString().contains('CostoIndirecto')) {
      return costo.costoPorProducto;
    }
    return 0.0;
  }

  Widget _buildCostSection({
    required String title,
    required List<dynamic> costos,
    required double total,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        ...costos.map((costo) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                costo.nombre,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${_getCostoTotal(costo).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        )).toList(),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal $title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalPrice(CalculadoraState state) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.dollarSign,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Precio Final Recomendado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '\$${state.precioFinal.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            if (state.config.modoAvanzado) ...[
              const SizedBox(height: 8),
              Text(
                'Incluye ${state.config.margenGananciaDefault.toStringAsFixed(0)}% margen + ${state.config.ivaDefault.toStringAsFixed(0)}% IVA',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfitabilityAnalysis(CalculadoraState state) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis de Rentabilidad',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProfitabilityCard(
                  title: 'Ganancia',
                  value: '\$${state.ganancia.toStringAsFixed(2)}',
                  color: state.ganancia > 0 ? AppTheme.successColor : AppTheme.errorColor,
                  icon: FontAwesomeIcons.arrowUp,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProfitabilityCard(
                  title: 'Margen %',
                  value: '${state.porcentajeGanancia.toStringAsFixed(1)}%',
                  color: state.porcentajeGanancia > 20 ? AppTheme.successColor : AppTheme.warningColor,
                  icon: FontAwesomeIcons.percent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfitabilityCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(CalculadoraState state) {
    final recomendaciones = _getRecommendations(state);
    
    if (recomendaciones.isEmpty) return const SizedBox();
    
    return AnimatedCard(
      delay: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recomendaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...recomendaciones.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FaIcon(
                  rec['icon'],
                  color: rec['color'],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec['text'],
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getRecommendations(CalculadoraState state) {
    final recomendaciones = <Map<String, dynamic>>[];
    
    if (state.config.modoAvanzado) {
      if (state.porcentajeGanancia < 20) {
        recomendaciones.add({
          'icon': FontAwesomeIcons.exclamationTriangle,
          'color': AppTheme.warningColor,
          'text': 'El margen de ganancia es bajo. Considera aumentar el precio o reducir costos.',
        });
      }
      
      if (state.costosDirectos.isEmpty) {
        recomendaciones.add({
          'icon': FontAwesomeIcons.infoCircle,
          'color': AppTheme.infoColor,
          'text': 'No se han agregado costos directos. Esto puede afectar la precisión del cálculo.',
        });
      }
      
      if (state.costosIndirectos.isEmpty) {
        recomendaciones.add({
          'icon': FontAwesomeIcons.infoCircle,
          'color': AppTheme.infoColor,
          'text': 'No se han agregado costos indirectos. Considera incluir gastos fijos del negocio.',
        });
      }
    }
    
    if (state.producto.stock < 5) {
      recomendaciones.add({
        'icon': FontAwesomeIcons.boxesStacked,
        'color': AppTheme.infoColor,
        'text': 'El stock es bajo. Considera aumentar la cantidad para aprovechar descuentos por volumen.',
      });
    }
    
    return recomendaciones;
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedButton(
          text: 'Nuevo Cálculo',
          type: ButtonType.secondary,
          onPressed: onNuevo,
          icon: FontAwesomeIcons.plus,
          delay: const Duration(milliseconds: 200),
        ),
        AnimatedButton(
          text: 'Guardar Producto',
          type: ButtonType.primary,
          onPressed: onGuardar,
          icon: FontAwesomeIcons.floppyDisk,
          delay: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
