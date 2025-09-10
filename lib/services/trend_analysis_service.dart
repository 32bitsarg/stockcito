import '../models/venta.dart';
import '../services/database_service.dart';
import '../services/logging_service.dart';

class TrendAnalysisService {
  static final TrendAnalysisService _instance = TrendAnalysisService._internal();
  factory TrendAnalysisService() => _instance;
  TrendAnalysisService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Análisis de tendencias de ventas por producto
  Future<Map<String, dynamic>> analyzeProductTrends(int productoId, {int days = 30}) async {
    try {
      LoggingService.business('Iniciando análisis de tendencias para producto $productoId');
      
      final ventas = await _databaseService.getVentasByDateRange(
        DateTime.now().subtract(Duration(days: days)),
        DateTime.now(),
      );

      // Filtrar ventas del producto específico
      final ventasProducto = ventas.where((venta) => 
        venta.items.any((item) => item.productoId == productoId)
      ).toList();

      if (ventasProducto.isEmpty) {
        return {
          'hasData': false,
          'message': 'No hay datos suficientes para análisis',
          'trend': 'stable',
          'confidence': 0.0,
        };
      }

      // Calcular métricas básicas
      final totalVentas = ventasProducto.fold<int>(0, (sum, venta) => 
        sum + venta.items.where((item) => item.productoId == productoId)
            .fold<int>(0, (itemSum, item) => itemSum + item.cantidad)
      );

      final promedioDiario = totalVentas / days;
      final tendencia = _calculateTrend(ventasProducto, productoId);
      final confianza = _calculateConfidence(ventasProducto.length, days);

      return {
        'hasData': true,
        'totalVentas': totalVentas,
        'promedioDiario': promedioDiario,
        'trend': tendencia,
        'confidence': confianza,
        'ventasPorDia': _groupVentasByDay(ventasProducto, productoId),
        'recomendacion': _generateRecommendation(tendencia, promedioDiario, confianza),
      };
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error en análisis de tendencias de producto',
        tag: 'TREND_ANALYSIS',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  /// Análisis de tendencias generales del negocio
  Future<Map<String, dynamic>> analyzeBusinessTrends({int days = 30}) async {
    try {
      LoggingService.business('Iniciando análisis de tendencias del negocio');
      
      final ventas = await _databaseService.getVentasByDateRange(
        DateTime.now().subtract(Duration(days: days)),
        DateTime.now(),
      );

      if (ventas.isEmpty) {
        return {
          'hasData': false,
          'message': 'No hay datos suficientes para análisis',
        };
      }

      // Calcular métricas del negocio
      final totalVentas = ventas.length;
      final totalIngresos = ventas.fold<double>(0, (sum, venta) => sum + venta.total);
      final promedioVenta = totalIngresos / totalVentas;
      
      // Análisis por categoría
      final ventasPorCategoria = _groupVentasByCategory(ventas);
      final categoriaTop = _findTopCategory(ventasPorCategoria);
      
      // Análisis de tendencia temporal
      final tendenciaTemporal = _calculateTemporalTrend(ventas);
      
      // Análisis de estacionalidad
      final estacionalidad = _analyzeSeasonality(ventas);

      return {
        'hasData': true,
        'totalVentas': totalVentas,
        'totalIngresos': totalIngresos,
        'promedioVenta': promedioVenta,
        'tendenciaTemporal': tendenciaTemporal,
        'categoriaTop': categoriaTop,
        'estacionalidad': estacionalidad,
        'ventasPorDia': _groupVentasByDayGeneral(ventas),
        'recomendaciones': _generateBusinessRecommendations(
          tendenciaTemporal, 
          categoriaTop, 
          estacionalidad
        ),
      };
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error en análisis de tendencias del negocio',
        tag: 'TREND_ANALYSIS',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  /// Análisis de inventario y recomendaciones de stock
  Future<Map<String, dynamic>> analyzeInventoryTrends() async {
    try {
      LoggingService.business('Iniciando análisis de tendencias de inventario');
      
      final productos = await _databaseService.getAllProductos();

      if (productos.isEmpty) {
        return {
          'hasData': false,
          'message': 'No hay productos para analizar',
        };
      }

      final recomendaciones = <Map<String, dynamic>>[];

      for (final producto in productos) {
        final analisis = await analyzeProductTrends(producto.id!, days: 30);
        
        if (analisis['hasData'] == true) {
          final promedioDiario = analisis['promedioDiario'] as double;
          final stockActual = producto.stock;
          final diasRestantes = stockActual / promedioDiario;
          
          String recomendacion;
          String prioridad;
          
          if (diasRestantes < 7) {
            recomendacion = 'Stock crítico - Reabastecer urgentemente';
            prioridad = 'alta';
          } else if (diasRestantes < 14) {
            recomendacion = 'Stock bajo - Considerar reabastecimiento';
            prioridad = 'media';
          } else if (diasRestantes > 60) {
            recomendacion = 'Stock excesivo - Considerar promociones';
            prioridad = 'media';
          } else {
            recomendacion = 'Stock adecuado';
            prioridad = 'baja';
          }

          recomendaciones.add({
            'productoId': producto.id,
            'nombre': producto.nombre,
            'categoria': producto.categoria,
            'stockActual': stockActual,
            'promedioDiario': promedioDiario,
            'diasRestantes': diasRestantes,
            'recomendacion': recomendacion,
            'prioridad': prioridad,
            'cantidadRecomendada': _calculateRecommendedQuantity(promedioDiario, stockActual),
          });
        }
      }

      // Ordenar por prioridad
      recomendaciones.sort((a, b) {
        final prioridades = {'alta': 3, 'media': 2, 'baja': 1};
        return prioridades[b['prioridad']]!.compareTo(prioridades[a['prioridad']]!);
      });

      return {
        'hasData': true,
        'recomendaciones': recomendaciones,
        'resumen': _generateInventorySummary(recomendaciones),
      };
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error en análisis de tendencias de inventario',
        tag: 'TREND_ANALYSIS',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  /// Predicción simple de demanda para los próximos días
  Future<Map<String, dynamic>> predictDemand(int productoId, {int days = 7}) async {
    try {
      LoggingService.business('Iniciando predicción de demanda para producto $productoId');
      
      final analisis = await analyzeProductTrends(productoId, days: 30);
      
      if (analisis['hasData'] != true) {
        return {
          'hasData': false,
          'message': 'No hay datos suficientes para predicción',
        };
      }

      final promedioDiario = analisis['promedioDiario'] as double;
      final tendencia = analisis['trend'] as String;
      final confianza = analisis['confidence'] as double;

      // Ajustar predicción basada en tendencia
      double factorTendencia = 1.0;
      switch (tendencia) {
        case 'increasing':
          factorTendencia = 1.2;
          break;
        case 'decreasing':
          factorTendencia = 0.8;
          break;
        case 'stable':
        default:
          factorTendencia = 1.0;
          break;
      }

      final prediccionDiaria = promedioDiario * factorTendencia;
      final prediccionTotal = prediccionDiaria * days;

      return {
        'hasData': true,
        'prediccionDiaria': prediccionDiaria,
        'prediccionTotal': prediccionTotal,
        'confianza': confianza,
        'tendencia': tendencia,
        'factorTendencia': factorTendencia,
        'recomendacion': _generateDemandRecommendation(prediccionTotal, confianza),
      };
    } catch (e, stackTrace) {
      LoggingService.error(
        'Error en predicción de demanda',
        tag: 'TREND_ANALYSIS',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'hasData': false,
        'error': e.toString(),
      };
    }
  }

  // Métodos privados para cálculos

  String _calculateTrend(List<Venta> ventas, int productoId) {
    if (ventas.length < 3) return 'stable';

    final ventasProducto = ventas.map((venta) => 
      venta.items.where((item) => item.productoId == productoId)
          .fold<int>(0, (sum, item) => sum + item.cantidad)
    ).toList();

    // Calcular pendiente usando regresión lineal simple
    final n = ventasProducto.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = ventasProducto.map((v) => v.toDouble()).toList();

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = x.asMap().entries.fold<double>(0, (sum, entry) => 
      sum + entry.value * y[entry.key]);
    final sumXX = x.fold<double>(0, (sum, x) => sum + x * x);

    final pendiente = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);

    if (pendiente > 0.1) return 'increasing';
    if (pendiente < -0.1) return 'decreasing';
    return 'stable';
  }

  double _calculateConfidence(int dataPoints, int totalDays) {
    if (dataPoints == 0) return 0.0;
    
    final coverage = dataPoints / totalDays;
    final minConfidence = 0.3;
    final maxConfidence = 0.95;
    
    return (minConfidence + (coverage * (maxConfidence - minConfidence))).clamp(0.0, 1.0);
  }

  Map<String, int> _groupVentasByDay(List<Venta> ventas, int productoId) {
    final Map<String, int> ventasPorDia = {};
    
    for (final venta in ventas) {
      final fecha = venta.fecha.toIso8601String().split('T')[0];
      final cantidad = venta.items
          .where((item) => item.productoId == productoId)
          .fold<int>(0, (sum, item) => sum + item.cantidad);
      
      ventasPorDia[fecha] = (ventasPorDia[fecha] ?? 0) + cantidad;
    }
    
    return ventasPorDia;
  }

  Map<String, int> _groupVentasByDayGeneral(List<Venta> ventas) {
    final Map<String, int> ventasPorDia = {};
    
    for (final venta in ventas) {
      final fecha = venta.fecha.toIso8601String().split('T')[0];
      ventasPorDia[fecha] = (ventasPorDia[fecha] ?? 0) + 1;
    }
    
    return ventasPorDia;
  }

  Map<String, int> _groupVentasByCategory(List<Venta> ventas) {
    final Map<String, int> ventasPorCategoria = {};
    
    for (final venta in ventas) {
      for (final item in venta.items) {
        ventasPorCategoria[item.categoria] = 
            (ventasPorCategoria[item.categoria] ?? 0) + item.cantidad;
      }
    }
    
    return ventasPorCategoria;
  }

  String _findTopCategory(Map<String, int> ventasPorCategoria) {
    if (ventasPorCategoria.isEmpty) return 'Sin datos';
    
    return ventasPorCategoria.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String _calculateTemporalTrend(List<Venta> ventas) {
    if (ventas.length < 3) return 'stable';

    // Dividir en dos períodos
    final mitad = ventas.length ~/ 2;
    final primeraMitad = ventas.take(mitad).fold<double>(0, (sum, v) => sum + v.total);
    final segundaMitad = ventas.skip(mitad).fold<double>(0, (sum, v) => sum + v.total);
    
    final promedioPrimera = primeraMitad / mitad;
    final promedioSegunda = segundaMitad / (ventas.length - mitad);
    
    final cambio = (promedioSegunda - promedioPrimera) / promedioPrimera;
    
    if (cambio > 0.1) return 'increasing';
    if (cambio < -0.1) return 'decreasing';
    return 'stable';
  }

  Map<String, dynamic> _analyzeSeasonality(List<Venta> ventas) {
    final Map<int, List<double>> ventasPorMes = {};
    
    for (final venta in ventas) {
      final mes = venta.fecha.month;
      ventasPorMes[mes] = ventasPorMes[mes] ?? [];
      ventasPorMes[mes]!.add(venta.total);
    }
    
    final Map<String, double> promediosPorMes = {};
    for (final entry in ventasPorMes.entries) {
      promediosPorMes[_getMonthName(entry.key)] = 
          entry.value.reduce((a, b) => a + b) / entry.value.length;
    }
    
    return promediosPorMes;
  }

  String _getMonthName(int month) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[month - 1];
  }

  String _generateRecommendation(String trend, double promedioDiario, double confidence) {
    if (confidence < 0.5) {
      return 'Datos insuficientes para recomendación confiable';
    }
    
    switch (trend) {
      case 'increasing':
        return 'Tendencia al alza - Considerar aumentar stock y promocionar';
      case 'decreasing':
        return 'Tendencia a la baja - Revisar estrategia de marketing';
      case 'stable':
      default:
        return 'Tendencia estable - Mantener estrategia actual';
    }
  }

  List<String> _generateBusinessRecommendations(String tendenciaTemporal, String categoriaTop, Map<String, dynamic> estacionalidad) {
    final recomendaciones = <String>[];
    
    switch (tendenciaTemporal) {
      case 'increasing':
        recomendaciones.add('Negocio en crecimiento - Considerar expansión');
        break;
      case 'decreasing':
        recomendaciones.add('Negocio en declive - Revisar estrategia general');
        break;
      case 'stable':
      default:
        recomendaciones.add('Negocio estable - Buscar oportunidades de crecimiento');
        break;
    }
    
    recomendaciones.add('Categoría más vendida: $categoriaTop - Enfocar esfuerzos');
    
    if (estacionalidad.isNotEmpty) {
      final mesTop = estacionalidad.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      recomendaciones.add('Mejor mes: $mesTop - Preparar estrategias estacionales');
    }
    
    return recomendaciones;
  }

  int _calculateRecommendedQuantity(double promedioDiario, int stockActual) {
    final diasObjetivo = 30; // Mantener stock para 30 días
    final cantidadObjetivo = (promedioDiario * diasObjetivo).round();
    final cantidadRecomendada = cantidadObjetivo - stockActual;
    
    return cantidadRecomendada.clamp(0, cantidadObjetivo);
  }

  Map<String, dynamic> _generateInventorySummary(List<Map<String, dynamic>> recomendaciones) {
    final criticos = recomendaciones.where((r) => r['prioridad'] == 'alta').length;
    final bajos = recomendaciones.where((r) => r['prioridad'] == 'media').length;
    final adecuados = recomendaciones.where((r) => r['prioridad'] == 'baja').length;
    
    return {
      'totalProductos': recomendaciones.length,
      'stockCritico': criticos,
      'stockBajo': bajos,
      'stockAdecuado': adecuados,
      'porcentajeCritico': recomendaciones.isEmpty ? 0.0 : (criticos / recomendaciones.length * 100),
    };
  }

  String _generateDemandRecommendation(double prediccionTotal, double confianza) {
    if (confianza < 0.5) {
      return 'Predicción con baja confianza - Usar con precaución';
    }
    
    if (prediccionTotal > 50) {
      return 'Alta demanda esperada - Preparar stock adicional';
    } else if (prediccionTotal < 10) {
      return 'Baja demanda esperada - Considerar promociones';
    } else {
      return 'Demanda moderada - Mantener stock actual';
    }
  }
}
