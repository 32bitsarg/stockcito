/// Modelo para costos directos
class CostoDirecto {
  final String id;
  final String nombre;
  final String tipo; // 'material', 'mano_obra', 'equipo', 'otro'
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double desperdicio; // % de desperdicio
  final String? descripcion;
  final DateTime fechaCreacion;

  const CostoDirecto({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    this.desperdicio = 0.0,
    this.descripcion,
    required this.fechaCreacion,
  });

  /// Crea un nuevo costo directo
  factory CostoDirecto.nuevo({
    required String nombre,
    required String tipo,
    required double cantidad,
    required String unidad,
    required double precioUnitario,
    double desperdicio = 0.0,
    String? descripcion,
  }) {
    return CostoDirecto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      tipo: tipo,
      cantidad: cantidad,
      unidad: unidad,
      precioUnitario: precioUnitario,
      desperdicio: desperdicio,
      descripcion: descripcion,
      fechaCreacion: DateTime.now(),
    );
  }

  /// Crea una copia con nuevos valores
  CostoDirecto copyWith({
    String? id,
    String? nombre,
    String? tipo,
    double? cantidad,
    String? unidad,
    double? precioUnitario,
    double? desperdicio,
    String? descripcion,
    DateTime? fechaCreacion,
  }) {
    return CostoDirecto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      unidad: unidad ?? this.unidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      desperdicio: desperdicio ?? this.desperdicio,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }

  /// Calcula el costo total incluyendo desperdicio
  double get costoTotal {
    final costoBase = cantidad * precioUnitario;
    final costoDesperdicio = costoBase * (desperdicio / 100);
    return costoBase + costoDesperdicio;
  }

  /// Calcula el costo por unidad
  double get costoPorUnidad {
    return precioUnitario * (1 + desperdicio / 100);
  }

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'cantidad': cantidad,
      'unidad': unidad,
      'precioUnitario': precioUnitario,
      'desperdicio': desperdicio,
      'descripcion': descripcion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  /// Crea desde Map
  factory CostoDirecto.fromMap(Map<String, dynamic> map) {
    return CostoDirecto(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      tipo: map['tipo'] ?? 'material',
      cantidad: map['cantidad']?.toDouble() ?? 0.0,
      unidad: map['unidad'] ?? '',
      precioUnitario: map['precioUnitario']?.toDouble() ?? 0.0,
      desperdicio: map['desperdicio']?.toDouble() ?? 0.0,
      descripcion: map['descripcion'],
      fechaCreacion: DateTime.parse(map['fechaCreacion'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Obtiene los tipos de costos directos disponibles
  static List<Map<String, dynamic>> getTiposDisponibles() {
    return [
      {
        'id': 'material',
        'nombre': 'Material',
        'descripcion': 'Materiales e insumos',
        'icono': '🧵',
        'unidades': ['metro', 'kg', 'unidad', 'rollo', 'paquete'],
      },
      {
        'id': 'mano_obra',
        'nombre': 'Mano de Obra',
        'descripcion': 'Tiempo de trabajo',
        'icono': '👷',
        'unidades': ['hora', 'día', 'semana'],
      },
      {
        'id': 'equipo',
        'nombre': 'Equipo/Máquina',
        'descripcion': 'Uso de equipos y máquinas',
        'icono': '🔧',
        'unidades': ['hora', 'día', 'unidad'],
      },
      {
        'id': 'embalaje',
        'nombre': 'Embalaje',
        'descripcion': 'Bolsas, etiquetas, packaging',
        'icono': '📦',
        'unidades': ['unidad', 'metro', 'kg'],
      },
      {
        'id': 'otro',
        'nombre': 'Otro',
        'descripcion': 'Otros costos directos',
        'icono': '💰',
        'unidades': ['unidad', 'metro', 'kg', 'hora'],
      },
    ];
  }

  /// Obtiene las unidades disponibles para un tipo
  static List<String> getUnidadesPorTipo(String tipo) {
    final tipos = getTiposDisponibles();
    final tipoEncontrado = tipos.firstWhere(
      (t) => t['id'] == tipo,
      orElse: () => {'unidades': ['unidad']},
    );
    return List<String>.from(tipoEncontrado['unidades']);
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

  /// Valida si el costo directo está completo
  bool get isValid {
    return nombre.isNotEmpty && 
           cantidad > 0 && 
           precioUnitario > 0 &&
           unidad.isNotEmpty;
  }
}
