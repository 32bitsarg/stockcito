import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../services/system/export_service.dart';
import '../../../services/datos/datos.dart';

class ReportesFunctions {
  /// Filtra productos por categoría y talla
  static List<Producto> filterProductos(
    List<Producto> productos,
    String filtroCategoria,
    String filtroTalla,
  ) {
    var productosFiltrados = productos;

    if (filtroCategoria != 'Todas') {
      productosFiltrados = productosFiltrados
          .where((p) => p.categoria == filtroCategoria)
          .toList();
    }

    if (filtroTalla != 'Todas') {
      productosFiltrados = productosFiltrados
          .where((p) => p.talla == filtroTalla)
          .toList();
    }

    return productosFiltrados;
  }

  /// Calcula productos por categoría
  static Map<String, int> getProductosPorCategoria(List<Producto> productos) {
    Map<String, int> categorias = {};
    for (var producto in productos) {
      categorias[producto.categoria] = (categorias[producto.categoria] ?? 0) + 1;
    }
    return categorias;
  }

  /// Calcula valor por categoría
  static Map<String, double> getValorPorCategoria(List<Producto> productos) {
    Map<String, double> valores = {};
    for (var producto in productos) {
      valores[producto.categoria] = (valores[producto.categoria] ?? 0) +
          (producto.precioVenta * producto.stock);
    }
    return valores;
  }

  /// Calcula valor total del inventario
  static double getValorTotalInventario(List<Producto> productos) {
    return productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
  }

  /// Calcula total de productos
  static int getTotalProductos(List<Producto> productos) {
    return productos.length;
  }

  /// Calcula productos con stock bajo
  static int getStockBajo(List<Producto> productos, {int limite = 10}) {
    return productos.where((p) => p.stock < limite).length;
  }

  /// Calcula margen promedio
  static double getMargenPromedio(List<Producto> productos) {
    if (productos.isEmpty) return 0.0;
    double totalMargen = 0.0;
    for (var producto in productos) {
      totalMargen += ((producto.precioVenta - producto.costoTotal) / producto.precioVenta) * 100;
    }
    return totalMargen / productos.length;
  }

  /// Obtiene el color para una categoría
  static Color getCategoriaColor(String categoria) {
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

  /// Obtiene el icono para una categoría
  static IconData getCategoriaIcon(String categoria) {
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

  /// Obtiene las categorías disponibles
  static List<String> getCategorias() {
    return [
      'Todas',
      'Bodies',
      'Conjuntos',
      'Vestidos',
      'Pijamas',
      'Gorros',
      'Accesorios',
    ];
  }

  /// Obtiene las tallas disponibles
  static List<String> getTallas() {
    return [
      'Todas',
      '0-3 meses',
      '3-6 meses',
      '6-12 meses',
      '12-18 meses',
      '18-24 meses',
    ];
  }

  /// Formatea un precio
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Formatea un número entero
  static String formatNumero(int numero) {
    return numero.toString();
  }

  /// Formatea un porcentaje
  static String formatPorcentaje(double porcentaje) {
    return '${porcentaje.toStringAsFixed(1)}%';
  }

  /// Verifica si un producto tiene stock bajo
  static bool isStockBajo(Producto producto, {int limite = 10}) {
    return producto.stock < limite;
  }

  /// Calcula el porcentaje de una categoría
  static double calcularPorcentajeCategoria(int cantidad, int total) {
    return total > 0 ? (cantidad / total * 100) : 0.0;
  }

  /// Exporta un reporte a PDF
  static Future<void> exportarPDF({
    required List<Producto> productos,
    required Map<String, int> productosPorCategoria,
    required Map<String, double> valorPorCategoria,
    required int totalProductos,
    required double valorTotalInventario,
    required int stockBajo,
    required double margenPromedio,
    required String nombreArchivo,
  }) async {
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
                pw.Text('Total de productos: $totalProductos'),
                pw.Text('Valor total del inventario: \$${valorTotalInventario.toStringAsFixed(2)}'),
                pw.Text('Productos con stock bajo: $stockBajo'),
                pw.Text('Margen promedio: ${margenPromedio.toStringAsFixed(1)}%'),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Análisis por Categoría',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...productosPorCategoria.entries.map((entry) {
                  final categoria = entry.key;
                  final cantidad = entry.value;
                  final valor = valorPorCategoria[categoria] ?? 0.0;
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
        name: nombreArchivo,
      );
    } catch (e) {
      throw Exception('Error al exportar PDF: $e');
    }
  }

  /// Obtiene color según el stock
  static Color getStockColor(int stock) {
    if (stock <= 0) return AppTheme.errorColor;
    if (stock <= 5) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  /// Obtiene icono según el stock
  static IconData getStockIcon(int stock) {
    if (stock <= 0) return Icons.error_outline;
    if (stock <= 5) return Icons.warning_outlined;
    return Icons.check_circle_outline;
  }

  /// Muestra un SnackBar de error
  static void showErrorSnackBar(BuildContext context, String message) {
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

  /// Exporta productos a CSV
  static Future<String> exportarProductosCSV(List<Producto> productos) async {
    final exportService = ExportService();
    return await exportService.exportProductosToCSV(productos);
  }

  /// Exporta reporte completo a JSON
  static Future<String> exportarReporteCompletoJSON({
    required List<Producto> productos,
    required Map<String, dynamic> metricas,
  }) async {
    try {
      final datosService = DatosService();
      
      // Cargar ventas y clientes para el reporte completo
      final ventas = await datosService.getVentas();
      final clientes = await datosService.getClientes();
      
      final exportService = ExportService();
      return await exportService.exportReporteCompletoToJSON(
        productos: productos,
        ventas: ventas,
        clientes: clientes,
        metricas: metricas,
      );
    } catch (e) {
      // Si hay error cargando ventas/clientes, exportar solo productos
      final exportService = ExportService();
      return await exportService.exportReporteCompletoToJSON(
        productos: productos,
        ventas: [],
        clientes: [],
        metricas: metricas,
      );
    }
  }

  /// Calcula métricas combinadas incluyendo ventas y clientes
  static Future<Map<String, dynamic>> calcularMetricasCompletas({
    required List<Producto> productos,
  }) async {
    try {
      final datosService = DatosService();
      final ventas = await datosService.getVentas();
      final clientes = await datosService.getClientes();
      
      // Métricas de productos
      final valorTotalInventario = getValorTotalInventario(productos);
      final totalProductos = productos.length;
      final productosStockBajo = productos.where((p) => p.stock <= 5).length;
      
      // Métricas de ventas
      final totalVentas = ventas.length;
      final valorTotalVentas = ventas.fold<double>(0, (sum, v) => sum + v.total);
      final ventasUltimos30Dias = ventas.where((v) => 
        DateTime.now().difference(v.fecha).inDays <= 30).length;
      
      // Métricas de clientes
      final totalClientes = clientes.length;
      final clientesActivos = clientes.where((c) => c.totalCompras > 0).length;
      
      // Métricas combinadas
      final rotacionInventario = totalVentas > 0 ? valorTotalVentas / valorTotalInventario : 0.0;
      final promedioVentaPorCliente = totalClientes > 0 ? valorTotalVentas / totalClientes : 0.0;
      
      return {
        'productos': {
          'total': totalProductos,
          'stock_bajo': productosStockBajo,
          'valor_inventario': valorTotalInventario,
        },
        'ventas': {
          'total': totalVentas,
          'valor_total': valorTotalVentas,
          'ultimos_30_dias': ventasUltimos30Dias,
        },
        'clientes': {
          'total': totalClientes,
          'activos': clientesActivos,
          'promedio_compra': promedioVentaPorCliente,
        },
        'metricas_combinadas': {
          'rotacion_inventario': rotacionInventario,
          'promedio_venta_cliente': promedioVentaPorCliente,
        },
        'fecha_generacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Si hay error, retornar métricas básicas solo de productos
      return {
        'productos': {
          'total': productos.length,
          'stock_bajo': productos.where((p) => p.stock <= 5).length,
          'valor_inventario': getValorTotalInventario(productos),
        },
        'ventas': {
          'total': 0,
          'valor_total': 0.0,
          'ultimos_30_dias': 0,
        },
        'clientes': {
          'total': 0,
          'activos': 0,
          'promedio_compra': 0.0,
        },
        'metricas_combinadas': {
          'rotacion_inventario': 0.0,
          'promedio_venta_cliente': 0.0,
        },
        'fecha_generacion': DateTime.now().toIso8601String(),
        'error': 'No se pudieron cargar ventas y clientes',
      };
    }
  }

  /// Muestra diálogo de exportación exitosa
  static void showExportSuccessDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportación Exitosa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El archivo se ha exportado correctamente:'),
            const SizedBox(height: 8),
            Text(
              filePath.split('/').last,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El archivo se encuentra en la carpeta de documentos de la aplicación.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
