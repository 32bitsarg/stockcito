/// Modelo para el producto en la calculadora
class ProductoCalculo {
  final String nombre;
  final String descripcion;
  final String categoria;
  final String talla;
  final int stock;
  final double? precioVenta; // Solo para modo simple
  final String tipoNegocio;
  final DateTime fechaCreacion;

  const ProductoCalculo({
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.talla,
    required this.stock,
    this.precioVenta,
    required this.tipoNegocio,
    required this.fechaCreacion,
  });

  /// Producto vacío
  factory ProductoCalculo.empty() {
    return ProductoCalculo(
      nombre: '',
      descripcion: '',
      categoria: '',
      talla: '',
      stock: 1,
      tipoNegocio: 'textil',
      fechaCreacion: DateTime.now(),
    );
  }

  /// Crea una copia con nuevos valores
  ProductoCalculo copyWith({
    String? nombre,
    String? descripcion,
    String? categoria,
    String? talla,
    int? stock,
    double? precioVenta,
    String? tipoNegocio,
    DateTime? fechaCreacion,
  }) {
    return ProductoCalculo(
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      categoria: categoria ?? this.categoria,
      talla: talla ?? this.talla,
      stock: stock ?? this.stock,
      precioVenta: precioVenta ?? this.precioVenta,
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'categoria': categoria,
      'talla': talla,
      'stock': stock,
      'precioVenta': precioVenta,
      'tipoNegocio': tipoNegocio,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory ProductoCalculo.fromMap(Map<String, dynamic> map) {
    return ProductoCalculo(
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      categoria: map['categoria'] ?? '',
      talla: map['talla'] ?? '',
      stock: map['stock'] ?? 1,
      precioVenta: map['precioVenta']?.toDouble(),
      tipoNegocio: map['tipoNegocio'] ?? 'textil',
      fechaCreacion: DateTime.parse(map['fechaCreacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Valida si el producto está completo
  bool get isValid {
    return nombre.isNotEmpty && 
           categoria.isNotEmpty && 
           talla.isNotEmpty &&
           stock > 0;
  }

  /// Valida si el producto está completo para modo simple
  bool get isValidSimple {
    return isValid && precioVenta != null && precioVenta! > 0;
  }

  /// Obtiene las categorías disponibles por tipo de negocio
  /// NOTA: Este método estático se mantiene para compatibilidad,
  /// pero ahora se recomienda usar las categorías dinámicas del servicio
  static List<String> getCategoriasPorTipo(String tipoNegocio) {
    switch (tipoNegocio) {
      case 'textil':
        return [
          'Bodies',
          'Conjuntos',
          'Vestidos',
          'Pijamas',
          'Gorros',
          'Accesorios',
          'Ropa Interior',
          'Ropa de Cama',
        ];
      case 'almacen':
        return [
          'Alimentos',
          'Bebidas',
          'Limpieza',
          'Higiene',
          'Electrodomésticos',
          'Ropa',
          'Calzado',
          'Otros',
        ];
      case 'manufactura':
        return [
          'Muebles',
          'Decoración',
          'Herramientas',
          'Artesanías',
          'Electrónicos',
          'Automotriz',
          'Otros',
        ];
      case 'servicio':
        return [
          'Consultoría',
          'Diseño',
          'Desarrollo',
          'Marketing',
          'Contabilidad',
          'Legal',
          'Otros',
        ];
      default:
        return ['General'];
    }
  }

  /// Obtiene las tallas disponibles por tipo de negocio
  /// NOTA: Este método estático se mantiene para compatibilidad,
  /// pero ahora se recomienda usar las tallas dinámicas del servicio
  static List<String> getTallasPorTipo(String tipoNegocio) {
    switch (tipoNegocio) {
      case 'textil':
        return [
          '0-3 meses',
          '3-6 meses',
          '6-12 meses',
          '12-18 meses',
          '18-24 meses',
          '2T',
          '3T',
          '4T',
          '5T',
        ];
      case 'almacen':
        return [
          'Única',
          'XS',
          'S',
          'M',
          'L',
          'XL',
          'XXL',
        ];
      case 'manufactura':
        return [
          'Pequeño',
          'Mediano',
          'Grande',
          'Extra Grande',
        ];
      case 'servicio':
        return [
          'Por hora',
          'Por proyecto',
          'Por consulta',
          'Mensual',
        ];
      default:
        return ['Única'];
    }
  }
}
