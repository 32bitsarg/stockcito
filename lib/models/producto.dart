class Producto {
  final int? id;
  final String nombre;
  final String categoria;
  final String talla;
  final double costoMateriales;
  final double costoManoObra;
  final double gastosGenerales;
  final double margenGanancia;
  final int stock;
  final DateTime fechaCreacion;

  Producto({
    this.id,
    required this.nombre,
    required this.categoria,
    required this.talla,
    required this.costoMateriales,
    required this.costoManoObra,
    required this.gastosGenerales,
    required this.margenGanancia,
    required this.stock,
    required this.fechaCreacion,
  });

  // Calcular costo total
  double get costoTotal => costoMateriales + costoManoObra + gastosGenerales;

  // Calcular precio de venta
  double get precioVenta => costoTotal * (1 + margenGanancia / 100);

  // Calcular precio con IVA (21%)
  double get precioConIVA => precioVenta * 1.21;

  // Convertir a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'talla': talla,
      'costo_materiales': costoMateriales,
      'costo_mano_obra': costoManoObra,
      'gastos_generales': gastosGenerales,
      'margen_ganancia': margenGanancia,
      'stock': stock,
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  // Crear desde Map (desde base de datos)
  factory Producto.fromMap(Map<String, dynamic> map) {
    return Producto(
      id: map['id'],
      nombre: map['nombre'],
      categoria: map['categoria'],
      talla: map['talla'],
      costoMateriales: map['costo_materiales'],
      costoManoObra: map['costo_mano_obra'],
      gastosGenerales: map['gastos_generales'],
      margenGanancia: map['margen_ganancia'],
      stock: map['stock'],
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
    );
  }
}
