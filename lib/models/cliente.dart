class Cliente {
  final int? id;
  final String nombre;
  final String telefono;
  final String email;
  final String direccion;
  final DateTime fechaRegistro;
  final String notas;
  final int totalCompras;
  final double totalGastado;

  Cliente({
    this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.fechaRegistro,
    required this.notas,
    this.totalCompras = 0,
    this.totalGastado = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'fecha_registro': fechaRegistro.toIso8601String(),
      'notas': notas,
      'total_compras': totalCompras,
      'total_gastado': totalGastado,
    };
  }

  factory Cliente.fromMap(Map<String, dynamic> map) {
    return Cliente(
      id: map['id'],
      nombre: map['nombre'],
      telefono: map['telefono'],
      email: map['email'],
      direccion: map['direccion'],
      fechaRegistro: DateTime.parse(map['fecha_registro']),
      notas: map['notas'],
      totalCompras: map['total_compras'] ?? 0,
      totalGastado: map['total_gastado'] ?? 0.0,
    );
  }

  Cliente copyWith({
    int? id,
    String? nombre,
    String? telefono,
    String? email,
    String? direccion,
    DateTime? fechaRegistro,
    String? notas,
    int? totalCompras,
    double? totalGastado,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      notas: notas ?? this.notas,
      totalCompras: totalCompras ?? this.totalCompras,
      totalGastado: totalGastado ?? this.totalGastado,
    );
  }
}
