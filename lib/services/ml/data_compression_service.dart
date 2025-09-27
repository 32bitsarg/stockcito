import 'dart:convert';
import 'dart:math';
import '../system/logging_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';

/// Servicio para comprimir datos antes de enviar a Supabase
/// Optimiza el uso del plan gratuito reduciendo el tamaño de los datos
class DataCompressionService {
  static final DataCompressionService _instance = DataCompressionService._internal();
  factory DataCompressionService() => _instance;
  DataCompressionService._internal();

  /// Comprime datos de productos para entrenamiento
  Map<String, dynamic> compressProductData(Producto producto) {
    try {
      // Solo enviar features esenciales para reducir tamaño
      return {
        'id': producto.id,
        'features': {
          'costo_total': _roundToDecimals(producto.costoTotal, 2),
          'margen': _roundToDecimals(producto.margenGanancia, 1),
          'stock': producto.stock,
          'categoria': _encodeCategory(producto.categoria),
          'talla': _encodeTalla(producto.talla),
        },
        'target': _roundToDecimals(producto.precioVenta, 2),
        'timestamp': _compressTimestamp(producto.fechaCreacion),
      };
    } catch (e) {
      LoggingService.error('Error comprimiendo datos de producto: $e');
      return {};
    }
  }

  /// Comprime datos de ventas para entrenamiento
  Map<String, dynamic> compressSalesData(Venta venta) {
    try {
      // Agregar datos de ventas para reducir tamaño
      final totalItems = venta.items.fold(0, (sum, item) => sum + item.cantidad);
      final avgPrice = venta.total / totalItems;
      
      return {
        'id': venta.id,
        'features': {
          'total_items': totalItems,
          'avg_price': _roundToDecimals(avgPrice, 2),
          'hour': venta.fecha.hour,
          'day_of_week': venta.fecha.weekday,
          'payment_method': _encodePaymentMethod(venta.metodoPago),
        },
        'target': _roundToDecimals(venta.total, 2),
        'timestamp': _compressTimestamp(venta.fecha),
      };
    } catch (e) {
      LoggingService.error('Error comprimiendo datos de venta: $e');
      return {};
    }
  }

  /// Comprime datos de clientes para entrenamiento
  Map<String, dynamic> compressCustomerData(Cliente cliente) {
    try {
      // Solo enviar métricas agregadas, no datos personales
      return {
        'id': cliente.id,
        'features': {
          'has_phone': cliente.telefono.isNotEmpty ? 1 : 0,
          'has_email': cliente.email.isNotEmpty ? 1 : 0,
          'has_address': cliente.direccion.isNotEmpty ? 1 : 0,
          'data_completeness': _calculateDataCompleteness(cliente),
        },
        'target': 1.0, // Cliente válido
        'timestamp': _compressTimestamp(DateTime.now()),
      };
    } catch (e) {
      LoggingService.error('Error comprimiendo datos de cliente: $e');
      return {};
    }
  }

  /// Genera datos agregados comprimidos para usuarios anónimos
  Map<String, dynamic> generateCompressedAggregatedData(
    List<Producto> productos, 
    List<Venta> ventas
  ) {
    try {
      // Calcular estadísticas agregadas comprimidas
      final totalProducts = productos.length;
      final totalSales = ventas.length;
      
      // Calcular estadísticas de precios comprimidas
      final prices = ventas.map((v) => v.total).toList();
      final priceStats = _calculateCompressedPriceStats(prices);
      
      // Calcular estadísticas de categorías comprimidas
      final categoryStats = _calculateCompressedCategoryStats(productos);
      
      // Calcular patrones temporales comprimidos
      final temporalStats = _calculateCompressedTemporalStats(ventas);
      
      return {
        'data_type': 'aggregated_compressed',
        'stats': {
          'total_products': totalProducts,
          'total_sales': totalSales,
          'price_stats': priceStats,
          'category_stats': categoryStats,
          'temporal_stats': temporalStats,
        },
        'timestamp': _compressTimestamp(DateTime.now()),
        'compression_ratio': _calculateCompressionRatio(productos, ventas),
      };
    } catch (e) {
      LoggingService.error('Error generando datos agregados comprimidos: $e');
      return {};
    }
  }

  /// Comprime un lote de datos de entrenamiento
  List<Map<String, dynamic>> compressTrainingBatch(
    List<Map<String, dynamic>> rawData,
    {int maxSize = 100}
  ) {
    try {
      if (rawData.length <= maxSize) {
        return rawData.map((data) => _compressGenericData(data)).toList();
      }
      
      // Si hay muchos datos, muestrear y comprimir
      final sampledData = _sampleData(rawData, maxSize);
      return sampledData.map((data) => _compressGenericData(data)).toList();
    } catch (e) {
      LoggingService.error('Error comprimiendo lote de datos: $e');
      return [];
    }
  }

  /// Calcula el ratio de compresión logrado
  double calculateCompressionRatio(
    List<Map<String, dynamic>> originalData,
    List<Map<String, dynamic>> compressedData
  ) {
    try {
      final originalSize = _estimateDataSize(originalData);
      final compressedSize = _estimateDataSize(compressedData);
      
      if (originalSize == 0) return 1.0;
      
      return compressedSize / originalSize;
    } catch (e) {
      LoggingService.error('Error calculando ratio de compresión: $e');
      return 1.0;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Redondea un número a un número específico de decimales
  double _roundToDecimals(double value, int decimals) {
    final multiplier = pow(10, decimals);
    return (value * multiplier).round() / multiplier;
  }

  /// Codifica categorías a números para reducir tamaño
  int _encodeCategory(String categoria) {
    const categoryMap = {
      'Bodies': 1,
      'Conjuntos': 2,
      'Vestidos': 3,
      'Pijamas': 4,
      'Gorros': 5,
      'Accesorios': 6,
    };
    return categoryMap[categoria] ?? 0;
  }

  /// Codifica tallas a números para reducir tamaño
  int _encodeTalla(String talla) {
    const tallaMap = {
      'XS': 1,
      'S': 2,
      'M': 3,
      'L': 4,
      'XL': 5,
      'XXL': 6,
    };
    return tallaMap[talla] ?? 0;
  }

  /// Codifica método de pago a números
  int _encodePaymentMethod(String metodo) {
    const methodMap = {
      'Efectivo': 1,
      'Tarjeta': 2,
      'Transferencia': 3,
      'Mercado Pago': 4,
    };
    return methodMap[metodo] ?? 0;
  }

  /// Comprime timestamp a formato más pequeño
  String _compressTimestamp(DateTime dateTime) {
    // Usar timestamp Unix en segundos en lugar de ISO string
    return (dateTime.millisecondsSinceEpoch / 1000).round().toString();
  }

  /// Calcula completitud de datos del cliente
  double _calculateDataCompleteness(Cliente cliente) {
    int fields = 0;
    int totalFields = 4;
    
    if (cliente.nombre.isNotEmpty) fields++;
    if (cliente.telefono.isNotEmpty) fields++;
    if (cliente.email.isNotEmpty) fields++;
    if (cliente.direccion.isNotEmpty) fields++;
    
    return fields / totalFields;
  }

  /// Calcula estadísticas de precios comprimidas
  Map<String, dynamic> _calculateCompressedPriceStats(List<double> prices) {
    if (prices.isEmpty) return {};
    
    prices.sort();
    
    return {
      'min': _roundToDecimals(prices.first, 2),
      'max': _roundToDecimals(prices.last, 2),
      'median': _roundToDecimals(prices[prices.length ~/ 2], 2),
      'q1': _roundToDecimals(prices[prices.length ~/ 4], 2),
      'q3': _roundToDecimals(prices[3 * prices.length ~/ 4], 2),
    };
  }

  /// Calcula estadísticas de categorías comprimidas
  Map<String, dynamic> _calculateCompressedCategoryStats(List<Producto> productos) {
    final categoryCount = <String, int>{};
    for (final producto in productos) {
      categoryCount[producto.categoria] = (categoryCount[producto.categoria] ?? 0) + 1;
    }
    
    // Solo mantener las categorías más importantes
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return {
      'top_categories': sortedCategories.take(3).map((e) => {
        'category': e.key,
        'count': e.value,
      }).toList(),
    };
  }

  /// Calcula estadísticas temporales comprimidas
  Map<String, dynamic> _calculateCompressedTemporalStats(List<Venta> ventas) {
    if (ventas.isEmpty) return {};
    
    final hourlySales = List.filled(24, 0);
    final dailySales = List.filled(7, 0);
    
    for (final venta in ventas) {
      hourlySales[venta.fecha.hour]++;
      dailySales[venta.fecha.weekday - 1]++;
    }
    
    return {
      'peak_hour': hourlySales.indexOf(hourlySales.reduce(max)),
      'peak_day': dailySales.indexOf(dailySales.reduce(max)) + 1,
      'total_hours_active': hourlySales.where((h) => h > 0).length,
    };
  }

  /// Muestrea datos para reducir tamaño
  List<Map<String, dynamic>> _sampleData(
    List<Map<String, dynamic>> data, 
    int maxSize
  ) {
    if (data.length <= maxSize) return data;
    
    // Muestreo estratificado: tomar datos recientes y algunos históricos
    final recentData = data.take(maxSize ~/ 2).toList();
    final historicalData = data.skip(data.length - maxSize ~/ 2).toList();
    
    return [...recentData, ...historicalData];
  }

  /// Comprime datos genéricos
  Map<String, dynamic> _compressGenericData(Map<String, dynamic> data) {
    final compressed = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is double) {
        compressed[key] = _roundToDecimals(value, 2);
      } else if (value is String && value.length > 50) {
        compressed[key] = value.substring(0, 50); // Truncar strings largos
      } else {
        compressed[key] = value;
      }
    }
    
    return compressed;
  }

  /// Estima el tamaño de los datos en bytes
  int _estimateDataSize(List<Map<String, dynamic>> data) {
    try {
      final jsonString = jsonEncode(data);
      return jsonString.length;
    } catch (e) {
      return 0;
    }
  }

  /// Calcula el ratio de compresión para datos agregados
  double _calculateCompressionRatio(List<Producto> productos, List<Venta> ventas) {
    // Estimación del ratio de compresión basado en la cantidad de datos
    final totalRecords = productos.length + ventas.length;
    
    if (totalRecords < 100) return 0.8; // 20% de compresión
    if (totalRecords < 500) return 0.6; // 40% de compresión
    if (totalRecords < 1000) return 0.4; // 60% de compresión
    return 0.3; // 70% de compresión para datasets grandes
  }
}
