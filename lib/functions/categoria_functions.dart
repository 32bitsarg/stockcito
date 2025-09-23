import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/producto.dart';

class CategoriaFunctions {
  /// Valida si una categoría puede ser eliminada
  static Future<bool> canDeleteCategoria(Categoria categoria, List<Producto> productos) async {
    // No permitir eliminar categorías por defecto
    if (categoria.isDefault) {
      return false;
    }

    // Verificar si hay productos con esta categoría
    final productosConCategoria = productos.where((p) => p.categoria == categoria.nombre).toList();
    
    return productosConCategoria.isEmpty;
  }

  /// Obtiene la lista de productos que usan una categoría
  static List<Producto> getProductosConCategoria(Categoria categoria, List<Producto> productos) {
    return productos.where((p) => p.categoria == categoria.nombre).toList();
  }

  /// Valida los datos de una categoría
  static String? validateCategoria({
    required String nombre,
    required String color,
    required String icono,
    List<Categoria>? categoriasExistentes,
    Categoria? categoriaActual,
  }) {
    // Validar nombre único
    if (categoriasExistentes != null) {
      final existe = categoriasExistentes.any((c) => 
        c.nombre.toLowerCase() == nombre.toLowerCase() && 
        c.id != categoriaActual?.id
      );
      if (existe) return 'Ya existe una categoría con este nombre';
    }

    // Validar longitud del nombre
    if (nombre.length < 2) return 'El nombre debe tener al menos 2 caracteres';
    if (nombre.length > 50) return 'El nombre no puede exceder 50 caracteres';

    // Validar color
    if (!_isValidHexColor(color)) return 'El color debe ser un código hexadecimal válido';

    // Validar icono
    if (icono.isEmpty) return 'Debe seleccionar un icono';

    return null;
  }

  /// Valida si un color hexadecimal es válido
  static bool _isValidHexColor(String color) {
    final hexColorRegex = RegExp(r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$');
    return hexColorRegex.hasMatch(color);
  }

  /// Obtiene el color de una categoría
  static Color getCategoriaColor(String categoria, List<Categoria> categorias) {
    final categoriaObj = categorias.firstWhere(
      (c) => c.nombre == categoria,
      orElse: () => Categoria(
        nombre: categoria,
        color: '#9E9E9E',
        icono: 'tag',
        fechaCreacion: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    return Color(int.parse(categoriaObj.color.replaceFirst('#', '0xFF')));
  }

  /// Obtiene el icono de una categoría
  static String getCategoriaIcon(String categoria, List<Categoria> categorias) {
    final categoriaObj = categorias.firstWhere(
      (c) => c.nombre == categoria,
      orElse: () => Categoria(
        nombre: categoria,
        color: '#9E9E9E',
        icono: 'tag',
        fechaCreacion: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    return categoriaObj.icono;
  }

  /// Obtiene el texto formateado de una categoría
  static String getCategoriaText(String categoria) {
    return categoria;
  }

  /// Obtiene la descripción de una categoría
  static String getCategoriaDescripcion(String categoria, List<Categoria> categorias) {
    final categoriaObj = categorias.firstWhere(
      (c) => c.nombre == categoria,
      orElse: () => Categoria(
        nombre: categoria,
        color: '#9E9E9E',
        icono: 'tag',
        descripcion: '',
        fechaCreacion: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    
    return categoriaObj.descripcion ?? '';
  }

  /// Obtiene el mensaje de error para categorías que no se pueden eliminar
  static String getCategoriaNoEliminableMessage(Categoria categoria, List<Producto> productos) {
    if (categoria.isDefault) {
      return 'No se puede eliminar una categoría por defecto';
    }

    final productosConCategoria = getProductosConCategoria(categoria, productos);
    if (productosConCategoria.isNotEmpty) {
      final nombresProductos = productosConCategoria.map((p) => p.nombre).join(', ');
      return 'No se puede eliminar esta categoría porque está siendo usada por los siguientes productos: $nombresProductos';
    }

    return 'No se puede eliminar esta categoría';
  }

  /// Obtiene la lista de colores predefinidos
  static List<Color> getColoresPredefinidos() {
    return [
      const Color(0xFFE91E63), // Rosa
      const Color(0xFF9C27B0), // Púrpura
      const Color(0xFF673AB7), // Violeta
      const Color(0xFF3F51B5), // Índigo
      const Color(0xFF2196F3), // Azul
      const Color(0xFF00BCD4), // Cian
      const Color(0xFF4CAF50), // Verde
      const Color(0xFF8BC34A), // Verde claro
      const Color(0xFFFFC107), // Ámbar
      const Color(0xFFFF9800), // Naranja
      const Color(0xFFFF5722), // Rojo profundo
      const Color(0xFF795548), // Marrón
      const Color(0xFF9E9E9E), // Gris
      const Color(0xFF607D8B), // Azul gris
      const Color(0xFF000000), // Negro
    ];
  }

  /// Obtiene la lista de iconos predefinidos
  static List<String> getIconosPredefinidos() {
    return [
      'tag',
      'baby',
      'tshirt',
      'dress',
      'moon',
      'hat-cowboy',
      'gift',
      'shopping-bag',
      'star',
      'heart',
      'bookmark',
      'flag',
      'home',
      'user',
      'cog',
      'bell',
      'search',
      'plus',
      'minus',
      'edit',
      'trash',
      'save',
      'download',
      'upload',
      'share',
      'link',
      'image',
      'video',
      'music',
      'camera',
    ];
  }

  /// Convierte un color a string hexadecimal
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Convierte un string hexadecimal a color
  static Color hexToColor(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  /// Obtiene el mensaje de éxito para operaciones de categorías
  static String getSuccessMessage(String operacion, String nombreCategoria) {
    switch (operacion.toLowerCase()) {
      case 'crear':
        return 'Categoría "$nombreCategoria" creada exitosamente';
      case 'editar':
        return 'Categoría "$nombreCategoria" actualizada exitosamente';
      case 'eliminar':
        return 'Categoría "$nombreCategoria" eliminada exitosamente';
      default:
        return 'Operación completada exitosamente';
    }
  }

  /// Obtiene el mensaje de error para operaciones de categorías
  static String getErrorMessage(String operacion, String error) {
    switch (operacion.toLowerCase()) {
      case 'crear':
        return 'Error creando categoría: $error';
      case 'editar':
        return 'Error actualizando categoría: $error';
      case 'eliminar':
        return 'Error eliminando categoría: $error';
      default:
        return 'Error: $error';
    }
  }
}

