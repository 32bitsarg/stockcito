import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../functions/editar_producto_functions.dart';

class EditarProductoFormulario extends StatelessWidget {
  final TextEditingController nombreController;
  final TextEditingController costoMaterialesController;
  final TextEditingController costoManoObraController;
  final TextEditingController gastosGeneralesController;
  final TextEditingController margenGananciaController;
  final TextEditingController stockController;
  final String categoriaSeleccionada;
  final String tallaSeleccionada;
  final double iva;
  final Function(String) onCategoriaChanged;
  final Function(String) onTallaChanged;
  final Function(double) onIVAChanged;
  final VoidCallback onCalcularPrecios;

  const EditarProductoFormulario({
    super.key,
    required this.nombreController,
    required this.costoMaterialesController,
    required this.costoManoObraController,
    required this.gastosGeneralesController,
    required this.margenGananciaController,
    required this.stockController,
    required this.categoriaSeleccionada,
    required this.tallaSeleccionada,
    required this.iva,
    required this.onCategoriaChanged,
    required this.onTallaChanged,
    required this.onIVAChanged,
    required this.onCalcularPrecios,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del producto
        _buildSeccion(
          context,
          titulo: 'Información del Producto',
          icono: Icons.info_outline,
          color: AppTheme.primaryColor,
          children: [
            _buildTextField(
              context,
              controller: nombreController,
              label: 'Nombre del producto',
              hint: 'Ej: Body de algodón',
              icon: Icons.shopping_bag,
              validator: EditarProductoFunctions.validateNombre,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    context,
                    value: categoriaSeleccionada,
                    items: EditarProductoFunctions.getCategorias(),
                    label: 'Categoría',
                    icon: Icons.category,
                    onChanged: (value) => onCategoriaChanged(value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    context,
                    value: tallaSeleccionada,
                    items: EditarProductoFunctions.getTallas(),
                    label: 'Talla',
                    icon: Icons.straighten,
                    onChanged: (value) => onTallaChanged(value!),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Costos
        _buildSeccion(
          context,
          titulo: 'Análisis de Costos',
          icono: Icons.attach_money,
          color: AppTheme.secondaryColor,
          children: [
            _buildTextField(
              context,
              controller: costoMaterialesController,
              label: 'Costo de materiales',
              hint: '0.00',
              icon: Icons.inventory,
              keyboardType: TextInputType.number,
              onChanged: (_) => onCalcularPrecios(),
              validator: (value) => EditarProductoFunctions.validateNumero(value, 'el costo de materiales'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: costoManoObraController,
              label: 'Costo de mano de obra',
              hint: '0.00',
              icon: Icons.work,
              keyboardType: TextInputType.number,
              onChanged: (_) => onCalcularPrecios(),
              validator: (value) => EditarProductoFunctions.validateNumero(value, 'el costo de mano de obra'),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context,
              controller: gastosGeneralesController,
              label: 'Gastos generales',
              hint: '0.00',
              icon: Icons.business,
              keyboardType: TextInputType.number,
              onChanged: (_) => onCalcularPrecios(),
              validator: (value) => EditarProductoFunctions.validateNumero(value, 'los gastos generales'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Configuración
        _buildSeccion(
          context,
          titulo: 'Configuración de Precios y Stock',
          icono: Icons.settings,
          color: AppTheme.accentColor,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    context,
                    controller: margenGananciaController,
                    label: 'Margen de ganancia (%)',
                    hint: '50',
                    icon: Icons.trending_up,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onCalcularPrecios(),
                    validator: (value) => EditarProductoFunctions.validateNumero(value, 'el margen'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    context,
                    controller: stockController,
                    label: 'Stock disponible',
                    hint: '1',
                    icon: Icons.inventory_2,
                    keyboardType: TextInputType.number,
                    validator: EditarProductoFunctions.validateStock,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider(
              context,
              value: iva,
              min: 0,
              max: 30,
              divisions: 30,
              label: EditarProductoFunctions.getIVAText(iva),
              onChanged: (value) {
                onIVAChanged(value);
                onCalcularPrecios();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeccion(
    BuildContext context, {
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
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
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
