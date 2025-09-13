import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';

class EditarProductoFunctions {
  /// Obtiene las categorías disponibles
  static List<String> getCategorias() {
    return [
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
      '0-3 meses',
      '3-6 meses',
      '6-12 meses',
      '12-18 meses',
      '18-24 meses',
    ];
  }

  /// Calcula el costo total
  static double calcularCostoTotal({
    required double materiales,
    required double manoObra,
    required double gastosGenerales,
  }) {
    return materiales + manoObra + gastosGenerales;
  }

  /// Calcula el precio de venta
  static double calcularPrecioVenta({
    required double costoTotal,
    required double margenGanancia,
  }) {
    return costoTotal * (1 + margenGanancia / 100);
  }

  /// Calcula el precio con IVA
  static double calcularPrecioConIVA({
    required double precioVenta,
    required double iva,
  }) {
    return precioVenta * (1 + iva / 100);
  }

  /// Calcula la ganancia neta
  static double calcularGananciaNeta({
    required double precioVenta,
    required double costoTotal,
  }) {
    return precioVenta - costoTotal;
  }

  /// Calcula el porcentaje de margen
  static double calcularPorcentajeMargen({
    required double gananciaNeta,
    required double costoTotal,
  }) {
    if (costoTotal == 0) return 0;
    return (gananciaNeta / costoTotal * 100);
  }

  /// Valida el nombre del producto
  static String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el nombre del producto';
    }
    return null;
  }

  /// Valida un campo numérico
  static String? validateNumero(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return 'Ingresa $campo';
    }
    if (double.tryParse(value) == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }

  /// Valida el stock
  static String? validateStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa el stock';
    }
    if (int.tryParse(value) == null) {
      return 'Ingresa un número válido';
    }
    return null;
  }

  /// Formatea un precio
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Formatea un porcentaje
  static String formatPorcentaje(double porcentaje) {
    return '${porcentaje.toStringAsFixed(1)}% de margen';
  }

  /// Obtiene el texto del slider de IVA
  static String getIVAText(double iva) {
    return 'IVA: ${iva.toStringAsFixed(0)}%';
  }

  /// Obtiene el mensaje de éxito para actualizar
  static String getActualizacionSuccessText() {
    return 'Producto actualizado exitosamente';
  }

  /// Obtiene el mensaje de error para actualizar
  static String getActualizacionErrorText(String error) {
    return 'Error al actualizar: $error';
  }

  /// Muestra un SnackBar de éxito
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  /// Carga los datos del producto en los controladores
  static void cargarDatosProducto({
    required Producto producto,
    required TextEditingController nombreController,
    required TextEditingController costoMaterialesController,
    required TextEditingController costoManoObraController,
    required TextEditingController gastosGeneralesController,
    required TextEditingController margenGananciaController,
    required TextEditingController stockController,
    required Function(String) onCategoriaChanged,
    required Function(String) onTallaChanged,
  }) {
    nombreController.text = producto.nombre;
    costoMaterialesController.text = producto.costoMateriales.toString();
    costoManoObraController.text = producto.costoManoObra.toString();
    gastosGeneralesController.text = producto.gastosGenerales.toString();
    margenGananciaController.text = producto.margenGanancia.toString();
    stockController.text = producto.stock.toString();
    onCategoriaChanged(producto.categoria);
    onTallaChanged(producto.talla);
  }

  /// Crea un producto actualizado
  static Producto crearProductoActualizado({
    required Producto productoOriginal,
    required String nombre,
    required String categoria,
    required String talla,
    required double costoMateriales,
    required double costoManoObra,
    required double gastosGenerales,
    required double margenGanancia,
    required int stock,
  }) {
    return Producto(
      id: productoOriginal.id,
      nombre: nombre,
      categoria: categoria,
      talla: talla,
      costoMateriales: costoMateriales,
      costoManoObra: costoManoObra,
      gastosGenerales: gastosGenerales,
      margenGanancia: margenGanancia,
      stock: stock,
      fechaCreacion: productoOriginal.fechaCreacion, // Mantener fecha original
    );
  }
}
