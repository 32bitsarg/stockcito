import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/categoria.dart';
import '../../../../models/producto.dart';
import '../../../../widgets/animated_widgets.dart';
import '../../../../functions/categoria_functions.dart';

class CategoriaListWidget extends StatelessWidget {
  final List<Categoria> categorias;
  final List<Producto> productos;
  final Function(Categoria) onEditar;
  final Function(Categoria) onEliminar;

  const CategoriaListWidget({
    super.key,
    required this.categorias,
    required this.productos,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      itemCount: categorias.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final categoria = categorias[index];
        return _buildCategoriaCard(context, categoria, index);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              FontAwesomeIcons.tags,
              size: 40,
              color: AppTheme.primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hay categorías',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera categoría para comenzar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaCard(BuildContext context, Categoria categoria, int index) {
    final productosConCategoria = CategoriaFunctions.getProductosConCategoria(categoria, productos);
    final color = CategoriaFunctions.hexToColor(categoria.color);
    final icono = _getIconFromString(categoria.icono);

    return AnimatedCard(
      delay: Duration(milliseconds: 100 + (index * 50)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderColor.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono de la categoría
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              
              // Información de la categoría
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre de la categoría
                    Row(
                      children: [
                        Text(
                          categoria.nombre,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (categoria.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Por defecto',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Descripción
                    if (categoria.descripcion != null && categoria.descripcion!.isNotEmpty)
                      Text(
                        categoria.descripcion!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    
                    // Información adicional
                    Row(
                      children: [
                        // Número de productos
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                FontAwesomeIcons.boxes,
                                color: AppTheme.primaryColor,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${productosConCategoria.length} ${productosConCategoria.length == 1 ? 'producto' : 'productos'}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Color
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Botones de acción
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    context,
                    Icons.edit_outlined,
                    AppTheme.primaryColor,
                    () => onEditar(categoria),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    Icons.delete_outline,
                    AppTheme.errorColor,
                    () => onEliminar(categoria),
                    enabled: !categoria.isDefault && productosConCategoria.isEmpty,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    bool enabled = true,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: enabled 
            ? color.withOpacity(0.1) 
            : AppTheme.borderColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled 
              ? color.withOpacity(0.3) 
              : AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? color : AppTheme.borderColor,
          ),
        ),
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
