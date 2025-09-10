class Venta {
  final int? id;
  final String cliente;
  final String telefono;
  final String email;
  final DateTime fecha;
  final double total;
  final String metodoPago;
  final String estado;
  final String notas;
  final List<VentaItem> items;

  Venta({
    this.id,
    required this.cliente,
    required this.telefono,
    required this.email,
    required this.fecha,
    required this.total,
    required this.metodoPago,
    required this.estado,
    required this.notas,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'telefono': telefono,
      'email': email,
      'fecha': fecha.toIso8601String(),
      'total': total,
      'metodo_pago': metodoPago,
      'estado': estado,
      'notas': notas,
    };
  }

  factory Venta.fromMap(Map<String, dynamic> map) {
    return Venta(
      id: map['id'],
      cliente: map['cliente'],
      telefono: map['telefono'],
      email: map['email'],
      fecha: DateTime.parse(map['fecha']),
      total: map['total'],
      metodoPago: map['metodo_pago'],
      estado: map['estado'],
      notas: map['notas'],
      items: [], // Se cargará por separado
    );
  }

  Venta copyWith({
    int? id,
    String? cliente,
    String? telefono,
    String? email,
    DateTime? fecha,
    double? total,
    String? metodoPago,
    String? estado,
    String? notas,
    List<VentaItem>? items,
  }) {
    return Venta(
      id: id ?? this.id,
      cliente: cliente ?? this.cliente,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      fecha: fecha ?? this.fecha,
      total: total ?? this.total,
      metodoPago: metodoPago ?? this.metodoPago,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      items: items ?? this.items,
    );
  }
}

class VentaItem {
  final int? id;
  final int ventaId;
  final int productoId;
  final String nombreProducto;
  final String categoria;
  final String talla;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  VentaItem({
    this.id,
    required this.ventaId,
    required this.productoId,
    required this.nombreProducto,
    required this.categoria,
    required this.talla,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'venta_id': ventaId,
      'producto_id': productoId,
      'nombre_producto': nombreProducto,
      'categoria': categoria,
      'talla': talla,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  factory VentaItem.fromMap(Map<String, dynamic> map) {
    return VentaItem(
      id: map['id'],
      ventaId: map['venta_id'],
      productoId: map['producto_id'],
      nombreProducto: map['nombre_producto'],
      categoria: map['categoria'],
      talla: map['talla'],
      cantidad: map['cantidad'],
      precioUnitario: map['precio_unitario'],
      subtotal: map['subtotal'],
    );
  }
}
