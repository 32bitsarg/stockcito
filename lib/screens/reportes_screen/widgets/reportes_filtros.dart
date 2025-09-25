import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/ui/utility/windows_button.dart';
import '../functions/reportes_functions.dart';

class ReportesFiltros extends StatelessWidget {
  final String filtroCategoria;
  final String filtroTalla;
  final Function(String) onCategoriaChanged;
  final Function(String) onTallaChanged;
  final VoidCallback onLimpiarFiltros;

  const ReportesFiltros({
    super.key,
    required this.filtroCategoria,
    required this.filtroTalla,
    required this.onCategoriaChanged,
    required this.onTallaChanged,
    required this.onLimpiarFiltros,
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
                'Filtros de Reporte',
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
              // Filtro categoría
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filtroCategoria,
                  items: ReportesFunctions.getCategorias().map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (value) => onCategoriaChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Categoría',
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
              ),
              const SizedBox(width: 16),
              // Filtro talla
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: filtroTalla,
                  items: ReportesFunctions.getTallas().map((talla) {
                    return DropdownMenuItem(
                      value: talla,
                      child: Text(talla),
                    );
                  }).toList(),
                  onChanged: (value) => onTallaChanged(value!),
                  decoration: InputDecoration(
                    labelText: 'Talla',
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
              ),
              const SizedBox(width: 16),
              // Botón limpiar filtros
              WindowsButton(
                text: 'Limpiar',
                type: ButtonType.secondary,
                onPressed: onLimpiarFiltros,
                icon: Icons.clear_all,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
