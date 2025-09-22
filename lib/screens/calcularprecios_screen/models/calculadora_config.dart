/// Configuración de la calculadora de precios
class CalculadoraConfig {
  final bool modoAvanzado;
  final String tipoNegocio;
  final double margenGananciaDefault;
  final double ivaDefault;
  final bool autoGuardar;
  final bool mostrarAnalisisDetallado;

  const CalculadoraConfig({
    required this.modoAvanzado,
    this.tipoNegocio = 'textil',
    this.margenGananciaDefault = 45.0,
    this.ivaDefault = 21.0,
    this.autoGuardar = true,
    this.mostrarAnalisisDetallado = true,
  });

  /// Configuración por defecto
  static const CalculadoraConfig defaultConfig = CalculadoraConfig(
    modoAvanzado: false,
    tipoNegocio: 'textil',
    margenGananciaDefault: 45.0,
    ivaDefault: 21.0,
    autoGuardar: true,
    mostrarAnalisisDetallado: true,
  );

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'modoAvanzado': modoAvanzado,
      'tipoNegocio': tipoNegocio,
      'margenGananciaDefault': margenGananciaDefault,
      'ivaDefault': ivaDefault,
      'autoGuardar': autoGuardar,
      'mostrarAnalisisDetallado': mostrarAnalisisDetallado,
    };
  }

  /// Crea desde Map
  factory CalculadoraConfig.fromMap(Map<String, dynamic> map) {
    return CalculadoraConfig(
      modoAvanzado: map['modoAvanzado'] ?? false,
      tipoNegocio: map['tipoNegocio'] ?? 'textil',
      margenGananciaDefault: map['margenGananciaDefault']?.toDouble() ?? 45.0,
      ivaDefault: map['ivaDefault']?.toDouble() ?? 21.0,
      autoGuardar: map['autoGuardar'] ?? true,
      mostrarAnalisisDetallado: map['mostrarAnalisisDetallado'] ?? true,
    );
  }

  /// Crea una copia con nuevos valores
  CalculadoraConfig copyWith({
    bool? modoAvanzado,
    String? tipoNegocio,
    double? margenGananciaDefault,
    double? ivaDefault,
    bool? autoGuardar,
    bool? mostrarAnalisisDetallado,
  }) {
    return CalculadoraConfig(
      modoAvanzado: modoAvanzado ?? this.modoAvanzado,
      tipoNegocio: tipoNegocio ?? this.tipoNegocio,
      margenGananciaDefault: margenGananciaDefault ?? this.margenGananciaDefault,
      ivaDefault: ivaDefault ?? this.ivaDefault,
      autoGuardar: autoGuardar ?? this.autoGuardar,
      mostrarAnalisisDetallado: mostrarAnalisisDetallado ?? this.mostrarAnalisisDetallado,
    );
  }

  /// Tipos de negocio disponibles
  static const List<Map<String, dynamic>> tiposNegocio = [
    {
      'id': 'textil',
      'nombre': 'Textil/Confección',
      'descripcion': 'Ropa, accesorios, productos textiles',
      'icono': '👕',
    },
    {
      'id': 'almacen',
      'nombre': 'Almacén/Comercio',
      'descripcion': 'Productos de almacén, comercio general',
      'icono': '🏪',
    },
    {
      'id': 'manufactura',
      'nombre': 'Manufactura',
      'descripcion': 'Productos manufacturados, artesanías',
      'icono': '🏭',
    },
    {
      'id': 'servicio',
      'nombre': 'Servicios',
      'descripcion': 'Servicios profesionales, consultoría',
      'icono': '💼',
    },
  ];
}
