import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/categoria.dart';
import '../../../models/producto.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../dashboard/modern_card_widget.dart';

/// Modal moderno para gestión de categorías
class ModernGestionCategoriasModal extends StatefulWidget {
  final List<Categoria> categorias;
  final List<Producto> productos;
  final InventarioLogicService logicService;
  final InventarioNavigationService navigationService;

  const ModernGestionCategoriasModal({
    super.key,
    required this.categorias,
    required this.productos,
    required this.logicService,
    required this.navigationService,
  });

  @override
  State<ModernGestionCategoriasModal> createState() => _ModernGestionCategoriasModalState();
}

class _ModernGestionCategoriasModalState extends State<ModernGestionCategoriasModal> {
  List<Categoria> _categorias = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _categorias = List.from(widget.categorias);
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
        color: Color(0xFF3B82F6),
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
              FontAwesomeIcons.tags,
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
                  'Gestión de Categorías',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_categorias.length} categorías disponibles',
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
          
          // Lista de categorías
          Expanded(
            child: _buildCategoriasList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _cargando ? null : _agregarCategoria,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar Nueva Categoría'),
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

  Widget _buildCategoriasList() {
    if (_categorias.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _categorias.length,
      itemBuilder: (context, index) {
        final categoria = _categorias[index];
        return _buildCategoriaCard(categoria, index);
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
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              FontAwesomeIcons.tags,
              color: Color(0xFF3B82F6),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay categorías',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primera categoría para organizar tus productos',
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

  Widget _buildCategoriaCard(Categoria categoria, int index) {
    return ModernCardWidget(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Icono de categoría
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(int.parse(categoria.color.replaceFirst('#', '0xff'))),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.tag,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Información de categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoria.nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_getProductosCount(categoria)} productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Botones de acción
          Row(
            children: [
              IconButton(
                onPressed: () => _editarCategoria(categoria),
                icon: const Icon(
                  Icons.edit,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
                tooltip: 'Editar categoría',
              ),
              IconButton(
                onPressed: () => _eliminarCategoria(categoria),
                icon: const Icon(
                  Icons.delete,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
                tooltip: 'Eliminar categoría',
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getProductosCount(Categoria categoria) {
    return widget.productos.where((p) => p.categoria == categoria.nombre).length;
  }

  Future<void> _agregarCategoria() async {
    // TODO: Implementar modal de formulario moderno
    widget.navigationService.showSuccessMessage(context, 'Funcionalidad de agregar categoría en desarrollo');
  }

  Future<void> _editarCategoria(Categoria categoria) async {
    // TODO: Implementar modal de formulario moderno
    widget.navigationService.showSuccessMessage(context, 'Funcionalidad de editar categoría en desarrollo');
  }

  Future<void> _eliminarCategoria(Categoria categoria) async {
    // Verificar si se puede eliminar
    final puedeEliminar = await widget.logicService.puedeEliminarCategoria(
      categoria.id ?? 0, 
      categoria.nombre,
    );
    
    if (!puedeEliminar) {
      widget.navigationService.showErrorMessage(
        context, 
        'No se puede eliminar la categoría "${categoria.nombre}" porque tiene productos asociados',
      );
      return;
    }
    
    final confirmado = await widget.navigationService.showConfirmDelete(
      context, 
      categoria.nombre,
    );
    
    if (confirmado) {
      setState(() {
        _cargando = true;
      });
      
      try {
        // Eliminar de la base de datos
        final eliminado = await widget.logicService.eliminarCategoria(categoria.id ?? 0);
        
        if (eliminado) {
          // Actualizar lista local
          setState(() {
            _categorias.removeWhere((c) => c.id == categoria.id);
          });
          
          widget.navigationService.showSuccessMessage(
            context, 
            'Categoría "${categoria.nombre}" eliminada correctamente',
          );
        } else {
          widget.navigationService.showErrorMessage(
            context, 
            'Error al eliminar la categoría',
          );
        }
      } catch (e) {
        widget.navigationService.showErrorMessage(
          context, 
          'Error al eliminar categoría: $e',
        );
      } finally {
        setState(() {
          _cargando = false;
        });
      }
    }
  }
}
