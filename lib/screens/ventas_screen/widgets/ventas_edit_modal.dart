import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../../../widgets/ui/utility/animated_widgets.dart';
import '../functions/ventas_functions.dart';
import '../services/ventas_edit_service.dart';

class VentasEditModal extends StatefulWidget {
  final Venta venta;

  const VentasEditModal({
    super.key,
    required this.venta,
  });

  static Future<void> show(BuildContext context, Venta venta) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: VentasEditModal(venta: venta),
          ),
        ),
      ),
    );
  }

  @override
  State<VentasEditModal> createState() => _VentasEditModalState();
}

class _VentasEditModalState extends State<VentasEditModal> {
  late String _estado;
  late String _metodoPago;
  late String _notas;
  
  final List<String> _estados = ['Pendiente', 'Completada', 'Cancelada'];
  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];
  
  // Servicio y estado
  final VentasEditService _ventasEditService = VentasEditService();
  bool _isLoading = false;
  bool _canEdit = true;

  @override
  void initState() {
    super.initState();
    _estado = widget.venta.estado;
    _metodoPago = widget.venta.metodoPago;
    _notas = widget.venta.notas;
    _checkIfCanEdit();
  }

  Future<void> _checkIfCanEdit() async {
    try {
      final canEdit = await _ventasEditService.canEditVenta(widget.venta.id!);
      if (mounted) {
        setState(() {
          _canEdit = canEdit;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canEdit = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Editar Venta'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de advertencia si no se puede editar
            if (!_canEdit) ...[
              _buildWarningBanner(context),
              const SizedBox(height: 16),
            ],
            
            // Información de la venta
            _buildEditarInfo(context),
            const SizedBox(height: 24),
            
            // Formulario de edición
            _buildEditarFormulario(context),
            const SizedBox(height: 24),
            
            // Botones de acción
            _buildEditarAcciones(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: AppTheme.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Venta no editable',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Esta venta no puede ser editada debido a su estado actual.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.warningColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditarInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
              Icons.edit,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editando Venta #${widget.venta.id}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cliente: ${widget.venta.cliente}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${VentasFunctions.formatPrecio(widget.venta.total)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditarFormulario(BuildContext context) {
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
                Icons.edit_note,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Editar Información',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Estado de la venta
          _buildEditarCampo(
            context,
            'Estado',
            _estado,
            _estados,
            (value) => setState(() => _estado = value),
          ),
          const SizedBox(height: 16),
          
          // Método de pago
          _buildEditarCampo(
            context,
            'Método de Pago',
            _metodoPago,
            _metodosPago,
            (value) => setState(() => _metodoPago = value),
          ),
          const SizedBox(height: 16),
          
          // Notas adicionales
          _buildEditarNotas(context),
        ],
      ),
    );
  }

  Widget _buildEditarCampo(
    BuildContext context,
    String label,
    String valor,
    List<String> opciones,
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
          value: valor,
          items: opciones.map((opcion) {
            return DropdownMenuItem(
              value: opcion,
              child: Text(opcion),
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

  Widget _buildEditarNotas(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notas Adicionales',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _notas,
          maxLines: 3,
          onChanged: (value) => setState(() => _notas = value),
          decoration: InputDecoration(
            hintText: 'Agregar notas sobre la venta...',
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

  Widget _buildEditarAcciones(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            text: _isLoading ? 'Guardando...' : 'Guardar Cambios',
            type: ButtonType.primary,
            onPressed: _isLoading || !_canEdit ? null : () => _guardarCambiosVenta(context),
            icon: _isLoading ? Icons.hourglass_empty : Icons.save,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () => Navigator.of(context).pop(),
            icon: Icons.cancel,
          ),
        ),
      ],
    );
  }

  Future<void> _guardarCambiosVenta(BuildContext context) async {
    if (!_canEdit) {
      _showErrorSnackBar(context, 'Esta venta no puede ser editada');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Crear venta actualizada
      final ventaActualizada = Venta(
        id: widget.venta.id,
        cliente: widget.venta.cliente,
        telefono: widget.venta.telefono,
        email: widget.venta.email,
        estado: _estado,
        metodoPago: _metodoPago,
        total: widget.venta.total,
        fecha: widget.venta.fecha,
        items: widget.venta.items,
        notas: _notas.trim().isEmpty ? '' : _notas.trim(),
      );

      // Actualizar venta usando el servicio
      await _ventasEditService.updateVenta(ventaActualizada);

      if (mounted) {
        // Mostrar mensaje de éxito
        _showSuccessSnackBar(context, 'Venta actualizada exitosamente');
        
        // Cerrar modal y retornar resultado
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context, 'Error al actualizar venta: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
