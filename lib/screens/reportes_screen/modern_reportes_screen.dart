import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';

// Importar widgets refactorizados
import 'widgets/reportes_header.dart';
import 'widgets/reportes_filtros.dart';
import 'widgets/reportes_metricas.dart';
import 'widgets/reportes_analisis_categoria.dart';
import 'widgets/reportes_lista_productos.dart';

// Importar funciones
import 'functions/reportes_functions.dart';

class ModernReportesScreen extends StatefulWidget {
  const ModernReportesScreen({super.key});

  @override
  State<ModernReportesScreen> createState() => _ModernReportesScreenState();
}

class _ModernReportesScreenState extends State<ModernReportesScreen> {
  final DatosService _datosService = DatosService();
  List<Producto> _productos = [];
  bool _isLoading = true;
  String _filtroCategoria = 'Todas';
  String _filtroTalla = 'Todas';

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    final productos = await _datosService.getProductos();
    setState(() {
      _productos = productos;
      _isLoading = false;
    });
  }

  List<Producto> get _productosFiltrados {
    return ReportesFunctions.filterProductos(_productos, _filtroCategoria, _filtroTalla);
  }

  Map<String, int> get _productosPorCategoria {
    return ReportesFunctions.getProductosPorCategoria(_productosFiltrados);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  // Lista de productos
                  ReportesListaProductos(productos: _productosFiltrados),
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
