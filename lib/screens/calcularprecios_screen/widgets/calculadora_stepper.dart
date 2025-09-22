import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../services/calculadora_service.dart';
import '../models/calculadora_state.dart';

/// Stepper vertical para la calculadora
class CalculadoraStepper extends StatelessWidget {
  final CalculadoraService calculadoraService;
  final Function(int) onStepChanged;

  const CalculadoraStepper({
    super.key,
    required this.calculadoraService,
    required this.onStepChanged,
  });

  @override
  Widget build(BuildContext context) {
    final state = calculadoraService.currentState;
    if (state == null) return const SizedBox();

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título del stepper
          Text(
            'Pasos del Cálculo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Progreso general
          _buildProgressBar(state),
          const SizedBox(height: 16),
          
          // Lista de pasos
          Expanded(
            child: Column(
              children: _buildSteps(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(CalculadoraState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${(state.progreso * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: state.progreso,
          backgroundColor: AppTheme.borderColor,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          minHeight: 4,
        ),
      ],
    );
  }

  List<Widget> _buildSteps(CalculadoraState state) {
    final steps = _getSteps(state.config.modoAvanzado);
    
    return steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      final isActive = index == state.pasoActual;
      final isCompleted = index < state.pasoActual;
      final isEnabled = index <= state.pasoActual || isCompleted;

      return _buildStepItem(
        step: step,
        index: index,
        isActive: isActive,
        isCompleted: isCompleted,
        isEnabled: isEnabled,
        onTap: isEnabled ? () => onStepChanged(index) : null,
      );
    }).toList();
  }

  Widget _buildStepItem({
    required Map<String, dynamic> step,
    required int index,
    required bool isActive,
    required bool isCompleted,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStepColor(isActive, isCompleted, isEnabled),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _getBorderColor(isActive, isCompleted, isEnabled),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icono del paso
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _getIconColor(isActive, isCompleted, isEnabled),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getStepIcon(isActive, isCompleted, isEnabled),
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                
                // Contenido del paso
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _getTextColor(isActive, isCompleted, isEnabled),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        step['description'],
                        style: TextStyle(
                          fontSize: 11,
                          color: _getSubtextColor(isActive, isCompleted, isEnabled),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getSteps(bool modoAvanzado) {
    if (modoAvanzado) {
      return [
        {
          'title': 'Configuración',
          'description': 'Modo y tipo de negocio',
          'icon': FontAwesomeIcons.gear,
        },
        {
          'title': 'Información del Producto',
          'description': 'Datos básicos del producto',
          'icon': FontAwesomeIcons.boxesStacked,
        },
        {
          'title': 'Costos Directos',
          'description': 'Materiales y mano de obra',
          'icon': FontAwesomeIcons.hammer,
        },
        {
          'title': 'Costos Indirectos',
          'description': 'Gastos fijos del negocio',
          'icon': FontAwesomeIcons.house,
        },
        {
          'title': 'Resultado Final',
          'description': 'Precio y análisis',
          'icon': FontAwesomeIcons.chartLine,
        },
      ];
    } else {
      return [
        {
          'title': 'Configuración',
          'description': 'Modo y tipo de negocio',
          'icon': FontAwesomeIcons.gear,
        },
        {
          'title': 'Producto y Precio',
          'description': 'Información y precio de venta',
          'icon': FontAwesomeIcons.boxesStacked,
        },
        {
          'title': 'Resultado Final',
          'description': 'Revisar y guardar',
          'icon': FontAwesomeIcons.chartLine,
        },
      ];
    }
  }

  Color _getStepColor(bool isActive, bool isCompleted, bool isEnabled) {
    if (isActive) {
      return AppTheme.primaryColor.withOpacity(0.1);
    } else if (isCompleted) {
      return AppTheme.successColor.withOpacity(0.1);
    } else if (isEnabled) {
      return Colors.white;
    } else {
      return AppTheme.backgroundColor;
    }
  }

  Color _getBorderColor(bool isActive, bool isCompleted, bool isEnabled) {
    if (isActive) {
      return AppTheme.primaryColor;
    } else if (isCompleted) {
      return AppTheme.successColor;
    } else if (isEnabled) {
      return AppTheme.borderColor;
    } else {
      return AppTheme.borderColor.withOpacity(0.5);
    }
  }

  Color _getIconColor(bool isActive, bool isCompleted, bool isEnabled) {
    if (isActive) {
      return AppTheme.primaryColor;
    } else if (isCompleted) {
      return AppTheme.successColor;
    } else if (isEnabled) {
      return AppTheme.textSecondary;
    } else {
      return AppTheme.textSecondary.withOpacity(0.5);
    }
  }

  IconData _getStepIcon(bool isActive, bool isCompleted, bool isEnabled) {
    if (isCompleted) {
      return FontAwesomeIcons.check;
    } else if (isActive) {
      return FontAwesomeIcons.play;
    } else {
      return FontAwesomeIcons.circle;
    }
  }

  Color _getTextColor(bool isActive, bool isCompleted, bool isEnabled) {
    if (isActive) {
      return AppTheme.primaryColor;
    } else if (isCompleted) {
      return AppTheme.successColor;
    } else if (isEnabled) {
      return AppTheme.textPrimary;
    } else {
      return AppTheme.textSecondary.withOpacity(0.5);
    }
  }

  Color _getSubtextColor(bool isActive, bool isCompleted, bool isEnabled) {
    if (isActive) {
      return AppTheme.primaryColor.withOpacity(0.8);
    } else if (isCompleted) {
      return AppTheme.successColor.withOpacity(0.8);
    } else if (isEnabled) {
      return AppTheme.textSecondary;
    } else {
      return AppTheme.textSecondary.withOpacity(0.5);
    }
  }
}
