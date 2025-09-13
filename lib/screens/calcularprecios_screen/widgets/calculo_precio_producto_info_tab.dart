import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../functions/calculo_precio_functions.dart';
import 'calculo_precio_input_fields.dart';
import 'calculo_precio_navigation_buttons.dart';

class CalculoPrecioProductoInfoTab extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController descripcionController;
  final TextEditingController stockController;
  final String categoriaSeleccionada;
  final String tallaSeleccionada;
  final Function(String) onCategoriaChanged;
  final Function(String) onTallaChanged;
  final TabController tabController;

  const CalculoPrecioProductoInfoTab({
    super.key,
    required this.nombreController,
    required this.descripcionController,
    required this.stockController,
    required this.categoriaSeleccionada,
    required this.tallaSeleccionada,
    required this.onCategoriaChanged,
    required this.onTallaChanged,
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
                child: CalculoPrecioInputFields.buildInputFieldMinimalista(
                  controller: nombreController,
                  label: 'Nombre del Producto',
                  hint: 'Ej: Body de algodón',
                  icon: FontAwesomeIcons.boxesStacked,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CalculoPrecioInputFields.buildDropdownMinimalista(
                  value: categoriaSeleccionada,
                  items: CalculoPrecioFunctions.getCategorias(),
                  label: 'Categoría',
                  onChanged: (value) => onCategoriaChanged(value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CalculoPrecioInputFields.buildDropdownMinimalista(
                  value: tallaSeleccionada,
                  items: CalculoPrecioFunctions.getTallas(),
                  label: 'Talla',
                  onChanged: (value) => onTallaChanged(value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CalculoPrecioInputFields.buildInputFieldMinimalista(
                  controller: stockController,
                  label: 'Stock Inicial',
                  hint: '1',
                  icon: FontAwesomeIcons.tag,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CalculoPrecioInputFields.buildInputField(
            controller: descripcionController,
            label: 'Descripción',
            hint: 'Descripción detallada del producto...',
            icon: FontAwesomeIcons.fileText,
            maxLines: 3,
          ),
          const Spacer(),
          CalculoPrecioNavigationButtons(
            currentIndex: 0,
            tabController: tabController,
          ),
        ],
      ),
    );
  }
}
