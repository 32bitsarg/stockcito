/// Modelo para resultados de búsqueda global
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type; // 'producto', 'venta', 'cliente'
  final Map<String, dynamic> data;
  double relevanceScore;
  List<String> matchedFields;
  final DateTime createdAt;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.data,
    required this.relevanceScore,
    required this.matchedFields,
    required this.createdAt,
  });

  /// Crea un resultado de búsqueda para un producto
  factory SearchResult.fromProducto(Map<String, dynamic> producto) {
    return SearchResult(
      id: producto['id'].toString(),
      title: producto['nombre'] ?? 'Sin nombre',
      subtitle: '${producto['categoria'] ?? 'Sin categoría'} - ${producto['talla'] ?? 'Sin talla'}',
      type: 'producto',
      data: producto,
      relevanceScore: 0.0, // Se calculará en el servicio
      matchedFields: [],
      createdAt: DateTime.parse(producto['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Crea un resultado de búsqueda para una venta
  factory SearchResult.fromVenta(Map<String, dynamic> venta) {
    return SearchResult(
      id: venta['id'].toString(),
      title: venta['cliente'] ?? 'Cliente sin nombre',
      subtitle: 'Venta - ${venta['estado'] ?? 'Sin estado'} - \$${venta['total']?.toStringAsFixed(2) ?? '0.00'}',
      type: 'venta',
      data: venta,
      relevanceScore: 0.0,
      matchedFields: [],
      createdAt: DateTime.parse(venta['fecha'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Crea un resultado de búsqueda para un cliente
  factory SearchResult.fromCliente(Map<String, dynamic> cliente) {
    return SearchResult(
      id: cliente['id'].toString(),
      title: cliente['nombre'] ?? 'Cliente sin nombre',
      subtitle: '${cliente['telefono'] ?? 'Sin teléfono'} - ${cliente['email'] ?? 'Sin email'}',
      type: 'cliente',
      data: cliente,
      relevanceScore: 0.0,
      matchedFields: [],
      createdAt: DateTime.parse(cliente['fechaRegistro'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'data': data,
      'relevanceScore': relevanceScore,
      'matchedFields': matchedFields,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SearchResult.fromMap(Map<String, dynamic> map) {
    return SearchResult(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: map['type'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      relevanceScore: (map['relevanceScore'] ?? 0.0).toDouble(),
      matchedFields: List<String>.from(map['matchedFields'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'SearchResult(id: $id, title: $title, type: $type, relevanceScore: $relevanceScore)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult && other.id == id && other.type == type;
  }

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

/// Tipos de entidades que se pueden buscar
enum SearchEntityType {
  producto,
  venta,
  cliente,
  all,
}

/// Filtros de búsqueda
class SearchFilters {
  final List<SearchEntityType> entityTypes;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? category;
  final String? status;

  const SearchFilters({
    this.entityTypes = const [SearchEntityType.all],
    this.dateFrom,
    this.dateTo,
    this.category,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'entityTypes': entityTypes.map((e) => e.name).toList(),
      'dateFrom': dateFrom?.toIso8601String(),
      'dateTo': dateTo?.toIso8601String(),
      'category': category,
      'status': status,
    };
  }

  factory SearchFilters.fromMap(Map<String, dynamic> map) {
    return SearchFilters(
      entityTypes: (map['entityTypes'] as List<dynamic>?)
          ?.map((e) => SearchEntityType.values.firstWhere(
                (type) => type.name == e,
                orElse: () => SearchEntityType.all,
              ))
          .toList() ?? [SearchEntityType.all],
      dateFrom: map['dateFrom'] != null ? DateTime.parse(map['dateFrom']) : null,
      dateTo: map['dateTo'] != null ? DateTime.parse(map['dateTo']) : null,
      category: map['category'],
      status: map['status'],
    );
  }
}
