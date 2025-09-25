import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';
import '../../../widgets/ui/utility/windows_button.dart';
import '../functions/clientes_functions.dart';

class ClientesFormulario extends StatefulWidget {
  final bool isEditing;
  final Cliente? cliente;
  final Function({
    required bool isEditing,
    Cliente? cliente,
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) onGuardar;

  const ClientesFormulario({
    super.key,
    required this.isEditing,
    this.cliente,
    required this.onGuardar,
  });

  @override
  State<ClientesFormulario> createState() => _ClientesFormularioState();
}

class _ClientesFormularioState extends State<ClientesFormulario> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _emailController;
  late final TextEditingController _direccionController;
  late final TextEditingController _notasController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.cliente?.nombre ?? '');
    _telefonoController = TextEditingController(text: widget.cliente?.telefono ?? '');
    _emailController = TextEditingController(text: widget.cliente?.email ?? '');
    _direccionController = TextEditingController(text: widget.cliente?.direccion ?? '');
    _notasController = TextEditingController(text: widget.cliente?.notas ?? '');
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ClientesFunctions.getFormularioIcon(widget.isEditing),
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            ClientesFunctions.getFormularioTitulo(widget.isEditing),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ClientesFunctions.getFormularioDescripcion(widget.isEditing),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botón cerrar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Formulario
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Cliente *',
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
                        fillColor: AppTheme.surfaceColor,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: ClientesFunctions.validateNombre,
                    ),
                    const SizedBox(height: 16),
                    // Teléfono
                    TextFormField(
                      controller: _telefonoController,
                      decoration: InputDecoration(
                        labelText: 'Teléfono *',
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
                        fillColor: AppTheme.surfaceColor,
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: ClientesFunctions.validateTelefono,
                    ),
                    const SizedBox(height: 16),
                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
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
                        fillColor: AppTheme.surfaceColor,
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: ClientesFunctions.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    // Dirección
                    TextFormField(
                      controller: _direccionController,
                      decoration: InputDecoration(
                        labelText: 'Dirección',
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
                        fillColor: AppTheme.surfaceColor,
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Notas
                    TextFormField(
                      controller: _notasController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Notas adicionales',
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
                        fillColor: AppTheme.surfaceColor,
                        prefixIcon: const Icon(Icons.note),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: WindowsButton(
                            text: 'Cancelar',
                            type: ButtonType.secondary,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icons.cancel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: WindowsButton(
                            text: ClientesFunctions.getBotonGuardarText(widget.isEditing),
                            type: ButtonType.primary,
                            onPressed: _guardarCliente,
                            icon: ClientesFunctions.getBotonGuardarIcon(widget.isEditing),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _guardarCliente() {
    if (_formKey.currentState!.validate()) {
      widget.onGuardar(
        isEditing: widget.isEditing,
        cliente: widget.cliente,
        nombre: _nombreController.text,
        telefono: _telefonoController.text,
        email: _emailController.text,
        direccion: _direccionController.text,
        notas: _notasController.text,
      );
    }
  }
}
