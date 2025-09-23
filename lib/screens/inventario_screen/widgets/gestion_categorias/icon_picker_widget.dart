import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../functions/categoria_functions.dart';

class IconPickerWidget extends StatefulWidget {
  final String iconoSeleccionado;
  final Function(String) onIconoChanged;

  const IconPickerWidget({
    super.key,
    required this.iconoSeleccionado,
    required this.onIconoChanged,
  });

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  late String _iconoSeleccionado;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _iconoSeleccionado = widget.iconoSeleccionado;
  }

  @override
  Widget build(BuildContext context) {
    final iconosPredefinidos = CategoriaFunctions.getIconosPredefinidos();
    final iconosFiltrados = iconosPredefinidos.where((icono) => 
      icono.toLowerCase().contains(_busqueda.toLowerCase())
    ).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono actual seleccionado
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _getIconFromString(_iconoSeleccionado),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _iconoSeleccionado,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Campo de búsqueda
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar icono...',
              prefixIcon: const Icon(Icons.search),
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
            onChanged: (value) {
              setState(() {
                _busqueda = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Grid de iconos
          SizedBox(
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: iconosFiltrados.length,
              itemBuilder: (context, index) {
                final icono = iconosFiltrados[index];
                final isSelected = _iconoSeleccionado == icono;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _iconoSeleccionado = icono;
                    });
                    widget.onIconoChanged(icono);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : AppTheme.borderColor.withOpacity(0.5),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      _getIconFromString(icono),
                      color: isSelected 
                          ? AppTheme.primaryColor 
                          : AppTheme.textSecondary,
                      size: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
}
