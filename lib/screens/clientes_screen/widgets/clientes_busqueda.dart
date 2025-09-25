import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/ui/utility/windows_button.dart';

class ClientesBusqueda extends StatelessWidget {
  final String filtroBusqueda;
  final Function(String) onBusquedaChanged;
  final VoidCallback onLimpiarBusqueda;

  const ClientesBusqueda({
    super.key,
    required this.filtroBusqueda,
    required this.onBusquedaChanged,
    required this.onLimpiarBusqueda,
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
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onBusquedaChanged,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, teléfono o email...',
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (filtroBusqueda.isNotEmpty)
            WindowsButton(
              text: 'Limpiar',
              type: ButtonType.secondary,
              onPressed: onLimpiarBusqueda,
              icon: Icons.clear,
            ),
        ],
      ),
    );
  }
}
