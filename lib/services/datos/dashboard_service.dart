import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import 'datos.dart';
import 'package:stockcito/services/system/logging_service.dart';

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

  // Getter para el monto total de todas las ventas
  Future<double> getTotalVentasMonto() async {
    try {
      final ventas = await _datosService.getVentas();
      double total = 0.0;
      for (var venta in ventas) {
        total += venta.total;
      }
      return total;
    } catch (e) {
      LoggingService.error('Error obteniendo monto total de ventas: $e');
      return 0.0;
    }
  }

  // Método para obtener actividades recientes
  Future<List<Map<String, dynamic>>> getActividadesRecientes({int limit = 5}) async {
    try {
      final ventas = await _datosService.getVentas();
      final productos = await _datosService.getProductos();
      final clientes = await _datosService.getClientes();
      
      List<Map<String, dynamic>> actividades = [];
      
      // Agregar ventas recientes
      final ventasOrdenadas = List<Venta>.from(ventas);
      ventasOrdenadas.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      for (var venta in ventasOrdenadas.take(limit)) {
        actividades.add({
          'tipo': 'venta',
          'descripcion': 'Nueva venta: ${venta.cliente} - \$${venta.total.toStringAsFixed(2)}',
          'fecha': _calcularTiempoRelativo(venta.fecha),
          'icono': FontAwesomeIcons.shoppingCart,
          'color': const Color(0xFF10B981),
        });
      }
      
      // Agregar productos recientes
      final productosOrdenados = List<Producto>.from(productos);
      productosOrdenados.sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
      
      for (var producto in productosOrdenados.take(limit ~/ 2)) {
        actividades.add({
          'tipo': 'producto',
          'descripcion': 'Producto agregado: ${producto.nombre}',
          'fecha': _calcularTiempoRelativo(producto.fechaCreacion),
          'icono': FontAwesomeIcons.box,
          'color': const Color(0xFF3B82F6),
        });
      }
      
      // Agregar clientes recientes
      final clientesOrdenados = List<Cliente>.from(clientes);
      clientesOrdenados.sort((a, b) => b.fechaRegistro.compareTo(a.fechaRegistro));
      
      for (var cliente in clientesOrdenados.take(limit ~/ 3)) {
        actividades.add({
          'tipo': 'cliente',
          'descripcion': 'Nuevo cliente: ${cliente.nombre}',
          'fecha': _calcularTiempoRelativo(cliente.fechaRegistro),
          'icono': FontAwesomeIcons.user,
          'color': const Color(0xFF8B5CF6),
        });
      }
      
      // Ordenar todas las actividades por fecha
      actividades.sort((a, b) {
        // Convertir fechas relativas a DateTime para ordenar
        final fechaA = _parsearFechaRelativa(a['fecha']);
        final fechaB = _parsearFechaRelativa(b['fecha']);
        return fechaB.compareTo(fechaA);
      });
      
      return actividades.take(limit).toList();
      
    } catch (e) {
      LoggingService.error('Error obteniendo actividades recientes: $e');
      return [];
    }
  }

  String _calcularTiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);
    
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    } else if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    } else if (diferencia.inDays < 7) {
      return 'Hace ${diferencia.inDays} días';
    } else {
      return 'Hace ${diferencia.inDays ~/ 7} semanas';
    }
  }

  DateTime _parsearFechaRelativa(String fechaRelativa) {
    final ahora = DateTime.now();
    
    if (fechaRelativa.contains('minutos')) {
      final minutos = int.tryParse(fechaRelativa.split(' ')[1]) ?? 0;
      return ahora.subtract(Duration(minutes: minutos));
    } else if (fechaRelativa.contains('horas')) {
      final horas = int.tryParse(fechaRelativa.split(' ')[1]) ?? 0;
      return ahora.subtract(Duration(hours: horas));
    } else if (fechaRelativa.contains('días')) {
      final dias = int.tryParse(fechaRelativa.split(' ')[1]) ?? 0;
      return ahora.subtract(Duration(days: dias));
    } else if (fechaRelativa.contains('semanas')) {
      final semanas = int.tryParse(fechaRelativa.split(' ')[1]) ?? 0;
      return ahora.subtract(Duration(days: semanas * 7));
    }
    
    return ahora;
  }

  // Método para obtener productos más vendidos
  Future<List<Map<String, dynamic>>> getProductosMasVendidos({int limit = 5}) async {
    try {
      final ventas = await _datosService.getVentas();
      final productos = await _datosService.getProductos();
      
      // Crear un mapa para contar las ventas por producto
      Map<int, int> ventasPorProducto = {};
      Map<int, double> totalVentasPorProducto = {};
      
      for (var venta in ventas) {
        for (var item in venta.items) {
          final productoId = item.productoId;
          ventasPorProducto[productoId] = (ventasPorProducto[productoId] ?? 0) + item.cantidad;
          totalVentasPorProducto[productoId] = (totalVentasPorProducto[productoId] ?? 0.0) + (item.precioUnitario * item.cantidad);
        }
      }
      
      // Crear lista de productos con sus ventas
      List<Map<String, dynamic>> productosConVentas = [];
      
      for (var producto in productos) {
        final cantidadVendida = ventasPorProducto[producto.id] ?? 0;
        final totalVentas = totalVentasPorProducto[producto.id] ?? 0.0;
        
        if (cantidadVendida > 0) {
          productosConVentas.add({
            'id': producto.id,
            'nombre': producto.nombre,
            'cantidadVendida': cantidadVendida,
            'totalVentas': totalVentas,
            'precio': producto.precioVenta,
            'stock': producto.stock,
          });
        }
      }
      
      // Ordenar por cantidad vendida (descendente)
      productosConVentas.sort((a, b) => b['cantidadVendida'].compareTo(a['cantidadVendida']));
      
      // Retornar solo el límite solicitado
      return productosConVentas.take(limit).toList();
      
    } catch (e) {
      LoggingService.error('Error obteniendo productos más vendidos: $e');
      return [];
    }
  }

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
