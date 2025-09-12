import 'dart:convert';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/services/supabase_auth_service.dart';
import 'package:ricitosdebb/services/datos/datos.dart';
import 'package:ricitosdebb/models/producto.dart';
import 'package:ricitosdebb/models/venta.dart';
import 'package:ricitosdebb/models/cliente.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio unificado de entrenamiento de ML que funciona tanto local como remotamente
class MLTrainingService {
  static final MLTrainingService _instance = MLTrainingService._internal();
  factory MLTrainingService() => _instance;
  MLTrainingService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  DatosService? _datosService;
  final SupabaseClient _supabase = Supabase.instance.client;

  // Configuración de consentimiento para datos anónimos
  static const String _consentKey = 'ml_data_sharing_consent';
  static const String _lastTrainingKey = 'last_ml_training';

  /// Inicializa el servicio de ML training
  void initializeDatosService(DatosService datosService) {
    _datosService = datosService;
  }

  /// Inicializa el servicio de ML training
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando MLTrainingService...');
      
      // Verificar si el usuario ha dado consentimiento para compartir datos
      final hasConsent = await _hasDataSharingConsent();
      
      if (hasConsent) {
        LoggingService.info('Usuario ha dado consentimiento para compartir datos ML');
        await _trainWithAllData();
      } else {
        LoggingService.info('Entrenando solo con datos locales');
        await _trainWithLocalData();
      }
      
      LoggingService.info('MLTrainingService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando MLTrainingService: $e');
    }
  }

  /// Entrena la IA con todos los datos disponibles (local + remoto si es posible)
  Future<void> _trainWithAllData() async {
    try {
      LoggingService.info('Iniciando entrenamiento con todos los datos disponibles...');
      
      // 1. Entrenar con datos locales (siempre disponible)
      await _trainWithLocalData();
      
      // 2. Si el usuario está autenticado y hay internet, entrenar con datos remotos
      if (_authService.isSignedIn && !_authService.isAnonymous) {
        await _trainWithRemoteData();
      }
      
      // 3. Si es usuario anónimo con consentimiento, enviar datos agregados
      if (_authService.isAnonymous && await _hasDataSharingConsent()) {
        await _sendAnonymousAggregatedData();
      }
      
      LoggingService.info('Entrenamiento completo finalizado');
    } catch (e) {
      LoggingService.error('Error en entrenamiento completo: $e');
      // Fallback a entrenamiento local
      await _trainWithLocalData();
    }
  }

  /// Entrena la IA solo con datos locales
  Future<void> _trainWithLocalData() async {
    try {
      LoggingService.info('Iniciando entrenamiento local...');
      
      // Obtener todos los datos locales
      if (_datosService == null) {
        LoggingService.warning('DatosService no inicializado en MLTrainingService');
        return;
      }
      
      final productos = await _datosService!.getAllProductos();
      final ventas = await _datosService!.getAllVentas();
      final clientes = await _datosService!.getAllClientes();
      
      LoggingService.info('Datos locales: ${productos.length} productos, ${ventas.length} ventas, ${clientes.length} clientes');
      
      // Generar datos de entrenamiento locales
      final localTrainingData = <Map<String, dynamic>>[];
      
      // Datos de productos
      for (final producto in productos) {
        localTrainingData.add(_generateProductTrainingData(producto));
      }
      
      // Datos de ventas
      for (final venta in ventas) {
        final salesData = _generateSalesTrainingData(venta);
        if (salesData != null) {
          localTrainingData.add(salesData);
        }
      }
      
      // Datos de clientes
      for (final cliente in clientes) {
        final customerData = _generateCustomerTrainingData(cliente);
        if (customerData != null) {
          localTrainingData.add(customerData);
        }
      }
      
      // Guardar datos de entrenamiento localmente
      await _saveLocalTrainingData(localTrainingData);
      
      // Actualizar timestamp del último entrenamiento
      await _updateLastTrainingTime();
      
      LoggingService.info('Entrenamiento local completado con ${localTrainingData.length} registros');
    } catch (e) {
      LoggingService.error('Error en entrenamiento local: $e');
    }
  }

  /// Entrena la IA con datos remotos de Supabase
  Future<void> _trainWithRemoteData() async {
    try {
      LoggingService.info('Iniciando entrenamiento remoto...');
      
      // Obtener datos de Supabase
      final productos = await _getRemoteProductos();
      final ventas = await _getRemoteVentas();
      final clientes = await _getRemoteClientes();
      
      LoggingService.info('Datos remotos: ${productos.length} productos, ${ventas.length} ventas, ${clientes.length} clientes');
      
      // Generar datos de entrenamiento remotos
      final remoteTrainingData = <Map<String, dynamic>>[];
      
      for (final producto in productos) {
        remoteTrainingData.add(_generateProductTrainingData(producto));
      }
      
      for (final venta in ventas) {
        final salesData = _generateSalesTrainingData(venta);
        if (salesData != null) {
          remoteTrainingData.add(salesData);
        }
      }
      
      for (final cliente in clientes) {
        final customerData = _generateCustomerTrainingData(cliente);
        if (customerData != null) {
          remoteTrainingData.add(customerData);
        }
      }
      
      // Guardar en Supabase ML training
      await _saveRemoteTrainingData(remoteTrainingData);
      
      LoggingService.info('Entrenamiento remoto completado con ${remoteTrainingData.length} registros');
    } catch (e) {
      LoggingService.warning('Error en entrenamiento remoto (RLS): $e');
      LoggingService.info('Continuando con entrenamiento local únicamente...');
      // No re-lanzar el error, solo continuar con entrenamiento local
    }
  }

  /// Envía datos agregados anónimos para mejorar el modelo global
  Future<void> _sendAnonymousAggregatedData() async {
    try {
      LoggingService.info('Enviando datos agregados anónimos...');
      
      // Obtener datos locales
      if (_datosService == null) {
        LoggingService.warning('DatosService no inicializado en MLTrainingService');
        return;
      }
      
      final productos = await _datosService!.getAllProductos();
      final ventas = await _datosService!.getAllVentas();
      
      // Generar datos agregados (sin información personal)
      final aggregatedData = _generateAggregatedData(productos, ventas);
      
      // Enviar a Supabase (si las políticas RLS lo permiten)
      await _saveAggregatedData(aggregatedData);
      
      LoggingService.info('Datos agregados anónimos enviados correctamente');
    } catch (e) {
      LoggingService.warning('Error enviando datos agregados (RLS): $e');
      LoggingService.info('Continuando sin datos agregados...');
      // No re-lanzar el error
    }
  }

  /// Genera datos de entrenamiento para un producto
  Map<String, dynamic> _generateProductTrainingData(Producto producto) {
    return {
      'user_id': _authService.currentUserId, // UUID o null
      'features': {
        'costo_materiales': producto.costoMateriales,
        'costo_mano_obra': producto.costoManoObra,
        'gastos_generales': producto.gastosGenerales,
        'margen_ganancia': producto.margenGanancia,
        'stock': producto.stock,
        'categoria': producto.categoria,
        'talla': producto.talla,
        'data_type': 'product',
      },
      'target': producto.precioVenta,
      'model_type': 'product_training',
      'timestamp': producto.fechaCreacion.toIso8601String(),
      'is_anonymous': _authService.isAnonymous,
    };
  }

  /// Genera datos de entrenamiento para una venta
  Map<String, dynamic>? _generateSalesTrainingData(Venta venta) {
    try {
      return {
        'user_id': _authService.currentUserId, // UUID o null
        'features': {
          'total': venta.total,
          'hora': venta.fecha.hour,
          'dia_semana': venta.fecha.weekday,
          'cantidad_items': venta.items.length,
          'metodo_pago': venta.metodoPago,
          'estado': venta.estado,
          'data_type': 'sale',
        },
        'target': 1.0, // Venta exitosa
        'model_type': 'sales_training',
        'timestamp': venta.fecha.toIso8601String(),
        'is_anonymous': _authService.isAnonymous,
      };
    } catch (e) {
      LoggingService.error('Error generando datos de venta: $e');
      return null;
    }
  }

  /// Genera datos de entrenamiento para un cliente
  Map<String, dynamic>? _generateCustomerTrainingData(Cliente cliente) {
    try {
      return {
        'user_id': _authService.currentUserId, // UUID o null
        'features': {
          'longitud_telefono': cliente.telefono.length,
          'longitud_email': cliente.email.length,
          'longitud_direccion': cliente.direccion.length,
          'tiene_telefono': cliente.telefono.isNotEmpty,
          'tiene_email': cliente.email.isNotEmpty,
          'tiene_direccion': cliente.direccion.isNotEmpty,
          'data_type': 'customer',
        },
        'target': _calculateCustomerScore(cliente),
        'model_type': 'customer_training',
        'timestamp': DateTime.now().toIso8601String(),
        'is_anonymous': _authService.isAnonymous,
      };
    } catch (e) {
      LoggingService.error('Error generando datos de cliente: $e');
      return null;
    }
  }

  /// Genera datos agregados anónimos
  Map<String, dynamic> _generateAggregatedData(List<Producto> productos, List<Venta> ventas) {
    // Calcular estadísticas agregadas sin información personal
    final totalProductos = productos.length;
    final totalVentas = ventas.length;
    final promedioPrecio = ventas.isNotEmpty 
        ? ventas.map((v) => v.total).reduce((a, b) => a + b) / ventas.length 
        : 0.0;
    
    final categorias = productos.map((p) => p.categoria).toSet().toList();
    final tallas = productos.map((p) => p.talla).toSet().toList();
    
    return {
      'data_type': 'aggregated',
      'aggregated_features': {
        'total_products': totalProductos,
        'total_sales': totalVentas,
        'average_price': promedioPrecio,
        'categories': categorias,
        'sizes': tallas,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Calcula el score de un cliente basado en completitud de datos
  double _calculateCustomerScore(Cliente cliente) {
    int score = 0;
    int maxScore = 4;
    
    if (cliente.nombre.isNotEmpty) score++;
    if (cliente.telefono.isNotEmpty) score++;
    if (cliente.email.isNotEmpty) score++;
    if (cliente.direccion.isNotEmpty) score++;
    
    return score / maxScore.toDouble();
  }

  /// Guarda datos de entrenamiento localmente
  Future<void> _saveLocalTrainingData(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data);
      await prefs.setString('local_ml_training_data', jsonData);
      LoggingService.info('Datos de entrenamiento local guardados: ${data.length} registros');
    } catch (e) {
      LoggingService.error('Error guardando datos de entrenamiento local: $e');
    }
  }

  /// Guarda datos de entrenamiento en Supabase
  Future<void> _saveRemoteTrainingData(List<Map<String, dynamic>> data) async {
    try {
      // Insertar todos los datos en una sola operación
      await _supabase
          .from('ml_training_data')
          .insert(data);
      LoggingService.info('Datos de entrenamiento remoto guardados: ${data.length} registros');
    } catch (e) {
      LoggingService.warning('Error guardando datos de entrenamiento remoto (RLS): $e');
      LoggingService.info('Intentando guardar individualmente...');
      
      // Intentar guardar uno por uno
      int successCount = 0;
      for (final record in data) {
        try {
          await _supabase
              .from('ml_training_data')
              .insert(record);
          successCount++;
        } catch (individualError) {
          LoggingService.warning('Error guardando registro individual: $individualError');
        }
      }
      
      if (successCount > 0) {
        LoggingService.info('Guardados $successCount de ${data.length} registros en Supabase');
      } else {
        LoggingService.info('Guardando todos los datos localmente como respaldo...');
        await _saveLocalTrainingData(data);
      }
    }
  }

  /// Guarda datos agregados en Supabase
  Future<void> _saveAggregatedData(Map<String, dynamic> data) async {
    try {
      await _supabase
          .from('ml_aggregated_data')
          .insert(data);
      LoggingService.info('Datos agregados guardados correctamente');
    } catch (e) {
      LoggingService.warning('Error guardando datos agregados (RLS): $e');
      LoggingService.info('Continuando sin datos agregados...');
    }
  }

  /// Obtiene productos remotos de Supabase
  Future<List<Producto>> _getRemoteProductos() async {
    try {
      final response = await _supabase
          .from('productos')
          .select()
          .eq('user_id', _authService.currentUserId!);
      
      return response.map((json) => Producto.fromMap(json)).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo productos remotos: $e');
      return [];
    }
  }

  /// Obtiene ventas remotas de Supabase
  Future<List<Venta>> _getRemoteVentas() async {
    try {
      final response = await _supabase
          .from('ventas')
          .select()
          .eq('user_id', _authService.currentUserId!);
      
      return response.map((json) => Venta.fromMap(json)).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo ventas remotas: $e');
      return [];
    }
  }

  /// Obtiene clientes remotos de Supabase
  Future<List<Cliente>> _getRemoteClientes() async {
    try {
      final response = await _supabase
          .from('clientes')
          .select()
          .eq('user_id', _authService.currentUserId!);
      
      return response.map((json) => Cliente.fromMap(json)).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo clientes remotos: $e');
      return [];
    }
  }

  /// Verifica si el usuario ha dado consentimiento para compartir datos
  Future<bool> _hasDataSharingConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_consentKey) ?? false;
    } catch (e) {
      LoggingService.error('Error verificando consentimiento: $e');
      return false;
    }
  }

  /// Establece el consentimiento del usuario para compartir datos
  Future<void> setDataSharingConsent(bool consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentKey, consent);
      LoggingService.info('Consentimiento de datos actualizado: $consent');
      
      // Si el usuario da consentimiento, entrenar con todos los datos
      if (consent) {
        await _trainWithAllData();
      }
    } catch (e) {
      LoggingService.error('Error estableciendo consentimiento: $e');
    }
  }

  /// Actualiza el timestamp del último entrenamiento
  Future<void> _updateLastTrainingTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastTrainingKey, DateTime.now().toIso8601String());
    } catch (e) {
      LoggingService.error('Error actualizando timestamp de entrenamiento: $e');
    }
  }

  /// Obtiene estadísticas del entrenamiento
  Future<Map<String, dynamic>> getTrainingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('local_ml_training_data');
      final lastTraining = prefs.getString(_lastTrainingKey);
      final hasConsent = await _hasDataSharingConsent();
      
      int localRecords = 0;
      if (localData != null) {
        final data = jsonDecode(localData) as List;
        localRecords = data.length;
      }
      
      return {
        'local_records': localRecords,
        'last_training': lastTraining,
        'has_consent': hasConsent,
        'is_anonymous': _authService.isAnonymous,
        'is_signed_in': _authService.isSignedIn,
      };
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de entrenamiento: $e');
      return {};
    }
  }

  /// Entrena la IA cuando se agregan nuevos datos
  Future<void> trainWithNewData() async {
    try {
      LoggingService.info('Entrenando IA con nuevos datos...');
      
      if (await _hasDataSharingConsent()) {
        await _trainWithAllData();
      } else {
        await _trainWithLocalData();
      }
      
      LoggingService.info('Entrenamiento con nuevos datos completado');
    } catch (e) {
      LoggingService.error('Error entrenando con nuevos datos: $e');
    }
  }
}
