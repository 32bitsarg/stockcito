import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../models/costo_directo.dart';

/// Diálogo para agregar/editar costos directos
class CalculadoraCostoDirectoDialog extends StatefulWidget {
  final CostoDirecto? costo;

  const CalculadoraCostoDirectoDialog({
    super.key,
    this.costo,
  });

  @override
  State<CalculadoraCostoDirectoDialog> createState() => _CalculadoraCostoDirectoDialogState();
}

class _CalculadoraCostoDirectoDialogState extends State<CalculadoraCostoDirectoDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _nombre;
  late String _tipo;
  late double _cantidad;
  late String _unidad;
  late double _precioUnitario;
  late double _desperdicio;
  late String _descripcion;

  @override
  void initState() {
    super.initState();
    if (widget.costo != null) {
      _nombre = widget.costo!.nombre;
      _tipo = widget.costo!.tipo;
      _cantidad = widget.costo!.cantidad;
      _unidad = widget.costo!.unidad;
      _precioUnitario = widget.costo!.precioUnitario;
      _desperdicio = widget.costo!.desperdicio;
      _descripcion = widget.costo!.descripcion ?? '';
    } else {
      _nombre = '';
      _tipo = 'material';
      _cantidad = 1.0;
      _unidad = 'unidad';
      _precioUnitario = 0.0;
      _desperdicio = 0.0;
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
                      
                      // Cantidad y precio
                      _buildQuantityAndPrice(),
                      const SizedBox(height: 16),
                      
                      // Desperdicio
                      _buildWasteSection(),
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
          widget.costo != null ? 'Editar Costo Directo' : 'Agregar Costo Directo',
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
                hint: 'Ej: Tela de algodón',
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
                items: CostoDirecto.getTiposDisponibles(),
                onChanged: (value) {
                  setState(() {
                    _tipo = value ?? 'material';
                    _unidad = CostoDirecto.getUnidadesPorTipo(_tipo).first;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityAndPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cantidad y Precio',
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
                label: 'Cantidad',
                hint: '1.0',
                value: _cantidad.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final cantidad = double.tryParse(value);
                  if (cantidad != null) {
                    _cantidad = cantidad;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La cantidad es obligatoria';
                  }
                  final cantidad = double.tryParse(value);
                  if (cantidad == null || cantidad <= 0) {
                    return 'La cantidad debe ser mayor a 0';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDropdownField(
                label: 'Unidad',
                value: _unidad,
                items: CostoDirecto.getUnidadesPorTipo(_tipo),
                onChanged: (value) => _unidad = value ?? 'unidad',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Precio Unitario',
                hint: '0.00',
                value: _precioUnitario.toString(),
                keyboardType: TextInputType.number,
                prefix: const Text('\$ '),
                onChanged: (value) {
                  final precio = double.tryParse(value);
                  if (precio != null) {
                    _precioUnitario = precio;
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El precio es obligatorio';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null || precio <= 0) {
                    return 'El precio debe ser mayor a 0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Desperdicio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Porcentaje de desperdicio o pérdida de material',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Desperdicio (%)',
          hint: '0.0',
          value: _desperdicio.toString(),
          keyboardType: TextInputType.number,
          suffix: const Text('%'),
          onChanged: (value) {
            final desperdicio = double.tryParse(value);
            if (desperdicio != null) {
              _desperdicio = desperdicio;
            }
          },
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
    required List<dynamic> items,
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
            final itemMap = item is Map ? item : {'id': item, 'nombre': item};
            return DropdownMenuItem<String>(
              value: itemMap['id'],
              child: Row(
                children: [
                  if (itemMap['icono'] != null) ...[
                    Text(itemMap['icono'], style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                  ],
                  Text(itemMap['nombre']),
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
            backgroundColor: AppTheme.primaryColor,
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

  Future<void> _save() async {
    if (_formKey.currentState?.validate() ?? false) {
      final costo = CostoDirecto.nuevo(
        nombre: _nombre,
        tipo: _tipo,
        cantidad: _cantidad,
        unidad: _unidad,
        precioUnitario: _precioUnitario,
        desperdicio: _desperdicio,
        descripcion: _descripcion.isEmpty ? null : _descripcion,
      );

      Navigator.pop(context, costo);
    }
  }
}
