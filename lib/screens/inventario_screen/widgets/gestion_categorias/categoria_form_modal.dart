import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/categoria.dart';
import '../../../../widgets/ui/utility/animated_widgets.dart';
import '../../../../functions/categoria_functions.dart';
import '../../../../services/datos/datos.dart';
import '../../../../services/auth/supabase_auth_service.dart';
import 'color_picker_widget.dart';
import 'icon_picker_widget.dart';

class CategoriaFormModal extends StatefulWidget {
  final Categoria? categoria; // null para crear, objeto para editar
  final List<Categoria> categoriasExistentes;

  const CategoriaFormModal({
    super.key,
    this.categoria,
    required this.categoriasExistentes,
  });

  @override
  State<CategoriaFormModal> createState() => _CategoriaFormModalState();
}

class _CategoriaFormModalState extends State<CategoriaFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final DatosService _datosService = DatosService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  
  String _colorSeleccionado = '#9E9E9E';
  String _iconoSeleccionado = 'tag';
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosCategoria();
  }

  void _cargarDatosCategoria() {
    if (widget.categoria != null) {
      _nombreController.text = widget.categoria!.nombre;
      _descripcionController.text = widget.categoria!.descripcion ?? '';
      _colorSeleccionado = widget.categoria!.color;
      _iconoSeleccionado = widget.categoria!.icono;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardarCategoria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      final categoria = Categoria(
        id: widget.categoria?.id,
        nombre: _nombreController.text.trim(),
        color: _colorSeleccionado,
        icono: _iconoSeleccionado,
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        fechaCreacion: widget.categoria?.fechaCreacion ?? DateTime.now(),
        updatedAt: DateTime.now(),
        userId: widget.categoria?.userId ?? _authService.currentUserId ?? 'default',
        isDefault: widget.categoria?.isDefault ?? false,
      );

      Categoria categoriaGuardada;
      if (widget.categoria == null) {
        // Crear nueva categoría
        categoriaGuardada = await _datosService.saveCategoria(categoria);
      } else {
        // Actualizar categoría existente
        categoriaGuardada = await _datosService.updateCategoria(categoria);
      }

      setState(() {
        _cargando = false;
      });

      if (mounted) {
        Navigator.of(context).pop(categoriaGuardada);
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando categoría: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.categoria != null;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
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
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      esEdicion ? FontAwesomeIcons.edit : FontAwesomeIcons.plus,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esEdicion ? 'Editar Categoría' : 'Nueva Categoría',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          esEdicion 
                              ? 'Modifica los datos de la categoría'
                              : 'Crea una nueva categoría para tus productos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo nombre
                      Text(
                        'Nombre de la categoría',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Ropa de verano',
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
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          if (value.trim().length < 2) {
                            return 'El nombre debe tener al menos 2 caracteres';
                          }
                          if (value.trim().length > 50) {
                            return 'El nombre no puede exceder 50 caracteres';
                          }
                          
                          // Verificar nombre único
                          final existe = widget.categoriasExistentes.any((c) => 
                            c.nombre.toLowerCase() == value.trim().toLowerCase() && 
                            c.id != widget.categoria?.id
                          );
                          if (existe) {
                            return 'Ya existe una categoría con este nombre';
                          }
                          
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Selector de color
                      Text(
                        'Color de la categoría',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ColorPickerWidget(
                        colorSeleccionado: _colorSeleccionado,
                        onColorChanged: (color) {
                          setState(() {
                            _colorSeleccionado = color;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Selector de icono
                      Text(
                        'Icono de la categoría',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconPickerWidget(
                        iconoSeleccionado: _iconoSeleccionado,
                        onIconoChanged: (icono) {
                          setState(() {
                            _iconoSeleccionado = icono;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Campo descripción
                      Text(
                        'Descripción (opcional)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descripcionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe brevemente esta categoría...',
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
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Preview de la categoría
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.borderColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: CategoriaFunctions.hexToColor(_colorSeleccionado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: CategoriaFunctions.hexToColor(_colorSeleccionado).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                _getIconFromString(_iconoSeleccionado),
                                color: CategoriaFunctions.hexToColor(_colorSeleccionado),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nombreController.text.isEmpty ? 'Nombre de la categoría' : _nombreController.text,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (_descripcionController.text.isNotEmpty)
                                    Text(
                                      _descripcionController.text,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Botones de acción
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedButton(
                      text: 'Cancelar',
                      type: ButtonType.outline,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedButton(
                      text: esEdicion ? 'Actualizar' : 'Crear',
                      type: ButtonType.primary,
                      onPressed: _cargando ? null : _guardarCategoria,
                      isLoading: _cargando,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
