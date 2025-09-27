import '../../../services/system/logging_service.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';

/// Resultado de validación
class ValidacionResultado {
  final bool esValido;
  final Map<String, String> errores;
  final Map<String, String> advertencias;
  final List<String> sugerencias;

  const ValidacionResultado({
    required this.esValido,
    required this.errores,
    required this.advertencias,
    required this.sugerencias,
  });

  bool get tieneErrores => errores.isNotEmpty;
  bool get tieneAdvertencias => advertencias.isNotEmpty;
  bool get tieneSugerencias => sugerencias.isNotEmpty;
}

/// Servicio para validar datos de la calculadora de precios
class CalculadoraValidationService {
  static final CalculadoraValidationService _instance = CalculadoraValidationService._internal();
  factory CalculadoraValidationService() => _instance;
  CalculadoraValidationService._internal();

  /// Valida datos para modo simple
  ValidacionResultado validarModoSimple({
    required String nombre,
    required String categoria,
    String? talla,
    required int stock,
    required double precioActual,
    String? descripcion,
  }) {
    try {
      LoggingService.info('🔍 Validando datos modo simple: $nombre');

      final errores = <String, String>{};
      final advertencias = <String, String>{};
      final sugerencias = <String>[];

      // Validar nombre
      if (nombre.trim().isEmpty) {
        errores['nombre'] = 'El nombre del producto es requerido';
      } else if (nombre.trim().length < 2) {
        errores['nombre'] = 'El nombre debe tener al menos 2 caracteres';
      } else if (nombre.trim().length > 100) {
        errores['nombre'] = 'El nombre no puede exceder 100 caracteres';
      }

      // Validar categoría
      if (categoria.trim().isEmpty) {
        errores['categoria'] = 'La categoría es requerida';
      }

      // Validar talla (opcional pero si se proporciona debe ser válida)
      if (talla != null && talla.trim().isNotEmpty) {
        if (talla.trim().length > 20) {
          errores['talla'] = 'La talla no puede exceder 20 caracteres';
        }
      }

      // Validar stock
      if (stock < 0) {
        errores['stock'] = 'El stock no puede ser negativo';
      } else if (stock > 10000) {
        errores['stock'] = 'El stock no puede exceder 10,000 unidades';
      } else if (stock == 0) {
        advertencias['stock'] = 'El stock es 0, considera si es correcto';
      }

      // Validar precio
      if (precioActual <= 0) {
        errores['precio'] = 'El precio debe ser mayor a 0';
      } else if (precioActual > 100000) {
        errores['precio'] = 'El precio no puede exceder \$100,000';
      } else if (precioActual < 1) {
        advertencias['precio'] = 'El precio es muy bajo, considera costos mínimos';
      }

      // Validar descripción (opcional)
      if (descripcion != null && descripcion.trim().isNotEmpty) {
        if (descripcion.trim().length > 500) {
          errores['descripcion'] = 'La descripción no puede exceder 500 caracteres';
        }
      }

      // Generar sugerencias
      if (precioActual > 0 && precioActual < 10) {
        sugerencias.add('Considera si el precio cubre todos los costos básicos');
      }

      if (nombre.trim().length < 5) {
        sugerencias.add('Un nombre más descriptivo puede ayudar en las ventas');
      }

      if (categoria.trim().toLowerCase().contains('general')) {
        sugerencias.add('Considera usar una categoría más específica');
      }

      final esValido = errores.isEmpty;
      
      LoggingService.info('✅ Validación modo simple completada: ${esValido ? "Válido" : "Con errores"}');
      
      return ValidacionResultado(
        esValido: esValido,
        errores: errores,
        advertencias: advertencias,
        sugerencias: sugerencias,
      );
    } catch (e) {
      LoggingService.error('❌ Error validando modo simple: $e');
      return ValidacionResultado(
        esValido: false,
        errores: {'general': 'Error interno de validación'},
        advertencias: {},
        sugerencias: [],
      );
    }
  }

  /// Valida datos para modo avanzado
  ValidacionResultado validarModoAvanzado({
    required ProductoCalculo producto,
    required List<CostoDirecto> costosDirectos,
    required List<CostoIndirecto> costosIndirectos,
    required CalculadoraConfig config,
  }) {
    try {
      LoggingService.info('🔍 Validando datos modo avanzado: ${producto.nombre}');

      final errores = <String, String>{};
      final advertencias = <String, String>{};
      final sugerencias = <String>[];

      // Validar producto básico
      final validacionProducto = validarProductoBasico(producto);
      errores.addAll(validacionProducto.errores);
      advertencias.addAll(validacionProducto.advertencias);
      sugerencias.addAll(validacionProducto.sugerencias);

      // Validar costos directos
      final validacionDirectos = validarCostosDirectos(costosDirectos);
      errores.addAll(validacionDirectos.errores);
      advertencias.addAll(validacionDirectos.advertencias);
      sugerencias.addAll(validacionDirectos.sugerencias);

      // Validar costos indirectos
      final validacionIndirectos = validarCostosIndirectos(costosIndirectos);
      errores.addAll(validacionIndirectos.errores);
      advertencias.addAll(validacionIndirectos.advertencias);
      sugerencias.addAll(validacionIndirectos.sugerencias);

      // Validar configuración
      final validacionConfig = validarConfiguracion(config);
      errores.addAll(validacionConfig.errores);
      advertencias.addAll(validacionConfig.advertencias);
      sugerencias.addAll(validacionConfig.sugerencias);

      // Validar coherencia general
      final validacionCoherencia = validarCoherenciaGeneral(
        producto, costosDirectos, costosIndirectos, config,
      );
      errores.addAll(validacionCoherencia.errores);
      advertencias.addAll(validacionCoherencia.advertencias);
      sugerencias.addAll(validacionCoherencia.sugerencias);

      final esValido = errores.isEmpty;
      
      LoggingService.info('✅ Validación modo avanzado completada: ${esValido ? "Válido" : "Con errores"}');
      
      return ValidacionResultado(
        esValido: esValido,
        errores: errores,
        advertencias: advertencias,
        sugerencias: sugerencias,
      );
    } catch (e) {
      LoggingService.error('❌ Error validando modo avanzado: $e');
      return ValidacionResultado(
        esValido: false,
        errores: {'general': 'Error interno de validación'},
        advertencias: {},
        sugerencias: [],
      );
    }
  }

  /// Valida un producto básico
  ValidacionResultado validarProductoBasico(ProductoCalculo producto) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    // Validar nombre
    if (producto.nombre.trim().isEmpty) {
      errores['nombre'] = 'El nombre del producto es requerido';
    } else if (producto.nombre.trim().length < 2) {
      errores['nombre'] = 'El nombre debe tener al menos 2 caracteres';
    } else if (producto.nombre.trim().length > 100) {
      errores['nombre'] = 'El nombre no puede exceder 100 caracteres';
    }

    // Validar categoría
    if (producto.categoria.trim().isEmpty) {
      errores['categoria'] = 'La categoría es requerida';
    }

    // Validar talla
    if (producto.talla.trim().isEmpty) {
      errores['talla'] = 'La talla es requerida';
    } else if (producto.talla.trim().length > 20) {
      errores['talla'] = 'La talla no puede exceder 20 caracteres';
    }

    // Validar stock
    if (producto.stock <= 0) {
      errores['stock'] = 'El stock debe ser mayor a 0';
    } else if (producto.stock > 10000) {
      advertencias['stock'] = 'Stock muy alto, considera la rotación';
    }

    // Validar descripción
    if (producto.descripcion.trim().length > 500) {
      errores['descripcion'] = 'La descripción no puede exceder 500 caracteres';
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }

  /// Valida costos directos
  ValidacionResultado validarCostosDirectos(List<CostoDirecto> costos) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    if (costos.isEmpty) {
      errores['costos_directos'] = 'Debe agregar al menos un costo directo';
      return ValidacionResultado(
        esValido: false,
        errores: errores,
        advertencias: advertencias,
        sugerencias: sugerencias,
      );
    }

    double totalCostos = 0;
    final nombres = <String>{};

    for (int i = 0; i < costos.length; i++) {
      final costo = costos[i];
      final prefijo = 'costo_directo_$i';

      // Validar nombre
      if (costo.nombre.trim().isEmpty) {
        errores['${prefijo}_nombre'] = 'El nombre del costo es requerido';
      } else if (costo.nombre.trim().length > 100) {
        errores['${prefijo}_nombre'] = 'El nombre no puede exceder 100 caracteres';
      } else if (nombres.contains(costo.nombre.trim().toLowerCase())) {
        advertencias['${prefijo}_nombre'] = 'Nombre duplicado';
      } else {
        nombres.add(costo.nombre.trim().toLowerCase());
      }

      // Validar costo total
      if (costo.costoTotal <= 0) {
        errores['${prefijo}_costo'] = 'El costo debe ser mayor a 0';
      } else if (costo.costoTotal > 50000) {
        advertencias['${prefijo}_costo'] = 'Costo muy alto, verificar';
      }

      // Validar tipo
      if (costo.tipo.trim().isEmpty) {
        errores['${prefijo}_tipo'] = 'El tipo de costo es requerido';
      }

      totalCostos += costo.costoTotal;
    }

    // Validar total de costos
    if (totalCostos > 100000) {
      advertencias['total_costos'] = 'Total de costos muy alto';
    }

    // Generar sugerencias
    if (costos.length == 1) {
      sugerencias.add('Considera agregar más costos directos para mayor precisión');
    }

    if (totalCostos < 5) {
      sugerencias.add('Verifica que todos los costos directos estén incluidos');
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }

  /// Valida costos indirectos
  ValidacionResultado validarCostosIndirectos(List<CostoIndirecto> costos) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    // Los costos indirectos son opcionales, pero si se proporcionan deben ser válidos
    if (costos.isNotEmpty) {
      double totalCostos = 0;
      final nombres = <String>{};

      for (int i = 0; i < costos.length; i++) {
        final costo = costos[i];
        final prefijo = 'costo_indirecto_$i';

        // Validar nombre
        if (costo.nombre.trim().isEmpty) {
          errores['${prefijo}_nombre'] = 'El nombre del costo es requerido';
        } else if (costo.nombre.trim().length > 100) {
          errores['${prefijo}_nombre'] = 'El nombre no puede exceder 100 caracteres';
        } else if (nombres.contains(costo.nombre.trim().toLowerCase())) {
          advertencias['${prefijo}_nombre'] = 'Nombre duplicado';
        } else {
          nombres.add(costo.nombre.trim().toLowerCase());
        }

        // Validar costo por producto
        if (costo.costoPorProducto <= 0) {
          errores['${prefijo}_costo'] = 'El costo debe ser mayor a 0';
        } else if (costo.costoPorProducto > 100000) {
          advertencias['${prefijo}_costo'] = 'Costo muy alto, verificar';
        }

        // Validar tipo
        if (costo.tipo.trim().isEmpty) {
          errores['${prefijo}_tipo'] = 'El tipo de costo es requerido';
        }

        totalCostos += costo.costoPorProducto;
      }

      // Generar sugerencias
      if (totalCostos > 0 && totalCostos < 1) {
        sugerencias.add('Los costos indirectos parecen muy bajos');
      }
    } else {
      sugerencias.add('Considera agregar costos indirectos como marketing, administración, etc.');
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }

  /// Valida configuración
  ValidacionResultado validarConfiguracion(CalculadoraConfig config) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    // Validar margen de ganancia
    if (config.margenGananciaDefault < 0) {
      errores['margen'] = 'El margen de ganancia no puede ser negativo';
    } else if (config.margenGananciaDefault > 1000) {
      errores['margen'] = 'El margen de ganancia no puede exceder 1000%';
    } else if (config.margenGananciaDefault < 10) {
      advertencias['margen'] = 'Margen muy bajo, considera costos adicionales';
    } else if (config.margenGananciaDefault > 200) {
      advertencias['margen'] = 'Margen muy alto, puede afectar competitividad';
    }

    // Validar IVA
    if (config.ivaDefault < 0) {
      errores['iva'] = 'El IVA no puede ser negativo';
    } else if (config.ivaDefault > 100) {
      errores['iva'] = 'El IVA no puede exceder 100%';
    }

    // Validar tipo de negocio
    if (config.tipoNegocio.trim().isEmpty) {
      errores['tipo_negocio'] = 'El tipo de negocio es requerido';
    }

    // Generar sugerencias
    if (config.margenGananciaDefault < 20) {
      sugerencias.add('Un margen mínimo del 20% es recomendable para cubrir gastos');
    }

    if (config.ivaDefault == 0) {
      sugerencias.add('Verifica si realmente no aplica IVA en tu región');
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }

  /// Valida coherencia general entre todos los componentes
  ValidacionResultado validarCoherenciaGeneral(
    ProductoCalculo producto,
    List<CostoDirecto> costosDirectos,
    List<CostoIndirecto> costosIndirectos,
    CalculadoraConfig config,
  ) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    // Calcular costo total
    final costoTotalDirectos = costosDirectos.fold(0.0, (sum, costo) => sum + costo.costoTotal);
    final costoTotalIndirectos = costosIndirectos.fold(0.0, (sum, costo) => sum + costo.costoPorProducto);
    final costoTotal = costoTotalDirectos + costoTotalIndirectos;

    // Validar proporción de costos
    if (costoTotalIndirectos > costoTotalDirectos * 2) {
      advertencias['proporcion_costos'] = 'Los costos indirectos son muy altos comparados con los directos';
    }

    // Validar costo mínimo
    if (costoTotal < 1) {
      advertencias['costo_minimo'] = 'El costo total es muy bajo, verificar todos los costos';
    }

    // Validar margen vs costo
    final precioMinimoEsperado = costoTotal * (1 + config.margenGananciaDefault / 100);
    if (precioMinimoEsperado < 5) {
      sugerencias.add('El precio resultante será muy bajo, considera aumentar el margen');
    }

    // Validar tipo de negocio vs categoría
    if (!_esCategoriaValidaParaTipoNegocio(producto.categoria, config.tipoNegocio)) {
      sugerencias.add('La categoría "${producto.categoria}" puede no ser apropiada para el tipo de negocio "${config.tipoNegocio}"');
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }

  /// Valida si una categoría es apropiada para un tipo de negocio
  bool _esCategoriaValidaParaTipoNegocio(String categoria, String tipoNegocio) {
    final categoriasValidas = {
      'textil': ['Camiseta', 'Pantalón', 'Vestido', 'Chaqueta', 'Ropa Interior', 'Deportiva'],
      'almacen': ['Alimentos', 'Bebidas', 'Limpieza', 'Higiene', 'Electrodomésticos'],
      'manufactura': ['Muebles', 'Decoración', 'Herramientas', 'Artesanías'],
      'servicio': ['Consultoría', 'Diseño', 'Desarrollo', 'Marketing'],
    };

    final categoriasPermitidas = categoriasValidas[tipoNegocio] ?? [];
    return categoriasPermitidas.contains(categoria) || categoria.toLowerCase() == 'general';
  }

  /// Valida un costo individual (directo o indirecto)
  ValidacionResultado validarCostoIndividual({
    required String nombre,
    required double costo,
    required String tipo,
    String? descripcion,
  }) {
    final errores = <String, String>{};
    final advertencias = <String, String>{};
    final sugerencias = <String>[];

    // Validar nombre
    if (nombre.trim().isEmpty) {
      errores['nombre'] = 'El nombre del costo es requerido';
    } else if (nombre.trim().length > 100) {
      errores['nombre'] = 'El nombre no puede exceder 100 caracteres';
    }

    // Validar costo
    if (costo <= 0) {
      errores['costo'] = 'El costo debe ser mayor a 0';
    } else if (costo > 100000) {
      advertencias['costo'] = 'Costo muy alto, verificar';
    }

    // Validar tipo
    if (tipo.trim().isEmpty) {
      errores['tipo'] = 'El tipo de costo es requerido';
    }

    // Validar descripción
    if (descripcion != null && descripcion.trim().length > 200) {
      errores['descripcion'] = 'La descripción no puede exceder 200 caracteres';
    }

    return ValidacionResultado(
      esValido: errores.isEmpty,
      errores: errores,
      advertencias: advertencias,
      sugerencias: sugerencias,
    );
  }
}
