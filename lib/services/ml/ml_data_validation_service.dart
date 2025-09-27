import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';

/// Servicio para validar datos antes de entrenar modelos ML
/// Implementa validaciones y fallbacks para datos insuficientes
class MLDataValidationService {
  static final MLDataValidationService _instance = MLDataValidationService._internal();
  factory MLDataValidationService() => _instance;
  MLDataValidationService._internal();

  // Constantes para validaciones
  static const int _minVentasParaDemanda = 5;
  static const int _minVentasParaPrecios = 10;
  static const int _minProductosParaEntrenar = 2;
  static const int _minClientesParaSegmentacion = 3;

  /// Valida si hay suficientes datos para entrenar modelos de demanda
  MLValidationResult validateDemandTrainingData(List<Venta> ventas, List<Producto> productos) {
    try {
      LoggingService.info('🔍 Validando datos para entrenamiento de demanda...');

      // Validar ventas mínimas
      if (ventas.length < _minVentasParaDemanda) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.insufficientSales,
          message: 'Se necesitan al menos $_minVentasParaDemanda ventas para entrenar el modelo de demanda',
          requiredData: _minVentasParaDemanda,
          currentData: ventas.length,
        );
      }

      // Validar productos mínimos
      if (productos.length < _minProductosParaEntrenar) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.insufficientProducts,
          message: 'Se necesitan al menos $_minProductosParaEntrenar productos para entrenar',
          requiredData: _minProductosParaEntrenar,
          currentData: productos.length,
        );
      }

      // Validar que hay productos con ventas
      final productosConVentas = productos.where((producto) {
        return ventas.any((venta) => 
          venta.items.any((item) => item.productoId == producto.id)
        );
      }).length;

      if (productosConVentas < _minProductosParaEntrenar) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.noProductSales,
          message: 'Se necesitan al menos $_minProductosParaEntrenar productos con ventas registradas',
          requiredData: _minProductosParaEntrenar,
          currentData: productosConVentas,
        );
      }

      LoggingService.info('✅ Datos válidos para entrenamiento de demanda');
      return MLValidationResult(
        isValid: true,
        message: 'Datos suficientes para entrenar modelo de demanda',
        currentData: ventas.length,
      );

    } catch (e) {
      LoggingService.error('Error validando datos de demanda: $e');
      return MLValidationResult(
        isValid: false,
        errorType: MLValidationErrorType.validationError,
        message: 'Error validando datos: $e',
      );
    }
  }

  /// Valida si hay suficientes datos para entrenar modelos de precios
  MLValidationResult validatePriceTrainingData(List<Venta> ventas, List<Producto> productos) {
    try {
      LoggingService.info('🔍 Validando datos para entrenamiento de precios...');

      // Validar ventas mínimas (más estrictas para precios)
      if (ventas.length < _minVentasParaPrecios) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.insufficientSales,
          message: 'Se necesitan al menos $_minVentasParaPrecios ventas para entrenar el modelo de precios',
          requiredData: _minVentasParaPrecios,
          currentData: ventas.length,
        );
      }

      // Validar variabilidad de precios
      final preciosUnicos = productos.map((p) => p.precioVenta).toSet().length;
      if (preciosUnicos < 2) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.noPriceVariability,
          message: 'Se necesita variabilidad en precios para entrenar el modelo',
          requiredData: 2,
          currentData: preciosUnicos,
        );
      }

      // Validar productos con diferentes precios vendidos
      final productosConPreciosVariados = productos.where((producto) {
        final ventasProducto = ventas.where((venta) => 
          venta.items.any((item) => item.productoId == producto.id)
        ).toList();
        
        if (ventasProducto.length < 3) return false;
        
        // Verificar que hay variabilidad en las ventas de este producto
        final preciosVenta = ventasProducto.map((v) => v.total).toSet();
        return preciosVenta.length > 1;
      }).length;

      if (productosConPreciosVariados < 1) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.noPriceVariability,
          message: 'Se necesitan productos con variabilidad en precios de venta',
          requiredData: 1,
          currentData: productosConPreciosVariados,
        );
      }

      LoggingService.info('✅ Datos válidos para entrenamiento de precios');
      return MLValidationResult(
        isValid: true,
        message: 'Datos suficientes para entrenar modelo de precios',
        currentData: ventas.length,
      );

    } catch (e) {
      LoggingService.error('Error validando datos de precios: $e');
      return MLValidationResult(
        isValid: false,
        errorType: MLValidationErrorType.validationError,
        message: 'Error validando datos: $e',
      );
    }
  }

  /// Valida si hay suficientes datos para segmentación de clientes
  MLValidationResult validateCustomerSegmentationData(List<Venta> ventas, List<Cliente> clientes) {
    try {
      LoggingService.info('🔍 Validando datos para segmentación de clientes...');

      // Validar clientes mínimos
      if (clientes.length < _minClientesParaSegmentacion) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.insufficientCustomers,
          message: 'Se necesitan al menos $_minClientesParaSegmentacion clientes para segmentación',
          requiredData: _minClientesParaSegmentacion,
          currentData: clientes.length,
        );
      }

      // Validar que hay clientes con múltiples compras
      final clientesConCompras = clientes.where((cliente) {
        final comprasCliente = ventas.where((v) => v.cliente == cliente.nombre).length;
        return comprasCliente >= 2;
      }).length;

      if (clientesConCompras < 2) {
        return MLValidationResult(
          isValid: false,
          errorType: MLValidationErrorType.insufficientCustomerData,
          message: 'Se necesitan al menos 2 clientes con múltiples compras para segmentación',
          requiredData: 2,
          currentData: clientesConCompras,
        );
      }

      LoggingService.info('✅ Datos válidos para segmentación de clientes');
      return MLValidationResult(
        isValid: true,
        message: 'Datos suficientes para segmentación de clientes',
        currentData: clientes.length,
      );

    } catch (e) {
      LoggingService.error('Error validando datos de clientes: $e');
      return MLValidationResult(
        isValid: false,
        errorType: MLValidationErrorType.validationError,
        message: 'Error validando datos: $e',
      );
    }
  }

  /// Genera mensaje educativo para el usuario basado en el tipo de error
  String generateEducationalMessage(MLValidationErrorType errorType, int required, int current) {
    switch (errorType) {
      case MLValidationErrorType.insufficientSales:
        return '💡 Para generar recomendaciones de demanda, necesitas registrar más ventas.\n\n'
               '• Agrega al menos $required ventas (tienes $current)\n'
               '• Registra ventas de diferentes productos\n'
               '• Incluye ventas de diferentes días\n\n'
               '¡Cada venta ayuda a la IA a aprender tus patrones de negocio!';

      case MLValidationErrorType.insufficientProducts:
        return '💡 Para entrenar la IA, necesitas más productos en tu inventario.\n\n'
               '• Agrega al menos $required productos (tienes $current)\n'
               '• Incluye productos de diferentes categorías\n'
               '• Establece precios variados\n\n'
               '¡La diversidad de productos mejora las predicciones!';

      case MLValidationErrorType.noProductSales:
        return '💡 Tus productos necesitan historial de ventas.\n\n'
               '• Registra ventas para al menos $required productos\n'
               '• Incluye diferentes cantidades vendidas\n'
               '• Agrega ventas de diferentes períodos\n\n'
               '¡Las ventas son la base para las predicciones de demanda!';

      case MLValidationErrorType.noPriceVariability:
        return '💡 Para optimizar precios, necesitas variabilidad en tus precios.\n\n'
               '• Establece diferentes precios para tus productos\n'
               '• Registra ventas con precios variados\n'
               '• Incluye promociones o descuentos\n\n'
               '¡La variabilidad de precios ayuda a encontrar el precio óptimo!';

      case MLValidationErrorType.insufficientCustomers:
        return '💡 Para segmentar clientes, necesitas más clientes registrados.\n\n'
               '• Agrega al menos $required clientes (tienes $current)\n'
               '• Registra información completa de cada cliente\n'
               '• Incluye clientes con diferentes patrones de compra\n\n'
               '¡Más clientes = mejores segmentaciones!';

      case MLValidationErrorType.insufficientCustomerData:
        return '💡 Tus clientes necesitan más historial de compras.\n\n'
               '• Registra múltiples compras por cliente\n'
               '• Incluye diferentes productos comprados\n'
               '• Agrega compras de diferentes períodos\n\n'
               '¡El historial de compras permite mejores segmentaciones!';

      case MLValidationErrorType.validationError:
        return '💡 Hubo un problema validando tus datos.\n\n'
               '• Verifica que todos los datos estén completos\n'
               '• Asegúrate de tener ventas, productos y clientes\n'
               '• Contacta soporte si el problema persiste\n\n'
               '¡Estamos aquí para ayudarte!';

      default:
        return '💡 Necesitas más datos para generar recomendaciones personalizadas.\n\n'
               '• Agrega más ventas, productos y clientes\n'
               '• Registra información completa y variada\n'
               '• ¡Cada dato mejora las predicciones de la IA!';
    }
  }

  /// Verifica si una lista está vacía antes de usar reduce
  bool canUseReduce(List<dynamic> list) {
    return list.isNotEmpty;
  }

  /// Obtiene el primer elemento de una lista de forma segura
  T? safeFirst<T>(List<T> list) {
    return list.isNotEmpty ? list.first : null;
  }

  /// Obtiene el último elemento de una lista de forma segura
  T? safeLast<T>(List<T> list) {
    return list.isNotEmpty ? list.last : null;
  }

  /// Calcula la suma de una lista de forma segura
  double safeSum(List<double> list) {
    return list.isNotEmpty ? list.reduce((a, b) => a + b) : 0.0;
  }

  /// Calcula el promedio de una lista de forma segura
  double safeAverage(List<double> list) {
    return list.isNotEmpty ? safeSum(list) / list.length : 0.0;
  }
}

/// Resultado de validación de datos ML
class MLValidationResult {
  final bool isValid;
  final MLValidationErrorType? errorType;
  final String message;
  final int? requiredData;
  final int? currentData;

  MLValidationResult({
    required this.isValid,
    this.errorType,
    required this.message,
    this.requiredData,
    this.currentData,
  });
}

/// Tipos de errores de validación
enum MLValidationErrorType {
  insufficientSales,
  insufficientProducts,
  noProductSales,
  noPriceVariability,
  insufficientCustomers,
  insufficientCustomerData,
  validationError,
}
