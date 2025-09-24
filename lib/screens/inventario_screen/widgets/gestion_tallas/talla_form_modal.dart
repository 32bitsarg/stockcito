import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/talla.dart';
import '../../../../services/datos/datos.dart';
import '../../../../services/auth/supabase_auth_service.dart';

class TallaFormModal extends StatefulWidget {
  final Talla? talla;
  final List<Talla> tallasExistentes;

  const TallaFormModal({
    super.key,
    this.talla,
    required this.tallasExistentes,
  });

  @override
  State<TallaFormModal> createState() => _TallaFormModalState();
}

class _TallaFormModalState extends State<TallaFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ordenController = TextEditingController();
  final DatosService _datosService = DatosService();
  final SupabaseAuthService _authService = SupabaseAuthService();
  bool _cargando = false;

  bool get esEdicion => widget.talla != null;

  @override
  void initState() {
    super.initState();
    if (esEdicion) {
      _nombreController.text = widget.talla!.nombre;
      _descripcionController.text = widget.talla!.descripcion ?? '';
      _ordenController.text = widget.talla!.orden.toString();
    } else {
      _ordenController.text = (widget.tallasExistentes.length + 1).toString();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ordenController.dispose();
    super.dispose();
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre de la talla es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (value.trim().length > 50) {
      return 'El nombre no puede exceder los 50 caracteres';
    }

    // Verificar nombre único
    final nombreExistente = widget.tallasExistentes.any((t) =>
        t.nombre.toLowerCase() == value.trim().toLowerCase() &&
        t.id != widget.talla?.id);
    if (nombreExistente) {
      return 'Ya existe una talla con este nombre';
    }

    return null;
  }

  String? _validateOrden(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El orden es requerido';
    }
    final orden = int.tryParse(value.trim());
    if (orden == null) {
      return 'El orden debe ser un número válido';
    }
    if (orden < 0) {
      return 'El orden no puede ser negativo';
    }
    return null;
  }

  Future<void> _guardarTalla() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _cargando = true;
    });

    try {
      
      final talla = Talla(
        id: widget.talla?.id, // Esto debería ser null para nuevas tallas
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim().isEmpty 
            ? null 
            : _descripcionController.text.trim(),
        orden: int.parse(_ordenController.text.trim()),
        isDefault: widget.talla?.isDefault ?? false,
        userId: widget.talla?.userId ?? _authService.currentUserId ?? 'default',
        fechaCreacion: widget.talla?.fechaCreacion ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      

      Talla tallaGuardada;
      if (widget.talla == null) {
        // Crear nueva talla
        tallaGuardada = await _datosService.saveTalla(talla);
      } else {
        // Actualizar talla existente
        tallaGuardada = await _datosService.updateTalla(talla);
      }

      setState(() {
        _cargando = false;
      });

      if (mounted) {
        Navigator.of(context).pop(tallaGuardada);
      }
    } catch (e) {
      setState(() {
        _cargando = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando talla: $e'),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        constraints: const BoxConstraints(maxWidth: 500),
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
          mainAxisSize: MainAxisSize.min,
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
                    child: Icon(
                      esEdicion ? FontAwesomeIcons.pen : FontAwesomeIcons.plus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          esEdicion ? 'Editar Talla' : 'Nueva Talla',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          esEdicion 
                              ? 'Modifica los datos de la talla'
                              : 'Agrega una nueva talla al sistema',
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

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      'Nombre de la talla',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        hintText: 'Ej: 0-3 meses, S, M, L...',
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
                        prefixIcon: const Icon(
                          FontAwesomeIcons.ruler,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 20),

                    // Descripción
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
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ej: Recién nacido, Talla pequeña...',
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
                        prefixIcon: const Icon(
                          FontAwesomeIcons.comment,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Orden
                    Text(
                      'Orden de visualización',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ordenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ej: 1, 2, 3...',
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
                        prefixIcon: const Icon(
                          FontAwesomeIcons.sortNumericUp,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      validator: _validateOrden,
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cargando ? null : () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              side: BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _cargando ? null : _guardarTalla,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(esEdicion ? 'Actualizar' : 'Crear'),
                          ),
                        ),
                      ],
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
