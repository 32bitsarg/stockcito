import 'package:flutter/material.dart';
import '../../../models/venta.dart';

class VentasFunctions {
  /// Filtra las ventas según los criterios especificados
  static List<Venta> filterVentas(
    List<Venta> ventas, {
    String estado = 'Todas',
    String cliente = 'Todos',
    String metodoPago = 'Todos',
  }) {
    return ventas.where((venta) {
      bool matchesEstado = estado == 'Todas' || venta.estado == estado;
      bool matchesCliente = cliente == 'Todos' || venta.cliente == cliente;
      bool matchesMetodoPago = metodoPago == 'Todos' || venta.metodoPago == metodoPago;
      
      return matchesEstado && matchesCliente && matchesMetodoPago;
    }).toList();
  }

  /// Calcula el total de ventas
  static double calcularTotalVentas(List<Venta> ventas) {
    return ventas.fold(0.0, (sum, venta) => sum + venta.total);
  }

  /// Calcula el número total de ventas
  static int calcularNumeroVentas(List<Venta> ventas) {
    return ventas.length;
  }

  /// Calcula el promedio de ventas
  static double calcularPromedioVentas(List<Venta> ventas) {
    if (ventas.isEmpty) return 0.0;
    return calcularTotalVentas(ventas) / ventas.length;
  }

  /// Obtiene el color del estado de la venta
  static Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return const Color(0xFF4CAF50);
      case 'pendiente':
        return const Color(0xFFFF9800);
      case 'cancelada':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Obtiene el icono del estado de la venta
  static IconData getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return Icons.check_circle;
      case 'pendiente':
        return Icons.pending;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  /// Formatea una fecha para mostrar
  static String formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea un precio para mostrar
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Valida si una venta puede ser editada
  static bool canEditVenta(Venta venta) {
    return venta.estado != 'Cancelada';
  }

  /// Valida si una venta puede ser eliminada
  static bool canDeleteVenta(Venta venta) {
    return venta.estado != 'Completada';
  }

  /// Obtiene el texto de estado formateado
  static String getEstadoText(String estado) {
    switch (estado.toLowerCase()) {
      case 'completada':
        return 'Completada';
      case 'pendiente':
        return 'Pendiente';
      case 'cancelada':
        return 'Cancelada';
      default:
        return estado;
    }
  }

  /// Obtiene el texto del método de pago formateado
  static String getMetodoPagoText(String metodoPago) {
    switch (metodoPago.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'transferencia':
        return 'Transferencia';
      default:
        return metodoPago;
    }
  }
}
