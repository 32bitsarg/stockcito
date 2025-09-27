import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../models/producto.dart';
import 'calculadora_validation_service.dart';
import 'calculadora_persistence_service.dart';
import 'calculadora_pricing_service.dart';

/// Resultado del modo simple
class ResultadoModoSimple {
  final bool exito;
  final String? mensaje;
  final Producto? productoGuardado;
  final Map<String, dynamic>? analisisBasico;

  const ResultadoModoSimple({
    required this.exito,
    this.mensaje,
    this.productoGuardado,
    this.analisisBasico,
  });
}

/// Servicio para manejar el modo simple de la calculadora
class ModoSimpleService {
  static final ModoSimpleService _instance = ModoSimpleService._internal();
  factory ModoSimpleService() => _instance;
  ModoSimpleService._internal();

  final DatosService _datosService = DatosService();
  final CalculadoraValidationService _validationService = CalculadoraValidationService();
  final CalculadoraPersistenceService _persistenceService = CalculadoraPersistenceService();

  /// Guarda un producto en modo simple
  Future<ResultadoModoSimple> guardarProductoSimple({
    required String nombre,
    required String categoria,
    String? talla,
    required int stock,
    required double precioActual,
    String? descripcion,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('📦 Guardando producto en modo simple: $nombre');

      // 1. Validar datos básicos
      final validacion = _validationService.validarModoSimple(
        nombre: nombre,
        categoria: categoria,
        talla: talla,
        stock: stock,
        precioActual: precioActual,
        descripcion: descripcion,
      );

      if (!validacion.esValido) {
        final errores = validacion.errores.values.join(', ');
        LoggingService.error('❌ Validación fallida: $errores');
        return ResultadoModoSimple(
          exito: false,
          mensaje: 'Datos inválidos: $errores',
        );
      }

      // 2. Crear producto de cálculo
      final productoCalculo = ProductoCalculo(
        nombre: nombre.trim(),
        categoria: categoria.trim(),
        talla: talla?.trim() ?? 'Única',
        stock: stock,
        precioVenta: precioActual,
        descripcion: descripcion?.trim() ?? '',
        tipoNegocio: config.tipoNegocio,
        fechaCreacion: DateTime.now(),
      );

      // 3. Calcular análisis básico
      final analisisBasico = _calcularAnalisisBasico(productoCalculo, config);

      // 4. Crear producto para la base de datos
      final producto = Producto(
        id: 0, // Se asignará automáticamente
        nombre: productoCalculo.nombre,
        categoria: productoCalculo.categoria,
        talla: productoCalculo.talla,
        stock: productoCalculo.stock,
        costoMateriales: precioActual * 0.6, // Estimación conservadora
        costoManoObra: precioActual * 0.3, // Estimación conservadora
        gastosGenerales: precioActual * 0.1, // Estimación conservadora
        margenGanancia: _calcularMargenEstimado(precioActual, config),
        fechaCreacion: productoCalculo.fechaCreacion,
      );

      // 5. Guardar en la base de datos
      final success = await _datosService.saveProducto(producto);
      
      if (!success) {
        LoggingService.error('❌ Error guardando producto en base de datos');
        return ResultadoModoSimple(
          exito: false,
          mensaje: 'Error guardando producto en la base de datos',
        );
      }

      // 6. Guardar en historial (solo para registro)
      await _guardarEnHistorialSimple(productoCalculo, precioActual, analisisBasico);

      LoggingService.info('✅ Producto guardado exitosamente en modo simple');
      
      return ResultadoModoSimple(
        exito: true,
        mensaje: 'Producto guardado exitosamente',
        productoGuardado: producto,
        analisisBasico: analisisBasico,
      );
    } catch (e) {
      LoggingService.error('❌ Error guardando producto simple: $e');
      return ResultadoModoSimple(
        exito: false,
        mensaje: 'Error interno: $e',
      );
    }
  }

  /// Obtiene sugerencias de precio basadas en categoría
  Future<Map<String, dynamic>> obtenerSugerenciasPrecio({
    required String categoria,
    required CalculadoraConfig config,
  }) async {
    try {
      LoggingService.info('💡 Obteniendo sugerencias de precio para: $categoria');

      // Obtener productos similares de la base de datos
      final productosSimilares = await _obtenerProductosSimilares(categoria);
      
      // Calcular estadísticas básicas
      final estadisticas = _calcularEstadisticasCategoria(productosSimilares);
      
      // Generar sugerencias
      final sugerencias = _generarSugerenciasBasicas(estadisticas, config);

      LoggingService.info('✅ Sugerencias generadas exitosamente');
      
      return {
        'estadisticas': estadisticas,
        'sugerencias': sugerencias,
        'productosSimilares': productosSimilares.length,
        'confianza': _calcularConfianzaSugerencias(productosSimilares.length),
      };
    } catch (e) {
      LoggingService.error('❌ Error obteniendo sugerencias: $e');
      return {
        'estadisticas': {},
        'sugerencias': ['No hay datos suficientes para sugerencias'],
        'productosSimilares': 0,
        'confianza': 0.0,
      };
    }
  }

  /// Valida si un precio es competitivo para la categoría
  Future<bool> validarCompetitividadPrecio({
    required String categoria,
    required double precio,
  }) async {
    try {
      LoggingService.info('🔍 Validando competitividad de precio: \$${precio.toStringAsFixed(2)}');

      final productosSimilares = await _obtenerProductosSimilares(categoria);
      
      if (productosSimilares.isEmpty) {
        LoggingService.info('ℹ️ No hay productos similares para comparar');
        return true; // Si no hay comparación, asumir que es válido
      }

      final preciosSimilares = productosSimilares.map((p) => p.precioVenta).toList();
      final precioPromedio = preciosSimilares.reduce((a, b) => a + b) / preciosSimilares.length;
      final precioMinimo = preciosSimilares.reduce((a, b) => a < b ? a : b);
      final precioMaximo = preciosSimilares.reduce((a, b) => a > b ? a : b);

      // Considerar competitivo si está dentro del rango ±30% del promedio
      final rangoMinimo = precioPromedio * 0.7;
      final rangoMaximo = precioPromedio * 1.3;

      final esCompetitivo = precio >= rangoMinimo && precio <= rangoMaximo;

      LoggingService.info('📊 Análisis competitividad: Promedio=\$${precioPromedio.toStringAsFixed(2)}, Rango=\$${rangoMinimo.toStringAsFixed(2)}-\$${rangoMaximo.toStringAsFixed(2)}, Competitivo=$esCompetitivo');

      return esCompetitivo;
    } catch (e) {
      LoggingService.error('❌ Error validando competitividad: $e');
      return true; // En caso de error, asumir que es válido
    }
  }

  /// Obtiene el historial de productos guardados en modo simple
  Future<List<Map<String, dynamic>>> obtenerHistorialSimple() async {
    try {
      LoggingService.info('📚 Obteniendo historial de modo simple');

      final historial = await _persistenceService.cargarHistorial(limite: 50);
      final historialSimple = historial
          .where((h) => h.modo == 'simple')
          .map((h) => {
                'id': h.id,
                'nombre': h.producto.nombre,
                'categoria': h.producto.categoria,
                'precio': h.precioCalculado.precioSugerido,
                'fecha': h.fechaCalculo,
                'fueGuardado': h.fueGuardado,
              })
          .toList();

      LoggingService.info('✅ Historial simple obtenido: ${historialSimple.length} productos');
      return historialSimple;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo historial simple: $e');
      return [];
    }
  }

  /// Calcula análisis básico del producto
  Map<String, dynamic> _calcularAnalisisBasico(ProductoCalculo producto, CalculadoraConfig config) {
    final precioConIVA = producto.precioVenta! * (1 + config.ivaDefault / 100);
    final costoEstimado = producto.precioVenta! * 0.8; // Estimación conservadora
    final margenEstimado = ((producto.precioVenta! - costoEstimado) / costoEstimado) * 100;

    return {
      'precioConIVA': precioConIVA,
      'costoEstimado': costoEstimado,
      'margenEstimado': margenEstimado,
      'rentabilidad': margenEstimado > config.margenGananciaDefault ? 'Alta' : 'Media',
      'competitividad': 'Por validar',
      'sugerencias': _generarSugerenciasBasicasProducto(producto, margenEstimado),
    };
  }

  /// Calcula margen estimado basado en configuración
  double _calcularMargenEstimado(double precio, CalculadoraConfig config) {
    // Estimación conservadora: asumir que el precio incluye un margen mínimo
    final costoEstimado = precio * 0.8;
    return ((precio - costoEstimado) / costoEstimado) * 100;
  }

  /// Obtiene productos similares de la base de datos
  Future<List<Producto>> _obtenerProductosSimilares(String categoria) async {
    try {
      final todosLosProductos = await _datosService.getProductos();
      return todosLosProductos.where((p) => p.categoria.toLowerCase() == categoria.toLowerCase()).toList();
    } catch (e) {
      LoggingService.error('❌ Error obteniendo productos similares: $e');
      return [];
    }
  }

  /// Calcula estadísticas de una categoría
  Map<String, dynamic> _calcularEstadisticasCategoria(List<Producto> productos) {
    if (productos.isEmpty) {
      return {
        'cantidad': 0,
        'precioPromedio': 0.0,
        'precioMinimo': 0.0,
        'precioMaximo': 0.0,
        'margenPromedio': 0.0,
      };
    }

    final precios = productos.map((p) => p.precioVenta).toList();
    final margenes = productos.map((p) => p.margenGanancia).toList();

    return {
      'cantidad': productos.length,
      'precioPromedio': precios.reduce((a, b) => a + b) / precios.length,
      'precioMinimo': precios.reduce((a, b) => a < b ? a : b),
      'precioMaximo': precios.reduce((a, b) => a > b ? a : b),
      'margenPromedio': margenes.reduce((a, b) => a + b) / margenes.length,
    };
  }

  /// Genera sugerencias básicas
  List<String> _generarSugerenciasBasicas(Map<String, dynamic> estadisticas, CalculadoraConfig config) {
    final sugerencias = <String>[];
    
    if (estadisticas['cantidad'] == 0) {
      sugerencias.add('No hay productos similares para comparar');
      sugerencias.add('Considera investigar precios de la competencia');
      return sugerencias;
    }

    final precioPromedio = estadisticas['precioPromedio'] as double;
    final margenPromedio = estadisticas['margenPromedio'] as double;

    if (margenPromedio < config.margenGananciaDefault) {
      sugerencias.add('Los productos similares tienen márgenes más bajos que tu configuración');
    }

    if (precioPromedio > 0) {
      sugerencias.add('Precio promedio en la categoría: \$${precioPromedio.toStringAsFixed(2)}');
    }

    sugerencias.add('Considera el análisis de costos para optimizar tu precio');
    sugerencias.add('Usa el modo avanzado para cálculos más precisos');

    return sugerencias;
  }

  /// Genera sugerencias específicas para un producto
  List<String> _generarSugerenciasBasicasProducto(ProductoCalculo producto, double margenEstimado) {
    final sugerencias = <String>[];

    if (margenEstimado < 20) {
      sugerencias.add('Margen estimado bajo, considera revisar costos');
    } else if (margenEstimado > 100) {
      sugerencias.add('Margen estimado alto, verifica competitividad');
    }

    if (producto.nombre.length < 5) {
      sugerencias.add('Nombre muy corto, considera ser más descriptivo');
    }

    if (producto.categoria.toLowerCase() == 'general') {
      sugerencias.add('Categoría muy general, considera ser más específico');
    }

    return sugerencias;
  }

  /// Calcula confianza de las sugerencias
  double _calcularConfianzaSugerencias(int cantidadProductos) {
    if (cantidadProductos == 0) return 0.0;
    if (cantidadProductos < 3) return 0.3;
    if (cantidadProductos < 10) return 0.6;
    return 0.8;
  }

  /// Guarda en historial para modo simple
  Future<void> _guardarEnHistorialSimple(
    ProductoCalculo producto,
    double precio,
    Map<String, dynamic> analisis,
  ) async {
    try {
      // Crear un PrecioCalculado simplificado para el historial
      final precioCalculado = PrecioCalculado(
        precioSugerido: precio,
        costoTotal: analisis['costoEstimado'] ?? precio * 0.8,
        precioBase: precio,
        margenGanancia: analisis['margenEstimado'] ?? 25.0,
        iva: 21.0,
        gananciaNeta: precio - (analisis['costoEstimado'] ?? precio * 0.8),
        analisis: analisis,
        factores: ['Modo simple', 'Precio fijo'],
        confianzaIA: 0.5,
        fechaCalculo: DateTime.now(),
      );

      await _persistenceService.guardarSoloHistorial(
        productoCalculo: producto,
        precioCalculado: precioCalculado,
        modo: 'simple',
      );
    } catch (e) {
      LoggingService.error('❌ Error guardando en historial simple: $e');
    }
  }
}
