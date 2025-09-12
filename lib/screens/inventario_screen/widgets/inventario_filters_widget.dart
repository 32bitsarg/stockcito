import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

class InventarioFiltersWidget extends StatelessWidget {
  final List<String> categorias;
  final List<String> tallas;
  final String filtroCategoria;
  final String filtroTalla;
  final String busqueda;
  final bool mostrarSoloStockBajo;
  final Function(String) onCategoriaChanged;
  final Function(String) onTallaChanged;
  final Function(String) onBusquedaChanged;
  final Function(bool) onStockBajoChanged;

  const InventarioFiltersWidget({
    super.key,
    required this.categorias,
    required this.tallas,
    required this.filtroCategoria,
    required this.filtroTalla,
    required this.busqueda,
    required this.mostrarSoloStockBajo,
    required this.onCategoriaChanged,
    required this.onTallaChanged,
    required this.onBusquedaChanged,
    required this.onStockBajoChanged,
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
                'Filtros y Búsqueda',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
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
            onChanged: onBusquedaChanged,
            controller: TextEditingController(text: busqueda),
          ),
          const SizedBox(height: 16),
          
          // Filtros
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  'Categoría',
                  filtroCategoria,
                  categorias,
                  onCategoriaChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  context,
                  'Talla',
                  filtroTalla,
                  tallas,
                  onTallaChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStockBajoFilter(context),
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

  Widget _buildStockBajoFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Stock Bajo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: mostrarSoloStockBajo ? AppTheme.primaryColor : AppTheme.borderColor,
              width: mostrarSoloStockBajo ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: mostrarSoloStockBajo,
                onChanged: (value) {
                  onStockBajoChanged(value ?? false);
                },
                activeColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Solo productos con stock bajo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
}
