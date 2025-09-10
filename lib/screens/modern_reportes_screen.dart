import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../config/app_theme.dart';
import '../widgets/windows_button.dart';

class ModernReportesScreen extends StatefulWidget {
  const ModernReportesScreen({super.key});

  @override
  State<ModernReportesScreen> createState() => _ModernReportesScreenState();
}

class _ModernReportesScreenState extends State<ModernReportesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Producto> _productos = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';

  final List<String> _categorias = [
    'Todas',
    'Bodies',
    'Conjuntos',
    'Vestidos',
    'Pijamas',
    'Gorros',
    'Accesorios',
  ];

  final List<String> _tallas = [
    'Todas',
    '0-3 meses',
    '3-6 meses',
    '6-12 meses',
    '12-18 meses',
    '18-24 meses',
  ];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    final productos = await _databaseService.getAllProductos();
    setState(() {
      _productos = productos;
      _isLoading = false;
    });
  }

  List<Producto> get _productosFiltrados {
    var productos = _productos;

    if (_filtroCategoria != 'Todas') {
      productos = productos.where((p) => p.categoria == _filtroCategoria).toList();
    }

    if (_filtroTalla != 'Todas') {
      productos = productos.where((p) => p.talla == _filtroTalla).toList();
    }

    return productos;
  }

  Map<String, int> get _productosPorCategoria {
    Map<String, int> categorias = {};
    for (var producto in _productosFiltrados) {
      categorias[producto.categoria] = (categorias[producto.categoria] ?? 0) + 1;
    }
    return categorias;
  }

  Map<String, double> get _valorPorCategoria {
    Map<String, double> valores = {};
    for (var producto in _productosFiltrados) {
      valores[producto.categoria] = (valores[producto.categoria] ?? 0) + 
          (producto.precioVenta * producto.stock);
    }
    return valores;
  }

  double get _valorTotalInventario {
    return _productosFiltrados.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
  }

  int get _totalProductos {
    return _productosFiltrados.length;
  }

  int get _stockBajo {
    return _productosFiltrados.where((p) => p.stock < 10).length;
  }

  double get _margenPromedio {
    if (_productosFiltrados.isEmpty) return 0.0;
    double totalMargen = 0.0;
    for (var producto in _productosFiltrados) {
      totalMargen += ((producto.precioVenta - producto.costoTotal) / producto.precioVenta) * 100;
    }
    return totalMargen / _productosFiltrados.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estadísticas
                  _buildHeader(),
                  const SizedBox(height: 24),
                  // Filtros
                  _buildFiltros(),
                  const SizedBox(height: 24),
                  // Métricas principales
                  _buildMetricasPrincipales(),
                  const SizedBox(height: 24),
                  // Análisis por categoría
                  _buildAnalisisCategoria(),
                  const SizedBox(height: 24),
                  // Lista de productos
                  _buildListaProductos(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Reportes y Análisis',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Análisis detallado de tu inventario y rendimiento',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botón exportar PDF
          WindowsButton(
            text: 'Exportar PDF',
            type: ButtonType.primary,
            onPressed: _exportarPDF,
            icon: Icons.picture_as_pdf,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
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
                Icons.filter_list,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros de Reporte',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Filtro categoría
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroCategoria,
                  items: _categorias.map((categoria) {
                    return DropdownMenuItem(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroCategoria = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Categoría',
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
              ),
              const SizedBox(width: 16),
              // Filtro talla
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroTalla,
                  items: _tallas.map((talla) {
                    return DropdownMenuItem(
                      value: talla,
                      child: Text(talla),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _filtroTalla = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Talla',
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
              ),
              const SizedBox(width: 16),
              // Botón limpiar filtros
              WindowsButton(
                text: 'Limpiar',
                type: ButtonType.secondary,
                onPressed: () {
                  setState(() {
                    _filtroCategoria = 'Todas';
                    _filtroTalla = 'Todas';
                  });
                },
                icon: Icons.clear_all,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasPrincipales() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricaCard(
            'Total Productos',
            '$_totalProductos',
            Icons.inventory,
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            'Valor Inventario',
            '\$${_valorTotalInventario.toStringAsFixed(0)}',
            Icons.attach_money,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            'Stock Bajo',
            '$_stockBajo',
            Icons.warning,
            AppTheme.warningColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricaCard(
            'Margen Promedio',
            '${_margenPromedio.toStringAsFixed(1)}%',
            Icons.trending_up,
            AppTheme.accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard(String title, String value, IconData icon, Color color) {
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisCategoria() {
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
                Icons.pie_chart,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis por Categoría',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._productosPorCategoria.entries.map((entry) {
            final categoria = entry.key;
            final cantidad = entry.value;
            final valor = _valorPorCategoria[categoria] ?? 0.0;
            final porcentaje = _totalProductos > 0 ? (cantidad / _totalProductos * 100) : 0.0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getCategoriaColor(categoria).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getCategoriaColor(categoria),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoria,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$cantidad productos • \$${valor.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _getCategoriaColor(categoria),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildListaProductos() {
    final productos = _productosFiltrados;

    if (productos.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
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
          // Header de la tabla
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Productos en Reporte (${productos.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Lista de productos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: productos.length,
            itemBuilder: (context, index) {
              final producto = productos[index];
              return _buildProductoCard(producto);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductoCard(Producto producto) {
    final isStockBajo = producto.stock < 10;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isStockBajo ? AppTheme.warningColor.withOpacity(0.3) : AppTheme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono del producto
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getCategoriaColor(producto.categoria).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getCategoriaIcon(producto.categoria),
              color: _getCategoriaColor(producto.categoria),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildInfoChip(producto.categoria, Icons.category),
                    const SizedBox(width: 8),
                    _buildInfoChip(producto.talla, Icons.straighten),
                    if (isStockBajo) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip('Stock Bajo', Icons.warning, AppTheme.warningColor),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Precios y stock
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${producto.precioVenta.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 16,
                    color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${producto.stock} unidades',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isStockBajo ? AppTheme.warningColor : AppTheme.textSecondary,
                      fontWeight: isStockBajo ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, [Color? color]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (color ?? AppTheme.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color ?? AppTheme.primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color ?? AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
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
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay datos para mostrar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajusta los filtros o agrega productos para ver el reporte',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoriaColor(String categoria) {
    switch (categoria) {
      case 'Bodies':
        return AppTheme.primaryColor;
      case 'Conjuntos':
        return AppTheme.secondaryColor;
      case 'Vestidos':
        return AppTheme.accentColor;
      case 'Pijamas':
        return AppTheme.warningColor;
      case 'Gorros':
        return AppTheme.successColor;
      case 'Accesorios':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria) {
      case 'Bodies':
        return Icons.child_care;
      case 'Conjuntos':
        return Icons.checkroom;
      case 'Vestidos':
        return Icons.checkroom;
      case 'Pijamas':
        return Icons.nightlight;
      case 'Gorros':
        return Icons.face;
      case 'Accesorios':
        return Icons.star;
      default:
        return Icons.inventory;
    }
  }

  Future<void> _exportarPDF() async {
    try {
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Reporte de Inventario - Stockcito',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generado el: ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Resumen General',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Total de productos: $_totalProductos'),
                pw.Text('Valor total del inventario: \$${_valorTotalInventario.toStringAsFixed(2)}'),
                pw.Text('Productos con stock bajo: $_stockBajo'),
                pw.Text('Margen promedio: ${_margenPromedio.toStringAsFixed(1)}%'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Análisis por Categoría',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ..._productosPorCategoria.entries.map((entry) {
                  final categoria = entry.key;
                  final cantidad = entry.value;
                  final valor = _valorPorCategoria[categoria] ?? 0.0;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 5),
                    child: pw.Text('$categoria: $cantidad productos - \$${valor.toStringAsFixed(2)}'),
                  );
                }).toList(),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'reporte_inventario_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar PDF: $e'),
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
}
