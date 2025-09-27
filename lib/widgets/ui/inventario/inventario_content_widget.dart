import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/inventario/inventario_state_service.dart';
import '../../../services/ui/inventario/inventario_navigation_service.dart';
import '../../../services/ui/inventario/inventario_logic_service.dart';
import '../../../services/ui/inventario/inventario_data_service.dart';
import '../../../models/talla.dart';
import '../utility/lazy_list_widget.dart';
import '../../../models/producto.dart';
import '../../../config/app_theme.dart';
import '../dashboard/modern_card_widget.dart';
import '../modals/size_form_modal.dart';
import '../../../screens/inventario_screen/widgets/inventario_filters_widget.dart';
import '../../../screens/inventario_screen/functions/inventario_functions.dart';
import 'inventario_provider.dart';
import 'inventario_stats_cards.dart';

/// Widget que maneja el contenido principal del inventario
class InventarioContentWidget extends StatelessWidget {
  const InventarioContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<InventarioStateService>(
      builder: (context, stateService, child) {
        final logicService = InventarioProvider.ofNotNull(context).logicService;
        final navigationService = InventarioProvider.ofNotNull(context).navigationService;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas
              const InventarioStatsCards(),
              
              const SizedBox(height: 24),
              
              // Filtros
              ModernCardWidget(
                padding: const EdgeInsets.all(20),
                child: InventarioFiltersWidget(
                  categorias: stateService.categorias.cast(),
                  tallas: stateService.tallas.cast(),
                  filtroCategoria: stateService.filtroCategoria,
                  filtroTalla: stateService.filtroTalla,
                  busqueda: stateService.busqueda,
                  mostrarSoloStockBajo: stateService.mostrarSoloStockBajo,
                  onCategoriaChanged: (categoria) => stateService.updateFiltroCategoria(categoria),
                  onTallaChanged: (talla) => stateService.updateFiltroTalla(talla),
                  onBusquedaChanged: (busqueda) => stateService.updateBusqueda(busqueda),
                  onStockBajoChanged: (mostrar) => stateService.updateMostrarSoloStockBajo(mostrar),
                  onGestionCategorias: () => _abrirGestionCategorias(context, navigationService, stateService),
                  onGestionTallas: () => _showSizeModal(context, stateService),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Lista de productos con lazy loading
              ModernCardWidget(
                padding: const EdgeInsets.all(16),
                child: LazyListWidget<Producto>(
                  entityKey: 'productos_inventario',
                  pageSize: 20,
                  dataLoader: (page, pageSize) => logicService.getProductosLazy(
                    page: page,
                    limit: pageSize,
                    filters: stateService.getCurrentFilters(),
                  ),
                  itemBuilder: (producto, index) => _buildProductoCard(context, producto, index, navigationService),
                  padding: const EdgeInsets.all(16),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  filters: stateService.getCurrentFilters(),
                  onRefresh: () => logicService.refreshData(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Construir tarjeta de producto
  Widget _buildProductoCard(BuildContext context, Producto producto, int index, InventarioNavigationService navigationService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => navigationService.navigateToEditProduct(context, producto),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono de categoría
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.tag,
                    color: InventarioFunctions.getCategoriaColor(producto.categoria),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del producto
                      Text(
                        producto.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Categoría y talla
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: InventarioFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              InventarioFunctions.getCategoriaText(producto.categoria),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: InventarioFunctions.getCategoriaColor(producto.categoria),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Talla: ${InventarioFunctions.getTallaText(producto.talla)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Precio y stock
                      Row(
                        children: [
                          Text(
                            InventarioFunctions.formatPrecio(producto.precioVenta),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: InventarioFunctions.getStockColor(producto.stock).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: InventarioFunctions.getStockColor(producto.stock).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  InventarioFunctions.getStockIcon(producto.stock),
                                  color: InventarioFunctions.getStockColor(producto.stock),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${producto.stock}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: InventarioFunctions.getStockColor(producto.stock),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
                      () => navigationService.navigateToEditProduct(context, producto),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.delete_outline,
                      AppTheme.errorColor,
                      () => _eliminarProducto(context, producto, navigationService),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construir botón de acción
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Abrir gestión de categorías
  void _abrirGestionCategorias(BuildContext context, InventarioNavigationService navigationService, InventarioStateService stateService) {
    final logicService = InventarioProvider.ofNotNull(context).logicService;
    
    navigationService.showGestionCategorias(
      context,
      categorias: stateService.categorias.cast(),
      productos: stateService.productos.cast(),
      onCategoriasChanged: (nuevasCategorias) {
        logicService.updateCategorias(nuevasCategorias);
      },
      logicService: logicService,
    );
  }

  /// Mostrar modal de gestión de tallas
  void _showSizeModal(BuildContext context, InventarioStateService stateService) {
    showDialog(
      context: context,
      builder: (context) => SizeFormModal(
        onSizeCreated: (talla) async {
          try {
            final logicService = InventarioProvider.ofNotNull(context).logicService;
            final dataService = InventarioProvider.ofNotNull(context).dataService;
            
            await dataService.createTalla(talla);
            await logicService.loadAllData();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Talla creada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al crear talla: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onSizeUpdated: (talla) async {
          try {
            final logicService = InventarioProvider.ofNotNull(context).logicService;
            final dataService = InventarioProvider.ofNotNull(context).dataService;
            
            await dataService.updateTalla(talla);
            await logicService.loadAllData();
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Talla actualizada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al actualizar talla: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Eliminar producto
  Future<void> _eliminarProducto(BuildContext context, Producto producto, InventarioNavigationService navigationService) async {
    final confirmado = await navigationService.showConfirmDelete(context, producto.nombre);
    
    if (confirmado) {
      final logicService = InventarioProvider.ofNotNull(context).logicService;
      final exito = await logicService.eliminarProducto(producto.id!);
      
      if (exito) {
        navigationService.showSuccessMessage(context, 'Producto eliminado exitosamente');
      } else {
        navigationService.showErrorMessage(context, 'Error eliminando producto');
      }
    }
  }
}
