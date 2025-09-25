import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../services/ui/reportes/reportes_state_service.dart';
import '../../../services/ui/reportes/reportes_logic_service.dart';
import '../../../services/ui/reportes/reportes_navigation_service.dart';
import '../../../models/producto.dart';
import '../utility/lazy_list_widget.dart';
import 'reportes_stats_cards.dart';

/// Widget que contiene el contenido principal de la pantalla de reportes
class ReportesContentWidget extends StatelessWidget {
  const ReportesContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ReportesStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<ReportesLogicService>(context, listen: false);
        final navigationService = Provider.of<ReportesNavigationService>(context, listen: false);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas principales
              const ReportesStatsCards(),
              
              const SizedBox(height: 24),
              
              // Filtros simplificados
              _buildFiltrosSimplificados(context, stateService, logicService, navigationService),
              
              const SizedBox(height: 24),
              
              // Métricas simplificadas
              _buildMetricasSimplificadas(context, stateService),
              
              const SizedBox(height: 24),
              
              // Análisis por categoría simplificado
              _buildAnalisisSimplificado(context, logicService),
              
              const SizedBox(height: 24),
              
              // Lista de productos con lazy loading
              _buildProductosList(context, stateService, logicService, navigationService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductosList(
    BuildContext context,
    ReportesStateService stateService,
    ReportesLogicService logicService,
    ReportesNavigationService navigationService,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          // Header de la lista
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos (${logicService.getProductosFiltrados().length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
              ],
            ),
          ),
          
          // Lista lazy loading
          SizedBox(
            height: 400, // Altura fija para la lista
            child: LazyListWidget<Producto>(
              entityKey: 'productos-reportes',
              itemBuilder: (producto, index) => _buildProductoCard(
                context,
                producto,
                index,
                navigationService,
              ),
              dataLoader: (page, limit) => logicService.getProductosLazy(
                page: page,
                limit: limit,
                filters: stateService.getCurrentFilters(),
              ),
              emptyWidget: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    'No hay productos para mostrar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              loadingWidget: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(
    BuildContext context,
    Producto producto,
    int index,
    ReportesNavigationService navigationService,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
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
          onTap: () => navigationService.showProductoDetails(context, producto),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icono del producto
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.box,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto.nombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${producto.categoria} - ${producto.talla}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Stock y precio
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock: ${producto.stock}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: producto.stock < 10 ? const Color(0xFFEF4444) : const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${producto.precioVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Botón de acciones
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAction(context, value, producto, navigationService),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ver',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('Ver detalles'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    String action,
    Producto producto,
    ReportesNavigationService navigationService,
  ) {
    switch (action) {
      case 'ver':
        navigationService.showProductoDetails(context, producto);
        break;
      case 'editar':
        navigationService.showProductoEdit(context, producto);
        break;
    }
  }

  void _exportarPDF(
    BuildContext context,
    ReportesLogicService logicService,
    ReportesNavigationService navigationService,
  ) async {
    final exitoso = await logicService.exportarReporte('PDF');
    
    if (exitoso) {
      navigationService.showSuccessMessage(context, 'Reporte PDF exportado correctamente');
    } else {
      navigationService.showErrorMessage(context, 'Error al exportar reporte PDF');
    }
  }

  void _exportarExcel(
    BuildContext context,
    ReportesLogicService logicService,
    ReportesNavigationService navigationService,
  ) async {
    final exitoso = await logicService.exportarReporte('Excel');
    
    if (exitoso) {
      navigationService.showSuccessMessage(context, 'Reporte Excel exportado correctamente');
    } else {
      navigationService.showErrorMessage(context, 'Error al exportar reporte Excel');
    }
  }

  Widget _buildFiltrosSimplificados(
    BuildContext context,
    ReportesStateService stateService,
    ReportesLogicService logicService,
    ReportesNavigationService navigationService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportarPDF(context, logicService, navigationService),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Exportar PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportarExcel(context, logicService, navigationService),
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Exportar Excel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasSimplificadas(BuildContext context, ReportesStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Métricas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          if (stateService.metricasCompletas != null)
            Text(
              'Métricas completas disponibles: ${stateService.metricasCompletas!.keys.length} indicadores',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            )
          else
            const Text(
              'Cargando métricas...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalisisSimplificado(BuildContext context, ReportesLogicService logicService) {
    final productosPorCategoria = logicService.getProductosPorCategoria();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Análisis por Categoría',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          ...productosPorCategoria.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    '${entry.value} productos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }
}
