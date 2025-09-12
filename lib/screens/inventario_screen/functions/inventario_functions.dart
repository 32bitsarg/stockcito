import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../models/producto.dart';

class InventarioFunctions {
  /// Filtra los productos según los criterios especificados
  static List<Producto> filterProductos(
    List<Producto> productos, {
    String categoria = 'Todas',
    String talla = 'Todas',
    String busqueda = '',
    bool mostrarSoloStockBajo = false,
  }) {
    var productosFiltrados = productos;

    // Filtrar por categoría
    if (categoria != 'Todas') {
      productosFiltrados = productosFiltrados.where((p) => p.categoria == categoria).toList();
    }

    // Filtrar por talla
    if (talla != 'Todas') {
      productosFiltrados = productosFiltrados.where((p) => p.talla == talla).toList();
    }

    // Filtrar por búsqueda
    if (busqueda.isNotEmpty) {
      productosFiltrados = productosFiltrados.where((p) => 
        p.nombre.toLowerCase().contains(busqueda.toLowerCase()) ||
        p.categoria.toLowerCase().contains(busqueda.toLowerCase())
      ).toList();
    }

    // Filtrar por stock bajo
    if (mostrarSoloStockBajo) {
      productosFiltrados = productosFiltrados.where((p) => p.stock < 10).toList();
    }

    return productosFiltrados;
  }

  /// Calcula el total de productos
  static int calcularTotalProductos(List<Producto> productos) {
    return productos.length;
  }

  /// Calcula el número de productos con stock bajo
  static int calcularStockBajo(List<Producto> productos) {
    return productos.where((p) => p.stock < 10).length;
  }

  /// Calcula el valor total del inventario
  static double calcularValorTotal(List<Producto> productos) {
    return productos.fold(0.0, (sum, p) => sum + (p.precioVenta * p.stock));
  }

  /// Obtiene el color del stock
  static Color getStockColor(int stock) {
    if (stock < 5) {
      return const Color(0xFFF44336); // Rojo para stock muy bajo
    } else if (stock < 10) {
      return const Color(0xFFFF9800); // Naranja para stock bajo
    } else {
      return const Color(0xFF4CAF50); // Verde para stock normal
    }
  }

  /// Obtiene el icono del stock
  static IconData getStockIcon(int stock) {
    if (stock < 5) {
      return FontAwesomeIcons.exclamationTriangle;
    } else if (stock < 10) {
      return FontAwesomeIcons.exclamationCircle;
    } else {
      return FontAwesomeIcons.checkCircle;
    }
  }

  /// Formatea un precio para mostrar
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Formatea un número para mostrar
  static String formatNumero(int numero) {
    return numero.toString();
  }

  /// Valida si un producto puede ser editado
  static bool canEditProducto(Producto producto) {
    return true; // Todos los productos pueden ser editados
  }

  /// Valida si un producto puede ser eliminado
  static bool canDeleteProducto(Producto producto) {
    return true; // Todos los productos pueden ser eliminados
  }

  /// Obtiene el texto de categoría formateado
  static String getCategoriaText(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'bodies':
        return 'Bodies';
      case 'conjuntos':
        return 'Conjuntos';
      case 'vestidos':
        return 'Vestidos';
      case 'pijamas':
        return 'Pijamas';
      case 'gorros':
        return 'Gorros';
      case 'accesorios':
        return 'Accesorios';
      default:
        return categoria;
    }
  }

  /// Obtiene el texto de talla formateado
  static String getTallaText(String talla) {
    switch (talla.toLowerCase()) {
      case '0-3 meses':
        return '0-3 meses';
      case '3-6 meses':
        return '3-6 meses';
      case '6-12 meses':
        return '6-12 meses';
      case '12-18 meses':
        return '12-18 meses';
      case '18-24 meses':
        return '18-24 meses';
      default:
        return talla;
    }
  }

  /// Obtiene el color de la categoría
  static Color getCategoriaColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'bodies':
        return const Color(0xFFE91E63);
      case 'conjuntos':
        return const Color(0xFF9C27B0);
      case 'vestidos':
        return const Color(0xFF673AB7);
      case 'pijamas':
        return const Color(0xFF3F51B5);
      case 'gorros':
        return const Color(0xFF2196F3);
      case 'accesorios':
        return const Color(0xFF00BCD4);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
