import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/talla.dart';
import '../../../models/producto.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../dashboard/modern_card_widget.dart';

/// Modal moderno para gestión de tallas
class ModernGestionTallasModal extends StatefulWidget {
  final List<Talla> tallas;
  final List<Producto> productos;
  final InventarioLogicService logicService;
  final InventarioNavigationService navigationService;

  const ModernGestionTallasModal({
    super.key,
    required this.tallas,
    required this.productos,
    required this.logicService,
    required this.navigationService,
  });

  @override
  State<ModernGestionTallasModal> createState() => _ModernGestionTallasModalState();
}

class _ModernGestionTallasModalState extends State<ModernGestionTallasModal> {
  List<Talla> _tallas = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _tallas = List.from(widget.tallas);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
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
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenido
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF8B5CF6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.ruler,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Tallas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_tallas.length} tallas disponibles',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
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
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Botón agregar
          _buildAddButton(),
          
          const SizedBox(height: 24),
          
          // Lista de tallas
          Expanded(
            child: _buildTallasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _agregarTalla,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar Nueva Talla'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildTallasList() {
    if (_tallas.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _tallas.length,
      itemBuilder: (context, index) {
        final talla = _tallas[index];
        return _buildTallaCard(talla, index);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              FontAwesomeIcons.ruler,
              color: Color(0xFF8B5CF6),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay tallas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tallas para organizar tus productos por tamaño',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTallaCard(Talla talla, int index) {
    return ModernCardWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icono de talla
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.ruler,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Información de talla
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  talla.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getProductosCount(talla)} productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Orden
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Orden: ${talla.orden}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: () => _editarTalla(talla),
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                tooltip: 'Editar talla',
              ),
              IconButton(
                onPressed: () => _eliminarTalla(talla),
                icon: const Icon(
                  Icons.delete,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Eliminar talla',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getProductosCount(Talla talla) {
    return widget.productos.where((p) => p.talla == talla.nombre).length;
  }

  Future<void> _agregarTalla() async {
    // TODO: Implementar modal de formulario moderno
    widget.navigationService.showSuccessMessage(context, 'Funcionalidad de agregar talla en desarrollo');
  }

  Future<void> _editarTalla(Talla talla) async {
    // TODO: Implementar modal de formulario moderno
    widget.navigationService.showSuccessMessage(context, 'Funcionalidad de editar talla en desarrollo');
  }

  Future<void> _eliminarTalla(Talla talla) async {
    // Verificar si se puede eliminar
    final puedeEliminar = await widget.logicService.puedeEliminarTalla(
      talla.id ?? 0, 
      talla.nombre,
    );
    
    if (!puedeEliminar) {
      widget.navigationService.showErrorMessage(
        context, 
        'No se puede eliminar la talla "${talla.nombre}" porque tiene productos asociados',
      );
      return;
    }
    
    final confirmado = await widget.navigationService.showConfirmDelete(
      context, 
      talla.nombre,
    );
    
    if (confirmado) {
      setState(() {
        _cargando = true;
      });
      
      try {
        // Eliminar de la base de datos
        final eliminado = await widget.logicService.eliminarTalla(talla.id ?? 0);
        
        if (eliminado) {
          // Actualizar lista local
          setState(() {
            _tallas.removeWhere((t) => t.id == talla.id);
          });
          
          widget.navigationService.showSuccessMessage(
            context, 
            'Talla "${talla.nombre}" eliminada correctamente',
          );
        } else {
          widget.navigationService.showErrorMessage(
            context, 
            'Error al eliminar la talla',
          );
        }
      } catch (e) {
        widget.navigationService.showErrorMessage(
          context, 
          'Error al eliminar talla: $e',
        );
      } finally {
        setState(() {
          _cargando = false;
        });
      }
    }
  }
}
