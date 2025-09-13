import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../models/cliente.dart';

class ClientesFunctions {
  /// Filtra clientes por búsqueda
  static List<Cliente> filterClientes(List<Cliente> clientes, String filtroBusqueda) {
    if (filtroBusqueda.isEmpty) return clientes;
    
    return clientes.where((cliente) {
      return cliente.nombre.toLowerCase().contains(filtroBusqueda.toLowerCase()) ||
             cliente.telefono.contains(filtroBusqueda) ||
             cliente.email.toLowerCase().contains(filtroBusqueda.toLowerCase());
    }).toList();
  }

  /// Valida el formulario de cliente
  static String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    return null;
  }

  /// Valida el teléfono
  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El teléfono es requerido';
    }
    return null;
  }

  /// Valida el email
  static String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Ingresa un email válido';
      }
    }
    return null;
  }

  /// Formatea un precio
  static String formatPrecio(double precio) {
    return '\$${precio.toStringAsFixed(2)}';
  }

  /// Formatea un número entero
  static String formatNumero(int numero) {
    return numero.toString();
  }

  /// Obtiene el texto de compras
  static String getComprasText(int totalCompras) {
    return '$totalCompras compras';
  }

  /// Obtiene el texto de gasto total
  static String getGastoTotalText(double totalGastado) {
    return '\$${totalGastado.toStringAsFixed(0)}';
  }

  /// Verifica si un cliente tiene email
  static bool hasEmail(Cliente cliente) {
    return cliente.email.isNotEmpty;
  }

  /// Obtiene el texto de confirmación de eliminación
  static String getEliminacionText(String nombreCliente) {
    return '¿Estás seguro de que quieres eliminar a $nombreCliente?';
  }

  /// Obtiene el mensaje de éxito para crear cliente
  static String getCreacionSuccessText() {
    return 'Cliente creado exitosamente';
  }

  /// Obtiene el mensaje de éxito para actualizar cliente
  static String getActualizacionSuccessText() {
    return 'Cliente actualizado exitosamente';
  }

  /// Obtiene el mensaje de éxito para eliminar cliente
  static String getEliminacionSuccessText(String nombreCliente) {
    return 'Cliente $nombreCliente eliminado exitosamente';
  }

  /// Obtiene el mensaje de error para cargar clientes
  static String getCargaErrorText(String error) {
    return 'Error cargando clientes: $error';
  }

  /// Obtiene el mensaje de error para guardar cliente
  static String getGuardadoErrorText(String error) {
    return 'Error al guardar cliente: $error';
  }

  /// Obtiene el mensaje de error para eliminar cliente
  static String getEliminacionErrorText(String error) {
    return 'Error al eliminar cliente: $error';
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

  /// Crea un nuevo cliente
  static Cliente createCliente({
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) {
    return Cliente(
      nombre: nombre,
      telefono: telefono,
      email: email,
      direccion: direccion,
      fechaRegistro: DateTime.now(),
      notas: notas,
    );
  }

  /// Actualiza un cliente existente
  static Cliente updateCliente({
    required Cliente cliente,
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) {
    return cliente.copyWith(
      nombre: nombre,
      telefono: telefono,
      email: email,
      direccion: direccion,
      notas: notas,
    );
  }

  /// Obtiene el título del formulario
  static String getFormularioTitulo(bool isEditing) {
    return isEditing ? 'Editar Cliente' : 'Nuevo Cliente';
  }

  /// Obtiene la descripción del formulario
  static String getFormularioDescripcion(bool isEditing) {
    return isEditing ? 'Modifica los datos del cliente' : 'Agrega un nuevo cliente a tu base de datos';
  }

  /// Obtiene el texto del botón guardar
  static String getBotonGuardarText(bool isEditing) {
    return isEditing ? 'Actualizar' : 'Guardar';
  }

  /// Obtiene el icono del botón guardar
  static IconData getBotonGuardarIcon(bool isEditing) {
    return isEditing ? Icons.update : Icons.save;
  }

  /// Obtiene el icono del formulario
  static IconData getFormularioIcon(bool isEditing) {
    return isEditing ? Icons.edit : Icons.person_add;
  }
}
