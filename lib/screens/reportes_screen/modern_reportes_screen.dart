import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../widgets/lazy_list_widget.dart';

// Importar widgets refactorizados
import 'widgets/reportes_header.dart';
import 'widgets/reportes_filtros.dart';
import 'widgets/reportes_metricas.dart';
import 'widgets/reportes_analisis_categoria.dart';

// Importar funciones
import 'functions/reportes_functions.dart';

class ModernReportesScreen extends StatefulWidget {
  const ModernReportesScreen({super.key});

  @override
  State<ModernReportesScreen> createState() => _ModernReportesScreenState();
}

class _ModernReportesScreenState extends State<ModernReportesScreen> {
  final DatosService _datosService = DatosService();
  List<Producto> _productos = []; // Mantenido para métricas
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      // Cargar solo datos necesarios para métricas
      final productos = await _datosService.getProductos();
      setState(() {
        _productos = productos;
      });
    } catch (e) {
      print('Error cargando productos para reportes: $e');
    }
  }

  List<Producto> get _productosFiltrados {
    return ReportesFunctions.filterProductos(_productos, _filtroCategoria, _filtroTalla);
  }

  Map<String, int> get _productosPorCategoria {
    return ReportesFunctions.getProductosPorCategoria(_productosFiltrados);
  }

  /// Obtiene los filtros actuales para el lazy loading
  Map<String, dynamic> _getCurrentFilters() {
    return {
      'categoria': _filtroCategoria,
      'talla': _filtroTalla,
    };
  }

  /// Construye la tarjeta de producto para el lazy loading
  Widget _buildProductoCard(Producto producto, int index) {
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
          onTap: () => _verDetalleProducto(producto),
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
                    color: ReportesFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ReportesFunctions.getCategoriaColor(producto.categoria).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.tag,
                    color: ReportesFunctions.getCategoriaColor(producto.categoria),
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
                              color: ReportesFunctions.getCategoriaColor(producto.categoria).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              producto.categoria,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: ReportesFunctions.getCategoriaColor(producto.categoria),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Talla: ${producto.talla}',
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
                            ReportesFunctions.formatPrecio(producto.precioVenta),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ReportesFunctions.getStockColor(producto.stock).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ReportesFunctions.getStockColor(producto.stock).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ReportesFunctions.getStockIcon(producto.stock),
                                  color: ReportesFunctions.getStockColor(producto.stock),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${producto.stock}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: ReportesFunctions.getStockColor(producto.stock),
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
                      Icons.visibility_outlined,
                      AppTheme.infoColor,
                      () => _verDetalleProducto(producto),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      Icons.edit_outlined,
                      AppTheme.primaryColor,
                      () => _editarProducto(producto),
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

  /// Construye botón de acción
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

  void _verDetalleProducto(Producto producto) {
    // TODO: Implementar vista de detalle de producto
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver detalle de: ${producto.nombre}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editarProducto(Producto producto) {
    // TODO: Implementar edición de producto desde reportes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editar: ${producto.nombre}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Map<String, double> get _valorPorCategoria {
    return ReportesFunctions.getValorPorCategoria(_productosFiltrados);
  }

  double get _valorTotalInventario {
    return ReportesFunctions.getValorTotalInventario(_productosFiltrados);
  }

  int get _totalProductos {
    return ReportesFunctions.getTotalProductos(_productosFiltrados);
  }

  int get _stockBajo {
    return ReportesFunctions.getStockBajo(_productosFiltrados);
  }

  double get _margenPromedio {
    return ReportesFunctions.getMargenPromedio(_productosFiltrados);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estadísticas
            ReportesHeader(onExportarPDF: _exportarPDF),
            const SizedBox(height: 24),
            // Filtros
            ReportesFiltros(
              filtroCategoria: _filtroCategoria,
              filtroTalla: _filtroTalla,
              onCategoriaChanged: (categoria) => setState(() => _filtroCategoria = categoria),
              onTallaChanged: (talla) => setState(() => _filtroTalla = talla),
              onLimpiarFiltros: () {
                setState(() {
                  _filtroCategoria = 'Todas';
                  _filtroTalla = 'Todas';
                });
              },
            ),
            const SizedBox(height: 24),
            // Métricas principales
            ReportesMetricas(
              totalProductos: _totalProductos,
              valorTotalInventario: _valorTotalInventario,
              stockBajo: _stockBajo,
              margenPromedio: _margenPromedio,
            ),
            const SizedBox(height: 24),
            // Análisis por categoría
            ReportesAnalisisCategoria(
              productosPorCategoria: _productosPorCategoria,
              valorPorCategoria: _valorPorCategoria,
              totalProductos: _totalProductos,
            ),
            const SizedBox(height: 24),
            // Lista de productos con lazy loading
            Container(
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
              child: LazyListWidget<Producto>(
                entityKey: 'productos_reportes',
                pageSize: 20,
                dataLoader: (page, pageSize) => _datosService.getProductosLazy(
                  page: page,
                  limit: pageSize,
                  filters: _getCurrentFilters(),
                ),
                itemBuilder: (producto, index) => _buildProductoCard(producto, index),
                padding: const EdgeInsets.all(16),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                filters: _getCurrentFilters(),
                onRefresh: () {
                  // Recargar datos de métricas
                  _loadProductos();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarPDF() async {
    try {
      await ReportesFunctions.exportarPDF(
        productos: _productosFiltrados,
        productosPorCategoria: _productosPorCategoria,
        valorPorCategoria: _valorPorCategoria,
        totalProductos: _totalProductos,
        valorTotalInventario: _valorTotalInventario,
        stockBajo: _stockBajo,
        margenPromedio: _margenPromedio,
        nombreArchivo: 'reporte_inventario_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ReportesFunctions.showErrorSnackBar(context, e.toString());
      }
    }
  }
}
