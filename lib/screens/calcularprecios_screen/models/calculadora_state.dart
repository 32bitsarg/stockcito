import 'calculadora_config.dart';
import 'producto_calculo.dart';
import 'costo_directo.dart';
import 'costo_indirecto.dart';

/// Estado global de la calculadora de precios
class CalculadoraState {
  final CalculadoraConfig config;
  final ProductoCalculo producto;
  final List<CostoDirecto> costosDirectos;
  final List<CostoIndirecto> costosIndirectos;
  final int pasoActual;
  final bool isLoading;
  final String? error;
  final bool hasChanges;

  const CalculadoraState({
    required this.config,
    required this.producto,
    required this.costosDirectos,
    required this.costosIndirectos,
    this.pasoActual = 0,
    this.isLoading = false,
    this.error,
    this.hasChanges = false,
  });

  /// Estado inicial
  factory CalculadoraState.initial(CalculadoraConfig config) {
    return CalculadoraState(
      config: config,
      producto: ProductoCalculo.empty(),
      costosDirectos: [],
      costosIndirectos: [],
      pasoActual: 0,
    );
  }

  /// Crea una copia con nuevos valores
  CalculadoraState copyWith({
    CalculadoraConfig? config,
    ProductoCalculo? producto,
    List<CostoDirecto>? costosDirectos,
    List<CostoIndirecto>? costosIndirectos,
    int? pasoActual,
    bool? isLoading,
    String? error,
    bool? hasChanges,
  }) {
    return CalculadoraState(
      config: config ?? this.config,
      producto: producto ?? this.producto,
      costosDirectos: costosDirectos ?? this.costosDirectos,
      costosIndirectos: costosIndirectos ?? this.costosIndirectos,
      pasoActual: pasoActual ?? this.pasoActual,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasChanges: hasChanges ?? this.hasChanges,
    );
  }

  /// Calcula el total de costos directos
  double get totalCostosDirectos {
    return costosDirectos.fold(0.0, (sum, costo) => sum + costo.costoTotal);
  }

  /// Calcula el total de costos indirectos
  double get totalCostosIndirectos {
    return costosIndirectos.fold(0.0, (sum, costo) => sum + costo.costoPorProducto);
  }

  /// Calcula el costo total
  double get costoTotal {
    return totalCostosDirectos + totalCostosIndirectos;
  }

  /// Calcula el precio final
  double get precioFinal {
    if (config.modoAvanzado) {
      final margen = config.margenGananciaDefault / 100;
      final iva = config.ivaDefault / 100;
      return costoTotal * (1 + margen) * (1 + iva);
    } else {
      return producto.precioVenta ?? 0.0;
    }
  }

  /// Calcula la ganancia
  double get ganancia {
    return precioFinal - costoTotal;
  }

  /// Calcula el porcentaje de ganancia
  double get porcentajeGanancia {
    if (costoTotal > 0) {
      return (ganancia / costoTotal) * 100;
    }
    return 0.0;
  }

  /// Verifica si se puede avanzar al siguiente paso
  bool canGoToNextStep() {
    switch (pasoActual) {
      case 0: // Configuración
        return config.tipoNegocio.isNotEmpty;
      case 1: // Información del producto
        return producto.nombre.isNotEmpty && 
               producto.categoria.isNotEmpty && 
               producto.talla.isNotEmpty;
      case 2: // Costos directos
        if (config.modoAvanzado) {
          return costosDirectos.isNotEmpty;
        }
        return true;
      case 3: // Costos indirectos
        if (config.modoAvanzado) {
          return costosIndirectos.isNotEmpty;
        }
        return true;
      case 4: // Resultado final
        return true;
      default:
        return false;
    }
  }

  /// Verifica si se puede retroceder
  bool canGoToPreviousStep() {
    return pasoActual > 0;
  }

  /// Verifica si el cálculo está completo
  bool get isComplete {
    if (config.modoAvanzado) {
      return config.tipoNegocio.isNotEmpty &&
             producto.nombre.isNotEmpty && 
             costosDirectos.isNotEmpty && 
             costosIndirectos.isNotEmpty;
    } else {
      return config.tipoNegocio.isNotEmpty &&
             producto.nombre.isNotEmpty && 
             producto.precioVenta != null && 
             producto.precioVenta! > 0;
    }
  }

  /// Obtiene el progreso como porcentaje
  double get progreso {
    if (config.modoAvanzado) {
      return (pasoActual + 1) / 5; // 5 pasos en modo avanzado
    } else {
      return (pasoActual + 1) / 3; // 3 pasos en modo simple
    }
  }

  /// Obtiene el título del paso actual
  String get tituloPasoActual {
    switch (pasoActual) {
      case 0:
        return 'Configuración';
      case 1:
        return 'Información del Producto';
      case 2:
        return config.modoAvanzado ? 'Costos Directos' : 'Precio de Venta';
      case 3:
        return config.modoAvanzado ? 'Costos Indirectos' : 'Resultado Final';
      case 4:
        return 'Resultado Final';
      default:
        return 'Calculadora de Precios';
    }
  }

  /// Obtiene la descripción del paso actual
  String get descripcionPasoActual {
    switch (pasoActual) {
      case 0:
        return 'Configura el modo de cálculo y el tipo de negocio';
      case 1:
        return 'Completa la información básica de tu producto';
      case 2:
        return config.modoAvanzado 
            ? 'Agrega los costos directos (materiales, mano de obra)'
            : 'Ingresa el precio de venta deseado';
      case 3:
        return config.modoAvanzado 
            ? 'Configura los costos indirectos (gastos fijos)'
            : 'Revisa el resultado final y guarda tu producto';
      case 4:
        return 'Revisa el análisis completo y guarda tu producto';
      default:
        return 'Calculadora de precios inteligente';
    }
  }
}
