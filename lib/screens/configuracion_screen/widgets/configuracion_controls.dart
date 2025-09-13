import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../functions/configuracion_functions.dart';

class ConfiguracionControls {
  /// Control deslizante para configuración
  static Widget buildSliderConfig(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    String suffix,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${ConfiguracionFunctions.formatNumber(value)}$suffix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Control dropdown para configuración
  static Widget buildDropdownConfig(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Control switch para configuración
  static Widget buildSwitchConfig(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    String subtitle,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  /// Control numérico para configuración
  static Widget buildNumberConfig(
    BuildContext context,
    String title,
    int value,
    ValueChanged<int> onChanged,
    String subtitle,
    int min,
    int max,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 80,
          child: Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(
                  Icons.remove,
                  color: value > min ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: value > min 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textSecondary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(
                  Icons.add,
                  color: value < max ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: value < max 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textSecondary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
