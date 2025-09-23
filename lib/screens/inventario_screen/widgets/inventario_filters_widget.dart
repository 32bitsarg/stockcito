import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../../../functions/categoria_functions.dart';

class InventarioFiltersWidget extends StatelessWidget {
  final List<Categoria> categorias;
  final List<Talla> tallas;
  final String filtroCategoria;
  final String filtroTalla;
  final String busqueda;
  final bool mostrarSoloStockBajo;
  final Function(String) onCategoriaChanged;
  final Function(String) onTallaChanged;
  final Function(String) onBusquedaChanged;
  final Function(bool) onStockBajoChanged;
  final VoidCallback? onGestionCategorias;
  final VoidCallback? onGestionTallas;

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
    this.onGestionCategorias,
    this.onGestionTallas,
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
              const Spacer(),
              if (onGestionCategorias != null)
                TextButton.icon(
                  onPressed: onGestionCategorias,
                  icon: const Icon(
                    FontAwesomeIcons.tags,
                    size: 16,
                  ),
                  label: const Text('Categorías'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              const SizedBox(width: 8),
              if (onGestionTallas != null)
                TextButton.icon(
                  onPressed: onGestionTallas,
                  icon: const Icon(
                    FontAwesomeIcons.ruler,
                    size: 16,
                  ),
                  label: const Text('Tallas'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
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
                child: _buildCategoriaDropdown(
                  context,
                  'Categoría',
                  filtroCategoria,
                  categorias,
                  onCategoriaChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTallaDropdown(
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

  Widget _buildCategoriaDropdown(
    BuildContext context,
    String label,
    String value,
    List<Categoria> categorias,
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
          items: [
            DropdownMenuItem(
              value: 'Todas',
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.list,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('Todas'),
                ],
              ),
            ),
            ...categorias.map((categoria) => DropdownMenuItem(
              value: categoria.nombre,
              child: Row(
                children: [
                  Icon(
                    _getIconFromString(categoria.icono),
                    color: CategoriaFunctions.hexToColor(categoria.color),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(categoria.nombre),
                ],
              ),
            )),
          ],
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

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'baby': return FontAwesomeIcons.baby;
      case 'tshirt': return FontAwesomeIcons.shirt;
      case 'dress': return FontAwesomeIcons.shirt;
      case 'moon': return FontAwesomeIcons.moon;
      case 'hat-cowboy': return FontAwesomeIcons.hatCowboy;
      case 'gift': return FontAwesomeIcons.gift;
      case 'shopping-bag': return FontAwesomeIcons.bagShopping;
      case 'star': return FontAwesomeIcons.star;
      case 'heart': return FontAwesomeIcons.heart;
      case 'bookmark': return FontAwesomeIcons.bookmark;
      case 'flag': return FontAwesomeIcons.flag;
      case 'home': return FontAwesomeIcons.house;
      case 'user': return FontAwesomeIcons.user;
      case 'cog': return FontAwesomeIcons.gear;
      case 'bell': return FontAwesomeIcons.bell;
      case 'search': return FontAwesomeIcons.magnifyingGlass;
      case 'plus': return FontAwesomeIcons.plus;
      case 'minus': return FontAwesomeIcons.minus;
      case 'edit': return FontAwesomeIcons.pen;
      case 'trash': return FontAwesomeIcons.trash;
      case 'save': return FontAwesomeIcons.floppyDisk;
      case 'download': return FontAwesomeIcons.download;
      case 'upload': return FontAwesomeIcons.upload;
      case 'share': return FontAwesomeIcons.share;
      case 'link': return FontAwesomeIcons.link;
      case 'image': return FontAwesomeIcons.image;
      case 'video': return FontAwesomeIcons.video;
      case 'music': return FontAwesomeIcons.music;
      case 'camera': return FontAwesomeIcons.camera;
      default: return FontAwesomeIcons.tag;
    }
  }

  Widget _buildTallaDropdown(
    BuildContext context,
    String label,
    String value,
    List<Talla> tallas,
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
          items: [
            DropdownMenuItem(
              value: 'Todas',
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.list,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  const Text('Todas'),
                ],
              ),
            ),
            ...tallas.map((talla) => DropdownMenuItem(
              value: talla.nombre,
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.ruler,
                    color: AppTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(talla.nombre),
                ],
              ),
            )),
          ],
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
