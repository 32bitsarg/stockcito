/// Modelo para costos indirectos
class CostoIndirecto {
  final String id;
  final String nombre;
  final String tipo; // 'alquiler', 'servicios', 'sueldos', 'marketing', 'otro'
  final double costoMensual;
  final int productosEstimadosMensuales;
  final String? descripcion;
  final DateTime fechaCreacion;

  const CostoIndirecto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.costoMensual,
    required this.productosEstimadosMensuales,
    this.descripcion,
    required this.fechaCreacion,
  });

  /// Crea un nuevo costo indirecto
  factory CostoIndirecto.nuevo({
    required String nombre,
    required String tipo,
    required double costoMensual,
    required int productosEstimadosMensuales,
    String? descripcion,
  }) {
    return CostoIndirecto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      tipo: tipo,
      costoMensual: costoMensual,
      productosEstimadosMensuales: productosEstimadosMensuales,
      descripcion: descripcion,
      fechaCreacion: DateTime.now(),
    );
  }

  /// Crea una copia con nuevos valores
  CostoIndirecto copyWith({
    String? id,
    String? nombre,
    String? tipo,
    double? costoMensual,
    int? productosEstimadosMensuales,
    String? descripcion,
    DateTime? fechaCreacion,
  }) {
    return CostoIndirecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      costoMensual: costoMensual ?? this.costoMensual,
      productosEstimadosMensuales: productosEstimadosMensuales ?? this.productosEstimadosMensuales,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Calcula el costo por producto
  double get costoPorProducto {
    if (productosEstimadosMensuales > 0) {
      return costoMensual / productosEstimadosMensuales;
    }
    return 0.0;
  }

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'costoMensual': costoMensual,
      'productosEstimadosMensuales': productosEstimadosMensuales,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory CostoIndirecto.fromMap(Map<String, dynamic> map) {
    return CostoIndirecto(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'otro',
      costoMensual: map['costoMensual']?.toDouble() ?? 0.0,
      productosEstimadosMensuales: map['productosEstimadosMensuales'] ?? 1,
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.parse(map['fechaCreacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Obtiene los tipos de costos indirectos disponibles
  static List<Map<String, dynamic>> getTiposDisponibles() {
    return [
      {
        'id': 'alquiler',
        'nombre': 'Alquiler',
        'descripcion': 'Alquiler del local o taller',
        'icono': '🏠',
        'sugerencia': 'Incluye alquiler del local, taller o espacio de trabajo',
      },
      {
        'id': 'servicios',
        'nombre': 'Servicios',
        'descripcion': 'Luz, gas, agua, internet',
        'icono': '⚡',
        'sugerencia': 'Servicios básicos del local',
      },
      {
        'id': 'sueldos',
        'nombre': 'Sueldos',
        'descripcion': 'Personal administrativo',
        'icono': '👥',
        'sugerencia': 'Sueldos de personal no productivo',
      },
      {
        'id': 'marketing',
        'nombre': 'Marketing',
        'descripcion': 'Publicidad y promoción',
        'icono': '📢',
        'sugerencia': 'Gastos en publicidad, redes sociales, etc.',
      },
      {
        'id': 'seguros',
        'nombre': 'Seguros',
        'descripcion': 'Seguros del negocio',
        'icono': '🛡️',
        'sugerencia': 'Seguros de responsabilidad, equipos, etc.',
      },
      {
        'id': 'mantenimiento',
        'nombre': 'Mantenimiento',
        'descripcion': 'Mantenimiento de equipos',
        'icono': '🔧',
        'sugerencia': 'Mantenimiento de máquinas y equipos',
      },
      {
        'id': 'depreciacion',
        'nombre': 'Depreciación',
        'descripcion': 'Depreciación de equipos',
        'icono': '📉',
        'sugerencia': 'Depreciación mensual de equipos e inversiones',
      },
      {
        'id': 'otro',
        'nombre': 'Otro',
        'descripcion': 'Otros gastos fijos',
        'icono': '💰',
        'sugerencia': 'Otros gastos fijos del negocio',
      },
    ];
  }

  /// Obtiene el icono para un tipo
  static String getIconoPorTipo(String tipo) {
    final tipos = getTiposDisponibles();
    final tipoEncontrado = tipos.firstWhere(
      (t) => t['id'] == tipo,
      orElse: () => {'icono': '💰'},
    );
    return tipoEncontrado['icono'];
  }

  /// Obtiene la sugerencia para un tipo
  static String getSugerenciaPorTipo(String tipo) {
    final tipos = getTiposDisponibles();
    final tipoEncontrado = tipos.firstWhere(
      (t) => t['id'] == tipo,
      orElse: () => {'sugerencia': 'Gasto fijo del negocio'},
    );
    return tipoEncontrado['sugerencia'];
  }

  /// Valida si el costo indirecto está completo
  bool get isValid {
    return nombre.isNotEmpty && 
           costoMensual > 0 && 
           productosEstimadosMensuales > 0;
  }
}
