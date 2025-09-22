import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/animated_widgets.dart';
import '../services/calculadora_service.dart';
import '../models/calculadora_state.dart';
import '../models/costo_directo.dart';
import 'calculadora_costo_directo_dialog.dart';

/// Widget para gestionar costos directos
class CalculadoraCostosDirectosWidget extends StatefulWidget {
  final CalculadoraService calculadoraService;
  final VoidCallback onCostosChanged;

  const CalculadoraCostosDirectosWidget({
    super.key,
    required this.calculadoraService,
    required this.onCostosChanged,
  });

  @override
  State<CalculadoraCostosDirectosWidget> createState() => _CalculadoraCostosDirectosWidgetState();
}

class _CalculadoraCostosDirectosWidgetState extends State<CalculadoraCostosDirectosWidget> {

  @override
  Widget build(BuildContext context) {
    final state = widget.calculadoraService.currentState;
    if (state == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del paso
          _buildStepHeader(),
          const SizedBox(height: 24),
          
          // Lista de costos directos
          Expanded(
            child: _buildCostosList(state),
          ),
          
          // Botones de navegación
          _buildNavigationButtons(),
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
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.hammer,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Costos Directos',
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
          'Agrega los costos directos como materiales, mano de obra y equipos',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCostosList(CalculadoraState state) {
    if (state.costosDirectos.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Resumen de costos
        _buildCostSummary(state),
        const SizedBox(height: 16),
        
        // Lista de costos
        Flexible(
          child: ListView.builder(
            itemCount: state.costosDirectos.length,
            itemBuilder: (context, index) {
              final costo = state.costosDirectos[index];
              return _buildCostoItem(costo, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const FaIcon(
              FontAwesomeIcons.hammer,
              color: AppTheme.textSecondary,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay costos directos agregados',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega materiales, mano de obra y otros costos directos',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary(CalculadoraState state) {
    return AnimatedCard(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Costos Directos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${state.costosDirectos.length} ${state.costosDirectos.length == 1 ? 'costo' : 'costos'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            Text(
              '\$${state.totalCostosDirectos.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostoItem(CostoDirecto costo, int index) {
    return AnimatedCard(
      delay: Duration(milliseconds: 100 + (index * 50)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            // Icono del tipo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTipoColor(costo.tipo).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: FaIcon(
                _getTipoIcon(costo.tipo),
                color: _getTipoColor(costo.tipo),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            
            // Información del costo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    costo.nombre,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${costo.cantidad} ${costo.unidad} × \$${costo.precioUnitario.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (costo.desperdicio > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Desperdicio: ${costo.desperdicio.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Precio total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${costo.costoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${costo.costoPorUnidad.toStringAsFixed(2)}/unidad',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // Botones de acción
            PopupMenuButton<String>(
              onSelected: (value) => _handleCostoAction(value, costo),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.pen, size: 14),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      FaIcon(FontAwesomeIcons.trash, size: 14, color: AppTheme.errorColor),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                    ],
                  ),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.ellipsisVertical,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedButton(
          text: 'Anterior',
          type: ButtonType.secondary,
          onPressed: _canGoBack() ? _goBack : null,
          icon: FontAwesomeIcons.arrowLeft,
          delay: const Duration(milliseconds: 200),
        ),
        Row(
          children: [
            AnimatedButton(
              text: 'Agregar Costo',
              type: ButtonType.outline,
              onPressed: _addCosto,
              icon: FontAwesomeIcons.plus,
              delay: const Duration(milliseconds: 200),
            ),
            const SizedBox(width: 12),
            AnimatedButton(
              text: 'Continuar',
              type: ButtonType.primary,
              onPressed: _canContinue() ? _continue : null,
              icon: FontAwesomeIcons.arrowRight,
              delay: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ],
    );
  }

  bool _canGoBack() {
    return widget.calculadoraService.currentState?.canGoToPreviousStep() ?? false;
  }

  bool _canContinue() {
    final state = widget.calculadoraService.currentState;
    return state?.costosDirectos.isNotEmpty ?? false;
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'material':
        return AppTheme.primaryColor;
      case 'mano_obra':
        return AppTheme.secondaryColor;
      case 'equipo':
        return AppTheme.warningColor;
      case 'embalaje':
        return AppTheme.infoColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getTipoIcon(String tipo) {
    switch (tipo) {
      case 'material':
        return FontAwesomeIcons.hammer;
      case 'mano_obra':
        return FontAwesomeIcons.person;
      case 'equipo':
        return FontAwesomeIcons.gear;
      case 'embalaje':
        return FontAwesomeIcons.box;
      default:
        return FontAwesomeIcons.dollarSign;
    }
  }

  Future<void> _addCosto() async {
    final result = await showDialog<CostoDirecto>(
      context: context,
      builder: (context) => CalculadoraCostoDirectoDialog(),
    );

    if (result != null) {
      await widget.calculadoraService.addCostoDirecto(result);
      widget.onCostosChanged();
    }
  }

  Future<void> _handleCostoAction(String action, CostoDirecto costo) async {
    switch (action) {
      case 'edit':
        final result = await showDialog<CostoDirecto>(
          context: context,
          builder: (context) => CalculadoraCostoDirectoDialog(costo: costo),
        );
        if (result != null) {
          await widget.calculadoraService.updateCostoDirecto(costo.id, result);
          widget.onCostosChanged();
        }
        break;
      case 'delete':
        await _confirmDelete(costo);
        break;
    }
  }

  Future<void> _confirmDelete(CostoDirecto costo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Costo'),
        content: Text('¿Estás seguro de que quieres eliminar "${costo.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.calculadoraService.removeCostoDirecto(costo.id);
      widget.onCostosChanged();
    }
  }

  Future<void> _goBack() async {
    await widget.calculadoraService.previousStep();
    widget.onCostosChanged();
  }

  Future<void> _continue() async {
    if (_canContinue()) {
      await widget.calculadoraService.nextStep();
      widget.onCostosChanged();
    }
  }
}
