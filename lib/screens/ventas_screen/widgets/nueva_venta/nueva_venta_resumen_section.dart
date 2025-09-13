import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../widgets/windows_button.dart';
import '../../functions/nueva_venta_functions.dart';

class NuevaVentaResumenSection extends StatelessWidget {
  final String metodoPago;
  final String estado;
  final TextEditingController notasController;
  final double totalVenta;
  final Function(String) onMetodoPagoChanged;
  final Function(String) onEstadoChanged;
  final VoidCallback onLimpiarFormulario;
  final VoidCallback onGuardarVenta;

  const NuevaVentaResumenSection({
    super.key,
    required this.metodoPago,
    required this.estado,
    required this.notasController,
    required this.totalVenta,
    required this.onMetodoPagoChanged,
    required this.onEstadoChanged,
    required this.onLimpiarFormulario,
    required this.onGuardarVenta,
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
                Icons.receipt_long,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Resumen de Venta',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Método de pago y estado
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: metodoPago,
                  items: NuevaVentaFunctions.getMetodosPago().map((metodo) {
                    return DropdownMenuItem(
                      value: metodo,
                      child: Text(metodo),
                    );
                  }).toList(),
                  onChanged: (value) => onMetodoPagoChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Método de pago',
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
              // Estado
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: estado,
                  items: NuevaVentaFunctions.getEstados().map((estado) {
                    return DropdownMenuItem(
                      value: estado,
                      child: Text(estado),
                    );
                  }).toList(),
                  onChanged: (value) => onEstadoChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Estado',
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
          const SizedBox(height: 12),
          // Notas
          TextFormField(
            controller: notasController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notas adicionales',
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
          // Total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  NuevaVentaFunctions.formatPrecio(totalVenta),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botones de acción
          Row(
            children: [
              Expanded(
                child: WindowsButton(
                  text: 'Limpiar',
                  type: ButtonType.secondary,
                  onPressed: onLimpiarFormulario,
                  icon: Icons.clear_all,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: WindowsButton(
                  text: 'Guardar Venta',
                  type: ButtonType.primary,
                  onPressed: onGuardarVenta,
                  icon: Icons.save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
