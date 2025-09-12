import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';

class VentasFiltersWidget extends StatelessWidget {
  final List<String> estados;
  final List<String> metodosPago;
  final List<Cliente> clientes;
  final String filtroEstado;
  final String filtroCliente;
  final String filtroMetodoPago;
  final Function(String) onEstadoChanged;
  final Function(String) onClienteChanged;
  final Function(String) onMetodoPagoChanged;

  const VentasFiltersWidget({
    super.key,
    required this.estados,
    required this.metodosPago,
    required this.clientes,
    required this.filtroEstado,
    required this.filtroCliente,
    required this.filtroMetodoPago,
    required this.onEstadoChanged,
    required this.onClienteChanged,
    required this.onMetodoPagoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                Icons.filter_list,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  'Estado',
                  filtroEstado,
                  estados,
                  onEstadoChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  'Cliente',
                  filtroCliente,
                  ['Todos', ...clientes.map((c) => c.nombre).toList()],
                  onClienteChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  'Método de Pago',
                  filtroMetodoPago,
                  metodosPago,
                  onMetodoPagoChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
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
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
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
          ),
        ),
      ],
    );
  }
}
