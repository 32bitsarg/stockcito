import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';

/// Widget de formulario para clientes
class ClientFormWidget extends StatefulWidget {
  final Cliente? client;
  final Function(Cliente) onSave;

  const ClientFormWidget({
    super.key,
    this.client,
    required this.onSave,
  });

  @override
  State<ClientFormWidget> createState() => _ClientFormWidgetState();
}

class _ClientFormWidgetState extends State<ClientFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.client != null) {
      final client = widget.client!;
      _nombreController.text = client.nombre;
      _telefonoController.text = client.telefono;
      _emailController.text = client.email;
      _direccionController.text = client.direccion;
      _notasController.text = client.notas;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _notasController.dispose();
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
            _buildSectionTitle(Icons.info, 'Detalles del Cliente'),
            const SizedBox(height: 16),
            
            // Grid de campos principales
            Expanded(
              child: Column(
                children: [
                  // Fila 1: Nombre del cliente
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration('Nombre del Cliente', FontAwesomeIcons.user),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre del cliente no puede estar vacío';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila 2: Teléfono y Email
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _telefonoController,
                          decoration: _inputDecoration('Teléfono', FontAwesomeIcons.phone),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Teléfono requerido';
                            }
                            if (value.length < 10) {
                              return 'Mínimo 10 dígitos';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email', FontAwesomeIcons.envelope),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email requerido';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila 3: Dirección
                  TextFormField(
                    controller: _direccionController,
                    decoration: _inputDecoration('Dirección', FontAwesomeIcons.locationDot),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La dirección no puede estar vacía';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila 4: Notas
                  TextFormField(
                    controller: _notasController,
                    decoration: _inputDecoration('Notas (Opcional)', FontAwesomeIcons.noteSticky),
                    maxLines: 2,
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
      icon: Icon(widget.client == null ? Icons.add : Icons.save),
      label: Text(widget.client == null ? 'Crear Cliente' : 'Guardar Cambios'),
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
      final client = Cliente(
        id: widget.client?.id,
        nombre: _nombreController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim(),
        direccion: _direccionController.text.trim(),
        fechaRegistro: widget.client?.fechaRegistro ?? DateTime.now(),
        notas: _notasController.text.trim().isEmpty 
            ? '' 
            : _notasController.text.trim(),
      );

      widget.onSave(client);
    }
  }
}
