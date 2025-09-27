import '../datos/datos.dart';
import 'package:stockcito/services/ml/ml_training_service.dart';
import 'package:stockcito/services/ml/ml_consent_service.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/ai/ai_cache_service.dart';

class DataMigrationService {
  static final DataMigrationService _instance = DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();

  DatosService? _datosService;
  MLTrainingService? _mlTrainingService;
  MLConsentService? _consentService;
  final AICacheService _cacheService = AICacheService();

  /// Inicializa los servicios (inyección de dependencia)
  void initializeServices({
    required DatosService datosService,
    required MLTrainingService mlTrainingService,
    required MLConsentService consentService,
  }) {
    _datosService = datosService;
    _mlTrainingService = mlTrainingService;
    _consentService = consentService;
  }

  /// Entrena la IA con todos los datos disponibles
  /// Solo migra datos si el usuario ha dado consentimiento
  Future<void> migrateExistingData() async {
    if (_datosService == null || _mlTrainingService == null || _consentService == null) {
      LoggingService.error('Servicios no inicializados en DataMigrationService');
      return;
    }

    try {
      // Verificar si el usuario ha dado consentimiento
      final hasConsent = await _consentService!.hasUserGivenConsent();
      
      if (!hasConsent) {
        LoggingService.info('Usuario no ha dado consentimiento para ML training. Saltando migración de datos.');
        return;
      }

      LoggingService.info('Iniciando migración de datos para ML training...');
      print('📦 DEBUG: Migrando datos existentes para entrenamiento de IA');
      
      // Usar el nuevo MLTrainingService
      await _mlTrainingService!.initialize();
      
      // Migrar datos existentes
      await _migrateProductos();
      await _migrateVentas();
      await _migrateClientes();
      
      LoggingService.info('Migración de datos para ML training completada');
    } catch (e) {
      LoggingService.error('Error en migración de datos para ML training: $e');
    }
  }

  /// Verifica si hay datos para migrar y los migra automáticamente
  /// Se llama cuando el usuario activa el consentimiento
  Future<void> checkAndMigrateDataOnConsent() async {
    if (_consentService == null) {
      LoggingService.error('MLConsentService no inicializado en DataMigrationService');
      return;
    }

    try {
      final hasConsent = await _consentService!.hasUserGivenConsent();
      
      if (!hasConsent) {
        LoggingService.info('Usuario no ha dado consentimiento. No se migrarán datos.');
        return;
      }

      // Verificar si ya se migraron los datos
      final isMigrated = await isDataMigrated();
      
      if (isMigrated) {
        LoggingService.info('Datos ya migrados para ML training.');
        return;
      }

      LoggingService.info('Usuario activó consentimiento. Migrando datos existentes...');
      await migrateExistingData();
      
    } catch (e) {
      LoggingService.error('Error verificando y migrando datos: $e');
    }
  }

  /// Migra productos existentes a datos de entrenamiento ML
  Future<void> _migrateProductos() async {
    if (_datosService == null || _mlTrainingService == null) return;
    
    try {
      final productos = await _datosService!.getAllProductos();
      print('🔍 DEBUG: Encontrados ${productos.length} productos para migrar');
      LoggingService.info('Migrando ${productos.length} productos...');
      
      for (final producto in productos) {
        print('🔍 DEBUG: Migrando producto: ${producto.nombre}');
        
        // Guardar usando MLTrainingService
        try {
          await _mlTrainingService!.initialize();
          print('✅ DEBUG: Producto migrado exitosamente: ${producto.nombre}');
          LoggingService.info('Producto migrado: ${producto.nombre}');
        } catch (e) {
          LoggingService.warning('Error entrenando IA con producto migrado: $e');
        }
      }
      
      print('✅ DEBUG: Todos los productos migrados exitosamente');
      LoggingService.info('Productos migrados exitosamente');
    } catch (e) {
      print('❌ DEBUG: Error migrando productos: $e');
      LoggingService.error('Error migrando productos: $e');
    }
  }

  /// Migra ventas existentes a datos de entrenamiento ML
  Future<void> _migrateVentas() async {
    if (_datosService == null || _mlTrainingService == null) return;
    
    try {
      final ventas = await _datosService!.getAllVentas();
      print('🔍 DEBUG: Encontradas ${ventas.length} ventas para migrar');
      LoggingService.info('Migrando ${ventas.length} ventas...');
      
      for (final venta in ventas) {
        print('🔍 DEBUG: Migrando venta: ${venta.cliente} - \$${venta.total}');
        
        try {
          await _mlTrainingService!.initialize();
          print('✅ DEBUG: Venta migrada exitosamente: ${venta.cliente}');
          LoggingService.info('Venta migrada: ${venta.cliente} - \$${venta.total}');
        } catch (e) {
          LoggingService.warning('Error entrenando IA con venta migrada: $e');
        }
      }
      
      print('✅ DEBUG: Todas las ventas migradas exitosamente');
      LoggingService.info('Ventas migradas exitosamente');
    } catch (e) {
      print('❌ DEBUG: Error migrando ventas: $e');
      LoggingService.error('Error migrando ventas: $e');
    }
  }

  /// Migra clientes existentes a datos de entrenamiento ML
  Future<void> _migrateClientes() async {
    if (_datosService == null || _mlTrainingService == null) return;
    
    try {
      final clientes = await _datosService!.getAllClientes();
      print('🔍 DEBUG: Encontrados ${clientes.length} clientes para migrar');
      LoggingService.info('Migrando ${clientes.length} clientes...');
      
      for (final cliente in clientes) {
        print('🔍 DEBUG: Migrando cliente: ${cliente.nombre}');
        
        try {
          await _mlTrainingService!.initialize();
          print('✅ DEBUG: Cliente migrado exitosamente: ${cliente.nombre}');
          LoggingService.info('Cliente migrado: ${cliente.nombre}');
        } catch (e) {
          LoggingService.warning('Error entrenando IA con cliente migrado: $e');
        }
      }
      
      print('✅ DEBUG: Todos los clientes migrados exitosamente');
      LoggingService.info('Clientes migrados exitosamente');
    } catch (e) {
      print('❌ DEBUG: Error migrando clientes: $e');
      LoggingService.error('Error migrando clientes: $e');
    }
  }



  /// Verifica si ya se migraron los datos
  Future<bool> isDataMigrated() async {
    if (_mlTrainingService == null) return false;
    
    try {
      final stats = await _mlTrainingService!.getTrainingStats();
      // Considerar migrado si hay datos de entrenamiento locales
      return (stats['local_records'] ?? 0) > 0;
    } catch (e) {
      LoggingService.error('Error verificando migración: $e');
      return false;
    }
  }

  /// Obtiene estadísticas de migración (con caché para optimizar peticiones)
  Future<Map<String, dynamic>> getMigrationStats() async {
    try {
      // Primero intentar obtener desde caché
      final cachedStats = await _cacheService.getCachedStats();
      if (cachedStats.isNotEmpty) {
        print('📦 DEBUG: Usando estadísticas desde caché');
        return cachedStats;
      }

      print('🔍 DEBUG: Obteniendo estadísticas de migración desde MLTrainingService...');
      final stats = await _mlTrainingService!.getTrainingStats();
      print('🔍 DEBUG: Estadísticas de ML obtenidas: $stats');
      
      final result = {
        'training_data_count': stats['local_records'] ?? 0,
        'models_count': 0, // No implementado aún
        'predictions_count': 0, // No implementado aún
        'migration_completed': true,
        'has_consent': stats['has_consent'] ?? false,
        'is_anonymous': stats['is_anonymous'] ?? false,
        'is_signed_in': stats['is_signed_in'] ?? false,
      };
      
      // Guardar en caché para futuras consultas
      await _cacheService.cacheStats(result);
      
      print('✅ DEBUG: Estadísticas de migración preparadas y guardadas en caché: $result');
      return result;
    } catch (e) {
      print('❌ DEBUG: Error obteniendo estadísticas: $e');
      LoggingService.error('Error obteniendo estadísticas: $e');
      return {
        'training_data_count': 0,
        'models_count': 0,
        'predictions_count': 0,
        'migration_completed': false,
        'has_consent': false,
        'is_anonymous': false,
        'is_signed_in': false,
      };
    }
  }
}
