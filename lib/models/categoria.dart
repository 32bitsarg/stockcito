class Categoria {
  final int? id;
  final String nombre;
  final String color; // Hex color
  final String icono; // FontAwesome icon name
  final String? descripcion;
  final DateTime fechaCreacion;
  final DateTime updatedAt;
  final String? userId; // Para usuarios autenticados
  final bool isDefault; // Si es categoría por defecto

  const Categoria({
    this.id,
    required this.nombre,
    required this.color,
    required this.icono,
    this.descripcion,
    required this.fechaCreacion,
    required this.updatedAt,
    this.userId,
    this.isDefault = false,
  });

  /// Crea una copia de la categoría con los campos modificados
  Categoria copyWith({
    int? id,
    String? nombre,
    String? color,
    String? icono,
    String? descripcion,
    DateTime? fechaCreacion,
    DateTime? updatedAt,
    String? userId,
    bool? isDefault,
  }) {
    return Categoria(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      descripcion: descripcion ?? this.descripcion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Convierte la categoría a Map para base de datos
  Map<String, dynamic> toMap() {
    final map = {
      'user_id': userId,
      'nombre': nombre,
      'color': color,
      'icono': icono,
      'descripcion': descripcion,
      'is_default': isDefault ? 1 : 0,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    
    // Solo incluir id si no es null (para actualizaciones)
    if (id != null) {
      map['id'] = id;
    }
    
    return map;
  }

  /// Crea una categoría desde Map de base de datos
  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id']?.toInt(),
      userId: map['user_id'],
      nombre: map['nombre'] ?? '',
      color: map['color'] ?? '#9E9E9E',
      icono: map['icono'] ?? 'tag',
      descripcion: map['descripcion'],
      isDefault: (map['is_default'] ?? 0) == 1,
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Convierte la categoría a Map para Supabase
  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'user_id': userId,
      'nombre': nombre,
      'color': color,
      'icono': icono,
      'descripcion': descripcion,
      'is_default': isDefault,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crea una categoría desde Map de Supabase
  factory Categoria.fromSupabaseMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id']?.toInt(),
      userId: map['user_id'],
      nombre: map['nombre'] ?? '',
      color: map['color'] ?? '#9E9E9E',
      icono: map['icono'] ?? 'tag',
      descripcion: map['descripcion'],
      isDefault: map['is_default'] ?? false,
      fechaCreacion: DateTime.parse(map['fecha_creacion']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Convierte la categoría a JSON
  Map<String, dynamic> toJson() => toMap();

  /// Crea una categoría desde JSON
  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria.fromMap(json);

  @override
  String toString() {
    return 'Categoria(id: $id, nombre: $nombre, color: $color, icono: $icono, isDefault: $isDefault)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Categoria && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Obtiene las categorías por defecto
  static List<Categoria> getCategoriasPorDefecto() {
    final now = DateTime.now();
    return [
      Categoria(
        nombre: 'Bodies',
        color: '#E91E63',
        icono: 'baby',
        descripcion: 'Ropa interior para bebés',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
      Categoria(
        nombre: 'Conjuntos',
        color: '#9C27B0',
        icono: 'tshirt',
        descripcion: 'Conjuntos de ropa para bebés',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
      Categoria(
        nombre: 'Vestidos',
        color: '#673AB7',
        icono: 'dress',
        descripcion: 'Vestidos para bebés y niñas',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
      Categoria(
        nombre: 'Pijamas',
        color: '#3F51B5',
        icono: 'moon',
        descripcion: 'Pijamas y ropa de dormir',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
      Categoria(
        nombre: 'Gorros',
        color: '#2196F3',
        icono: 'hat-cowboy',
        descripcion: 'Gorros y accesorios para la cabeza',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
      Categoria(
        nombre: 'Accesorios',
        color: '#00BCD4',
        icono: 'gift',
        descripcion: 'Accesorios varios para bebés',
        fechaCreacion: now,
        updatedAt: now,
        isDefault: true,
      ),
    ];
  }
}
