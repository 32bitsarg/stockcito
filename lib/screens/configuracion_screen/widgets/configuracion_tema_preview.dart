import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../functions/configuracion_functions.dart';

class ConfiguracionTemaPreview extends StatelessWidget {
  final String temaActual;

  const ConfiguracionTemaPreview({
    super.key,
    required this.temaActual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa del Tema',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTemaOption(context, 'Claro', temaActual == 'Claro'),
              const SizedBox(width: 12),
              _buildTemaOption(context, 'Oscuro', temaActual == 'Oscuro'),
              const SizedBox(width: 12),
              _buildTemaOption(context, 'Automático', temaActual == 'Automático'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemaOption(BuildContext context, String nombre, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              ConfiguracionFunctions.getTemaIcon(nombre),
              color: ConfiguracionFunctions.getTemaColor(nombre, isSelected),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ConfiguracionFunctions.getTemaColor(nombre, isSelected),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
