import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/talla.dart';
import '../../../../models/producto.dart';
import '../../../../services/datos/datos.dart';
import '../../../../functions/talla_functions.dart';
import 'talla_list_widget.dart';
import 'talla_form_modal.dart';

class GestionTallasModal extends StatefulWidget {
  final List<Talla> tallas;
  final List<Producto> productos;
  final Function(List<Talla>) onTallasChanged;

  const GestionTallasModal({
    super.key,
    required this.tallas,
    required this.productos,
    required this.onTallasChanged,
  });

  @override
  State<GestionTallasModal> createState() => _GestionTallasModalState();
}

class _GestionTallasModalState extends State<GestionTallasModal> {
  List<Talla> _tallas = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _tallas = List.from(widget.tallas);
  }

  Future<void> _crearTalla() async {
    final result = await showDialog<Talla>(
      context: context,
      builder: (context) => TallaFormModal(
        talla: null,
        tallasExistentes: _tallas,
      ),
    );

    if (result != null) {
      setState(() {
        _cargando = true;
      });

      try {
        final nuevaTalla = await DatosService().saveTalla(result);
        setState(() {
          _tallas.add(nuevaTalla);
          _tallas.sort((a, b) => a.orden.compareTo(b.orden));
        });
        
        widget.onTallasChanged(_tallas);
        TallaFunctions.showSuccessSnackBar(context, 'Talla creada exitosamente');
      } catch (e) {
        TallaFunctions.showErrorSnackBar(context, 'Error al crear talla: $e');
      } finally {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _editarTalla(Talla talla) async {
    final result = await showDialog<Talla>(
      context: context,
      builder: (context) => TallaFormModal(
        talla: talla,
        tallasExistentes: _tallas,
      ),
    );

    if (result != null) {
      setState(() {
        _cargando = true;
      });

      try {
        final tallaActualizada = await DatosService().updateTalla(result);
        setState(() {
          final index = _tallas.indexWhere((t) => t.id == tallaActualizada.id);
          if (index != -1) {
            _tallas[index] = tallaActualizada;
            _tallas.sort((a, b) => a.orden.compareTo(b.orden));
          }
        });
        
        widget.onTallasChanged(_tallas);
        TallaFunctions.showSuccessSnackBar(context, 'Talla actualizada exitosamente');
      } catch (e) {
        TallaFunctions.showErrorSnackBar(context, 'Error al actualizar talla: $e');
      } finally {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  Future<void> _eliminarTalla(Talla talla) async {
    // Verificar si la talla tiene productos asociados
    final productosConTalla = widget.productos.where((p) => p.talla == talla.nombre).toList();
    
    if (productosConTalla.isNotEmpty) {
      final nombresProductos = productosConTalla.map((p) => p.nombre).join(', ');
      TallaFunctions.showErrorSnackBar(
        context, 
        'No se puede eliminar esta talla porque tiene productos asociados: $nombresProductos'
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar la talla "${talla.nombre}"?'),
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
        _cargando = true;
      });

      try {
        await DatosService().deleteTalla(talla.id!);
        setState(() {
          _tallas.removeWhere((t) => t.id == talla.id);
        });
        
        widget.onTallasChanged(_tallas);
        TallaFunctions.showSuccessSnackBar(context, 'Talla eliminada exitosamente');
      } catch (e) {
        TallaFunctions.showErrorSnackBar(context, 'Error al eliminar talla: $e');
      } finally {
        setState(() {
          _cargando = false;
        });
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
              color: Colors.black.withOpacity(0.1),
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
                color: AppTheme.primaryColor.withOpacity(0.1),
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
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.ruler,
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
                          'Gestión de Tallas',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Administra las tallas disponibles para tus productos',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : TallaListWidget(
                      tallas: _tallas,
                      onEditar: _editarTalla,
                      onEliminar: _eliminarTalla,
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cargando ? null : _crearTalla,
                      icon: const Icon(FontAwesomeIcons.plus),
                      label: const Text('Nueva Talla'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(FontAwesomeIcons.check),
                      label: const Text('Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
}
