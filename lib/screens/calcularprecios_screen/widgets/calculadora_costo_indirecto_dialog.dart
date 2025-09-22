import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../models/costo_indirecto.dart';

/// Diálogo para agregar/editar costos indirectos
class CalculadoraCostoIndirectoDialog extends StatefulWidget {
  final CostoIndirecto? costo;

  const CalculadoraCostoIndirectoDialog({
    super.key,
    this.costo,
  });

  @override
  State<CalculadoraCostoIndirectoDialog> createState() => _CalculadoraCostoIndirectoDialogState();
}

class _CalculadoraCostoIndirectoDialogState extends State<CalculadoraCostoIndirectoDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _tipo;
  late double _costoMensual;
  late int _productosEstimadosMensuales;
  late String _descripcion;

  @override
  void initState() {
    super.initState();
    if (widget.costo != null) {
      _nombre = widget.costo!.nombre;
      _tipo = widget.costo!.tipo;
      _costoMensual = widget.costo!.costoMensual;
      _productosEstimadosMensuales = widget.costo!.productosEstimadosMensuales;
      _descripcion = widget.costo!.descripcion ?? '';
    } else {
      _nombre = '';
      _tipo = 'alquiler';
      _costoMensual = 0.0;
      _productosEstimadosMensuales = 1;
      _descripcion = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Información básica
                      _buildBasicInfo(),
                      const SizedBox(height: 16),
                      
                      // Costo mensual
                      _buildMonthlyCost(),
                      const SizedBox(height: 16),
                      
                      // Productos estimados
                      _buildEstimatedProducts(),
                      const SizedBox(height: 16),
                      
                      // Descripción
                      _buildDescription(),
                    ],
                  ),
                ),
              ),
              
              // Botones
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const FaIcon(
            FontAwesomeIcons.house,
            color: AppTheme.secondaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          widget.costo != null ? 'Editar Costo Indirecto' : 'Agregar Costo Indirecto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Nombre',
                hint: 'Ej: Alquiler del local',
                value: _nombre,
                onChanged: (value) => _nombre = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Tipo',
                value: _tipo,
                items: CostoIndirecto.getTiposDisponibles(),
                onChanged: (value) => _tipo = value ?? 'alquiler',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.lightbulb,
                color: AppTheme.infoColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  CostoIndirecto.getSugerenciaPorTipo(_tipo),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCost() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Costo Mensual',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Costo Mensual',
          hint: '0.00',
          value: _costoMensual.toString(),
          keyboardType: TextInputType.number,
          prefix: const Text('\$ '),
          onChanged: (value) {
            final costo = double.tryParse(value);
            if (costo != null) {
              _costoMensual = costo;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El costo mensual es obligatorio';
            }
            final costo = double.tryParse(value);
            if (costo == null || costo <= 0) {
              return 'El costo debe ser mayor a 0';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEstimatedProducts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos Estimados Mensuales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cantidad aproximada de productos que planeas producir/vender por mes',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Productos por Mes',
          hint: '1',
          value: _productosEstimadosMensuales.toString(),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final productos = int.tryParse(value);
            if (productos != null) {
              _productosEstimadosMensuales = productos;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La cantidad es obligatoria';
            }
            final productos = int.tryParse(value);
            if (productos == null || productos <= 0) {
              return 'La cantidad debe ser mayor a 0';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Costo por Producto:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '\$${_calculateCostPerProduct().toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descripción (Opcional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Descripción',
          hint: 'Detalles adicionales...',
          value: _descripcion,
          maxLines: 3,
          onChanged: (value) => _descripcion = value,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? prefix,
    Widget? suffix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefix: prefix,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['id'],
              child: Row(
                children: [
                  Text(item['icono'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(item['nombre']),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(widget.costo != null ? 'Actualizar' : 'Agregar'),
        ),
      ],
    );
  }

  double _calculateCostPerProduct() {
    if (_productosEstimadosMensuales > 0) {
      return _costoMensual / _productosEstimadosMensuales;
    }
    return 0.0;
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final costo = CostoIndirecto.nuevo(
        nombre: _nombre,
        tipo: _tipo,
        costoMensual: _costoMensual,
        productosEstimadosMensuales: _productosEstimadosMensuales,
        descripcion: _descripcion.isEmpty ? null : _descripcion,
      );

      Navigator.pop(context, costo);
    }
  }
}
