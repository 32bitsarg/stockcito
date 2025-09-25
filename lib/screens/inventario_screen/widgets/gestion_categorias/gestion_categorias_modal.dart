import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/categoria.dart';
import '../../../../models/producto.dart';
import '../../../../widgets/ui/utility/animated_widgets.dart';
import '../../../../functions/categoria_functions.dart';
import 'categoria_list_widget.dart';
import 'categoria_form_modal.dart';

class GestionCategoriasModal extends StatefulWidget {
  final List<Categoria> categorias;
  final List<Producto> productos;
  final Function(List<Categoria>) onCategoriasChanged;

  const GestionCategoriasModal({
    super.key,
    required this.categorias,
    required this.productos,
    required this.onCategoriasChanged,
  });

  @override
  State<GestionCategoriasModal> createState() => _GestionCategoriasModalState();
}

class _GestionCategoriasModalState extends State<GestionCategoriasModal> {
  List<Categoria> _categorias = [];

  @override
  void initState() {
    super.initState();
    _categorias = List.from(widget.categorias);
  }

  Future<void> _agregarCategoria() async {
    final result = await showDialog<Categoria>(
      context: context,
      builder: (context) => CategoriaFormModal(
        categoriasExistentes: _categorias,
      ),
    );

    if (result != null) {
      setState(() {
        _categorias.add(result);
      });
      widget.onCategoriasChanged(_categorias);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CategoriaFunctions.getSuccessMessage('crear', result.nombre)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _editarCategoria(Categoria categoria) async {
    final result = await showDialog<Categoria>(
      context: context,
      builder: (context) => CategoriaFormModal(
        categoria: categoria,
        categoriasExistentes: _categorias,
      ),
    );

    if (result != null) {
      setState(() {
        final index = _categorias.indexWhere((c) => c.id == categoria.id);
        if (index != -1) {
          _categorias[index] = result;
        }
      });
      widget.onCategoriasChanged(_categorias);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CategoriaFunctions.getSuccessMessage('editar', result.nombre)),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    // Verificar si se puede eliminar
    final puedeEliminar = await CategoriaFunctions.canDeleteCategoria(categoria, widget.productos);
    
    if (!puedeEliminar) {
      final mensaje = CategoriaFunctions.getCategoriaNoEliminableMessage(categoria, widget.productos);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
      return;
    }

    // Confirmar eliminación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de que quieres eliminar la categoría "${categoria.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() {
        _categorias.removeWhere((c) => c.id == categoria.id);
      });
      widget.onCategoriasChanged(_categorias);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(CategoriaFunctions.getSuccessMessage('eliminar', categoria.nombre)),
            backgroundColor: AppTheme.successColor,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
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
                    child: const Icon(
                      FontAwesomeIcons.tags,
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
                          'Gestión de Categorías',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Administra las categorías de tus productos',
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón agregar
                    Row(
                      children: [
                        AnimatedButton(
                          text: 'Agregar Categoría',
                          type: ButtonType.primary,
                          onPressed: _agregarCategoria,
                          icon: FontAwesomeIcons.plus,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${_categorias.length} ${_categorias.length == 1 ? 'categoría' : 'categorías'}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Lista de categorías
                    Expanded(
                      child: CategoriaListWidget(
                        categorias: _categorias,
                        productos: widget.productos,
                        onEditar: _editarCategoria,
                        onEliminar: _eliminarCategoria,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
