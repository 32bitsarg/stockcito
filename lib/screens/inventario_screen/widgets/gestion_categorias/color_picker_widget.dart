import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../functions/categoria_functions.dart';

class ColorPickerWidget extends StatefulWidget {
  final String colorSeleccionado;
  final Function(String) onColorChanged;

  const ColorPickerWidget({
    super.key,
    required this.colorSeleccionado,
    required this.onColorChanged,
  });

  @override
  State<ColorPickerWidget> createState() => _ColorPickerWidgetState();
}

class _ColorPickerWidgetState extends State<ColorPickerWidget> {
  late String _colorSeleccionado;

  @override
  void initState() {
    super.initState();
    _colorSeleccionado = widget.colorSeleccionado;
  }

  @override
  Widget build(BuildContext context) {
    final coloresPredefinidos = CategoriaFunctions.getColoresPredefinidos();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color actual seleccionado
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CategoriaFunctions.hexToColor(_colorSeleccionado),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderColor,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                CategoriaFunctions.colorToHex(CategoriaFunctions.hexToColor(_colorSeleccionado)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Paleta de colores
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: coloresPredefinidos.length,
            itemBuilder: (context, index) {
              final color = coloresPredefinidos[index];
              final hexColor = CategoriaFunctions.colorToHex(color);
              final isSelected = _colorSeleccionado == hexColor;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _colorSeleccionado = hexColor;
                  });
                  widget.onColorChanged(hexColor);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Campo de color personalizado
          Text(
            'Color personalizado',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _colorSeleccionado,
            decoration: InputDecoration(
              hintText: '#FF5722',
              prefixText: '#',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (value) {
              final hexColor = value.startsWith('#') ? value : '#$value';
              if (_isValidHexColor(hexColor)) {
                setState(() {
                  _colorSeleccionado = hexColor;
                });
                widget.onColorChanged(hexColor);
              }
            },
          ),
        ],
      ),
    );
  }

  bool _isValidHexColor(String color) {
    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(color);
  }
}

