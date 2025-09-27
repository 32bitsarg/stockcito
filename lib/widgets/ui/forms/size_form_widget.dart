import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/talla.dart';

/// Widget de formulario para tallas
class SizeFormWidget extends StatefulWidget {
  final Talla? size;
  final Function(Talla) onSave;

  const SizeFormWidget({
    super.key,
    this.size,
    required this.onSave,
  });

  @override
  State<SizeFormWidget> createState() => _SizeFormWidgetState();
}

class _SizeFormWidgetState extends State<SizeFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ordenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.size != null) {
      final size = widget.size!;
      _nombreController.text = size.nombre;
      _descripcionController.text = size.descripcion ?? '';
      _ordenController.text = size.orden.toString();
    } else {
      // Default values for new size
      _ordenController.text = '0';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildSectionTitle(Icons.info, 'Detalles de la Talla'),
            const SizedBox(height: 16),
            
            // Grid de campos
            Expanded(
              child: Column(
                children: [
                  // Nombre de la talla
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration('Nombre de la Talla', FontAwesomeIcons.ruler),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre de la talla no puede estar vacío';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción y Orden
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _descripcionController,
                          decoration: _inputDecoration('Descripción', FontAwesomeIcons.noteSticky),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _ordenController,
                          decoration: _inputDecoration('Orden', FontAwesomeIcons.sortNumericUp),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Orden inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        FaIcon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _handleSave,
      icon: Icon(widget.size == null ? Icons.add : Icons.save),
      label: Text(widget.size == null ? 'Crear Talla' : 'Guardar Cambios'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final size = Talla(
        id: widget.size?.id,
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        orden: int.parse(_ordenController.text),
        fechaCreacion: widget.size?.fechaCreacion ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onSave(size);
    }
  }
}