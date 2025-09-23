
class Talla {
  final int? id;
  final String nombre;
  final String? descripcion;
  final int orden; // Para ordenar las tallas
  final DateTime fechaCreacion;
  final DateTime updatedAt;
  final String? userId;
  final bool isDefault;

  Talla({
    this.id,
    required this.nombre,
    this.descripcion,
    this.orden = 0,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
    this.userId,
    this.isDefault = false,
  })  : fechaCreacion = fechaCreacion ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor para crear una Talla desde un Map (SQLite)
  factory Talla.fromMap(Map<String, dynamic> map) {
    return Talla(
      id: map['id'] as int?,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      orden: map['orden'] as int,
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userId: map['user_id'] as String?,
      isDefault: (map['is_default'] as int) == 1,
    );
  }

  // Factory constructor para crear una Talla desde JSON (Supabase)
  factory Talla.fromJson(Map<String, dynamic> json) {
    return Talla(
      id: json['id'] as int?,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      orden: json['orden'] as int,
      fechaCreacion: DateTime.parse(json['fecha_creacion'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String?,
      isDefault: json['is_default'] as bool,
    );
  }

  // Convierte una Talla a un Map (SQLite)
  Map<String, dynamic> toMap() {
    final map = {
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'is_default': isDefault ? 1 : 0,
    };
    
    // Solo incluir id si no es null (para actualizaciones)
    if (id != null) {
      map['id'] = id;
    }
    
    return map;
  }

  // Convierte una Talla a JSON (Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'is_default': isDefault,
    };
  }

  // Método copyWith para crear una nueva instancia con valores modificados
  Talla copyWith({
    int? id,
    String? nombre,
    String? descripcion,
    int? orden,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
    String? userId,
    bool? isDefault,
  }) {
    return Talla(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  String toString() {
    return 'Talla(id: $id, nombre: $nombre, descripcion: $descripcion, orden: $orden, fechaCreacion: $fechaCreacion, updatedAt: $updatedAt, userId: $userId, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Talla &&
        other.id == id &&
        other.nombre == nombre &&
        other.descripcion == descripcion &&
        other.orden == orden &&
        other.fechaCreacion == fechaCreacion &&
        other.updatedAt == updatedAt &&
        other.userId == userId &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        nombre.hashCode ^
        descripcion.hashCode ^
        orden.hashCode ^
        fechaCreacion.hashCode ^
        updatedAt.hashCode ^
        userId.hashCode ^
        isDefault.hashCode;
  }

  // Tallas por defecto para ropa de bebé
  static List<Talla> get defaultTallas {
    return [
      Talla(nombre: '0-3 meses', descripcion: 'Recién nacido', orden: 1, isDefault: true),
      Talla(nombre: '3-6 meses', descripcion: 'Bebé pequeño', orden: 2, isDefault: true),
      Talla(nombre: '6-12 meses', descripcion: 'Bebé mediano', orden: 3, isDefault: true),
      Talla(nombre: '12-18 meses', descripcion: 'Bebé grande', orden: 4, isDefault: true),
      Talla(nombre: '18-24 meses', descripcion: 'Toddler', orden: 5, isDefault: true),
      Talla(nombre: '2T', descripcion: 'Toddler 2 años', orden: 6, isDefault: true),
      Talla(nombre: '3T', descripcion: 'Toddler 3 años', orden: 7, isDefault: true),
      Talla(nombre: '4T', descripcion: 'Toddler 4 años', orden: 8, isDefault: true),
    ];
  }
}
