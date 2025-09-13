import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/cliente.dart';
import '../../functions/nueva_venta_functions.dart';

class NuevaVentaClienteSection extends StatelessWidget {
  final Cliente? clienteSeleccionado;
  final List<Cliente> clientes;
  final TextEditingController clienteController;
  final TextEditingController telefonoController;
  final TextEditingController emailController;
  final TextEditingController direccionController;
  final Function(Cliente?) onClienteChanged;

  const NuevaVentaClienteSection({
    super.key,
    required this.clienteSeleccionado,
    required this.clientes,
    required this.clienteController,
    required this.telefonoController,
    required this.emailController,
    required this.direccionController,
    required this.onClienteChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.user,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Cliente (Opcional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Selector de cliente compacto
          DropdownButtonFormField<Cliente?>(
            value: clienteSeleccionado,
            items: [
              const DropdownMenuItem<Cliente?>(
                value: null,
                child: Text('Cliente existente'),
              ),
              ...clientes.map((cliente) {
                return DropdownMenuItem<Cliente?>(
                  value: cliente,
                  child: Text(NuevaVentaFunctions.getClienteDropdownText(cliente)),
                );
              }).toList(),
            ],
            onChanged: (cliente) {
              onClienteChanged(cliente);
            },
            decoration: InputDecoration(
              labelText: 'Seleccionar cliente',
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
          ),
          const SizedBox(height: 12),
          // Campos de cliente compactos
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: clienteController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: telefonoController,
                  decoration: InputDecoration(
                    labelText: 'Teléfono',
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
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
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: direccionController,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
