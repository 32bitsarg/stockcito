import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../../models/producto.dart';

class NuevaVentaFunctions {
  /// Obtiene los métodos de pago disponibles
  static List<String> getMetodosPago() {
    return ['Efectivo', 'Tarjeta', 'Transferencia', 'Otro'];
  }

  /// Obtiene los estados disponibles
  static List<String> getEstados() {
    return ['Pendiente', 'Completada', 'Cancelada'];
  }

  /// Calcula el total de la venta
  static double calcularTotalVenta(List<VentaItem> itemsVenta) {
    return itemsVenta.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  /// Valida si hay stock disponible
  static bool tieneStockDisponible(Producto producto) {
    return producto.stock > 0;
  }

  /// Valida si se puede incrementar la cantidad
  static bool puedeIncrementarCantidad(VentaItem item, Producto producto) {
    return item.cantidad < producto.stock;
  }

  /// Valida si se puede decrementar la cantidad
  static bool puedeDecrementarCantidad(VentaItem item) {
    return item.cantidad > 1;
  }

  /// Busca un item existente en la venta
  static int buscarItemExistente(List<VentaItem> itemsVenta, int productoId) {
    return itemsVenta.indexWhere((item) => item.productoId == productoId);
  }

  /// Crea un nuevo item de venta
  static VentaItem crearItemVenta(Producto producto) {
    return VentaItem(
      ventaId: 0, // Se asignará al guardar
      productoId: producto.id!,
      nombreProducto: producto.nombre,
      categoria: producto.categoria,
      talla: producto.talla,
      cantidad: 1,
      precioUnitario: producto.precioVenta,
      subtotal: producto.precioVenta,
    );
  }

  /// Incrementa la cantidad de un item
  static VentaItem incrementarCantidadItem(VentaItem item) {
    return VentaItem(
      id: item.id,
      ventaId: item.ventaId,
      productoId: item.productoId,
      nombreProducto: item.nombreProducto,
      categoria: item.categoria,
      talla: item.talla,
      cantidad: item.cantidad + 1,
      precioUnitario: item.precioUnitario,
      subtotal: (item.cantidad + 1) * item.precioUnitario,
    );
  }

  /// Decrementa la cantidad de un item
  static VentaItem decrementarCantidadItem(VentaItem item) {
    return VentaItem(
      id: item.id,
      ventaId: item.ventaId,
      productoId: item.productoId,
      nombreProducto: item.nombreProducto,
      categoria: item.categoria,
      talla: item.talla,
      cantidad: item.cantidad - 1,
      precioUnitario: item.precioUnitario,
      subtotal: (item.cantidad - 1) * item.precioUnitario,
    );
  }

  /// Crea una venta completa
  static Venta crearVenta({
    required String cliente,
    required String telefono,
    required String email,
    required double total,
    required String metodoPago,
    required String estado,
    required String notas,
    required List<VentaItem> items,
  }) {
    return Venta(
      cliente: cliente.isNotEmpty ? cliente : 'Cliente no especificado',
      telefono: telefono,
      email: email,
      fecha: DateTime.now(),
      total: total,
      metodoPago: metodoPago,
      estado: estado,
      notas: notas,
      items: items,
    );
  }

  /// Formatea un precio
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Obtiene el texto de stock
  static String getStockText(int stock) {
    return 'Stock: $stock';
  }

  /// Obtiene el texto de cliente por defecto
  static String getClienteDefaultText() {
    return 'Cliente no especificado';
  }

  /// Obtiene el mensaje de error para stock insuficiente
  static String getStockInsuficienteText(String nombreProducto) {
    return 'No hay suficiente stock para $nombreProducto';
  }

  /// Obtiene el mensaje de error para stock no disponible
  static String getStockNoDisponibleText(String nombreProducto) {
    return 'No hay stock disponible para $nombreProducto';
  }

  /// Obtiene el mensaje de error para items vacíos
  static String getItemsVaciosText() {
    return 'Debe agregar al menos un producto a la venta';
  }

  /// Obtiene el mensaje de éxito para venta guardada
  static String getVentaGuardadaSuccessText() {
    return 'Venta guardada exitosamente';
  }

  /// Obtiene el mensaje de error para guardar venta
  static String getVentaGuardadaErrorText() {
    return 'Error al guardar la venta. Inténtalo de nuevo.';
  }

  /// Obtiene el mensaje de error para cargar datos
  static String getCargaDatosErrorText(String error) {
    return 'Error cargando datos: $error';
  }

  /// Muestra un SnackBar de advertencia
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
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

  /// Valida si el formulario está completo
  static bool validarFormulario(GlobalKey<FormState> formKey, List<VentaItem> itemsVenta) {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    
    if (itemsVenta.isEmpty) {
      return false;
    }
    
    return true;
  }

  /// Limpia los datos del cliente seleccionado
  static void limpiarDatosCliente({
    required TextEditingController clienteController,
    required TextEditingController telefonoController,
    required TextEditingController emailController,
    required TextEditingController direccionController,
  }) {
    clienteController.clear();
    telefonoController.clear();
    emailController.clear();
    direccionController.clear();
  }

  /// Carga los datos del cliente seleccionado
  static void cargarDatosCliente({
    required Cliente cliente,
    required TextEditingController clienteController,
    required TextEditingController telefonoController,
    required TextEditingController emailController,
    required TextEditingController direccionController,
  }) {
    clienteController.text = cliente.nombre;
    telefonoController.text = cliente.telefono;
    emailController.text = cliente.email;
    direccionController.text = cliente.direccion;
  }

  /// Obtiene el texto del dropdown de cliente
  static String getClienteDropdownText(Cliente cliente) {
    return '${cliente.nombre} - ${cliente.telefono}';
  }

  /// Obtiene el texto del item de venta
  static String getItemVentaText(VentaItem item) {
    return '${item.nombreProducto} (${item.categoria} - ${item.talla})';
  }

  /// Obtiene el texto del subtotal
  static String getSubtotalText(VentaItem item) {
    return '${item.cantidad} x ${formatPrecio(item.precioUnitario)} = ${formatPrecio(item.subtotal)}';
  }
}
