import 'package:flutter/material.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import 'datos.dart';
import '../logging_service.dart';

class DashboardService extends ChangeNotifier {
  // Constructor que carga datos automáticamente
  DashboardService() {
    _initializeData();
  }

  final DatosService _datosService = DatosService();
  String? _error;
  // Estado de carga
  bool _isLoading = false;

  double _margenPromedio = 0.0;
  List<Producto> _productosRecientes = [];
  int _stockBajo = 0;
  int _totalClientes = 0;
  // Métricas del dashboard
  int _totalProductos = 0;

  int _totalVentas = 0;
  double _valorInventario = 0.0;
  double _ventasDelMes = 0.0;
  List<Venta> _ventasRecientes = [];
  List<Map<String, dynamic>> _ventasUltimos7Dias = [];

  // Getters
  int get totalProductos => _totalProductos;

  double get ventasDelMes => _ventasDelMes;

  double get margenPromedio => _margenPromedio;

  int get stockBajo => _stockBajo;

  int get totalClientes => _totalClientes;

  int get totalVentas => _totalVentas;

  double get valorInventario => _valorInventario;

  List<Producto> get productosRecientes => _productosRecientes;

  List<Venta> get ventasRecientes => _ventasRecientes;

  List<Map<String, dynamic>> get ventasUltimos7Dias => _ventasUltimos7Dias;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // Inicializar datos
  Future<void> cargarDatos() async {
    if (_isLoading) return; // Evitar cargas múltiples
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      LoggingService.business('Cargando datos del dashboard');
      
      // Cargar productos
      final productos = await _datosService.getProductos();
      _totalProductos = productos.length;
      LoggingService.debug('Productos cargados: $_totalProductos');
      
      // Calcular valor total del inventario
      _valorInventario = productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
      
      // Calcular margen promedio
      _margenPromedio = _calcularMargenPromedio(productos);
      
      // Contar productos con stock bajo
      _stockBajo = productos.where((p) => p.stock < 10).length;
      
      // Obtener productos recientes (últimos 5)
      final productosOrdenados = List<Producto>.from(productos);
      productosOrdenados.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      _productosRecientes = productosOrdenados.take(5).toList();
      
      // Cargar clientes
      final clientes = await _datosService.getClientes();
      _totalClientes = clientes.length;
      LoggingService.debug('Clientes cargados: $_totalClientes');
      
      // Cargar ventas
      final ventas = await _datosService.getVentas();
      _totalVentas = ventas.length;
      LoggingService.debug('Ventas cargadas: $_totalVentas');
      
      // Calcular ventas del mes (datos reales)
      _ventasDelMes = await _datosService.getTotalVentasDelMes();
      
      // Obtener ventas de los últimos 7 días (datos reales)
      _ventasUltimos7Dias = await _datosService.getVentasUltimos7Dias();
      
      // Obtener ventas recientes (últimas 5)
      final ventasOrdenadas = List<Venta>.from(ventas);
      ventasOrdenadas.sort((a, b) => b.fecha.compareTo(a.fecha));
      _ventasRecientes = ventasOrdenadas.take(5).toList();
      
      _isLoading = false;
      LoggingService.business('Datos del dashboard cargados exitosamente');
      notifyListeners();
    } catch (e, stackTrace) {
      _isLoading = false;
      _error = e.toString();
      LoggingService.error(
        'Error cargando datos del dashboard',
        tag: 'DASHBOARD',
        error: e,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  // Actualizar datos cuando se agrega un nuevo producto
  Future<void> actualizarDatos() async {
    await cargarDatos();
  }

  // Inicializar datos automáticamente
  Future<void> _initializeData() async {
    // Pequeño delay para asegurar que la app esté lista
    await Future.delayed(const Duration(milliseconds: 500));
    await cargarDatos();
  }

  // Método eliminado - ahora usamos datos reales de ventas

  double _calcularMargenPromedio(List<Producto> productos) {
    if (productos.isEmpty) return 0.0;
    
    double totalMargen = 0.0;
    for (var producto in productos) {
      double margen = ((producto.precioVenta - producto.costoTotal) / producto.precioVenta) * 100;
      totalMargen += margen;
    }
    return totalMargen / productos.length;
  }
}
