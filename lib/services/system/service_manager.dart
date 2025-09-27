import '../system/logging_service.dart';
import '../datos/datos.dart';
import '../datos/enhanced_sync_service.dart';
import '../system/data_migration_service.dart';
import '../ml/ml_training_service.dart';
import '../ml/ml_consent_service.dart';
import '../system/intelligent_cache_service.dart';
import '../system/lazy_loading_service.dart';
import '../system/automated_backup_service.dart';
import '../auth/supabase_auth_service.dart';
import '../auth/user_migration_service.dart';
import '../auth/user_data_cleanup_service.dart';
import '../auth/user_session_manager.dart';

/// Gestor centralizado de servicios de la aplicación
class ServiceManager {
  static final ServiceManager _instance = ServiceManager._internal();
  factory ServiceManager() => _instance;
  ServiceManager._internal();

  // Servicios principales
  SupabaseAuthService? _authService;
  DatosService? _datosService;
  EnhancedSyncService? _enhancedSyncService;
  DataMigrationService? _dataMigrationService;
  MLTrainingService? _mlTrainingService;
  MLConsentService? _mlConsentService;
  IntelligentCacheService? _intelligentCacheService;
  LazyLoadingService? _lazyLoadingService;
  AutomatedBackupService? _automatedBackupService;

  // Servicios de gestión de usuarios
  UserMigrationService? _userMigrationService;
  UserDataCleanupService? _userDataCleanupService;
  UserSessionManager? _userSessionManager;

  // Estado de servicios
  final Map<String, ServiceInfo> _services = {};
  bool _initialized = false;

  /// Inicializa todos los servicios de la aplicación
  Future<void> initializeAllServices() async {
    try {
      LoggingService.info('🚀 Inicializando todos los servicios...');

      if (_initialized) {
        LoggingService.warning('⚠️ Servicios ya inicializados');
        return;
      }

      // 1. Inicializar servicios principales
      await _initializeCoreServices();

      // 2. Inicializar servicios de gestión de usuarios
      await _initializeUserManagementServices();

      // 3. Configurar dependencias entre servicios
      await _configureServiceDependencies();

      // 4. Validar integridad de servicios
      await _validateServiceIntegrity();

      _initialized = true;
      LoggingService.info('✅ Todos los servicios inicializados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicios: $e');
      throw Exception('Error inicializando servicios: $e');
    }
  }

  /// Inicializa los servicios principales
  Future<void> _initializeCoreServices() async {
    try {
      LoggingService.info('🔧 Inicializando servicios principales...');

      // SupabaseAuthService
      _authService = SupabaseAuthService();
      await _authService!.initialize();
      _registerService('auth', _authService!, 'Autenticación');

      // DatosService
      _datosService = DatosService();
      _datosService!.initializeAuthService(_authService!);
      await _datosService!.initialize();
      _registerService('datos', _datosService!, 'Gestión de datos');

      // EnhancedSyncService
      _enhancedSyncService = EnhancedSyncService();
      await _enhancedSyncService!.initialize();
      _registerService('sync', _enhancedSyncService!, 'Sincronización');

      // DataMigrationService
      _dataMigrationService = DataMigrationService();
      _registerService('migration', _dataMigrationService!, 'Migración de datos');

      // MLTrainingService
      _mlTrainingService = MLTrainingService();
      _datosService!.initializeMLTrainingService(_mlTrainingService!);
      await _mlTrainingService!.initialize();
      _registerService('ml', _mlTrainingService!, 'Machine Learning');

      // MLConsentService
      _mlConsentService = MLConsentService();
      _registerService('consent', _mlConsentService!, 'Consentimiento ML');

      // IntelligentCacheService
      _intelligentCacheService = IntelligentCacheService();
      await _intelligentCacheService!.initialize();
      _registerService('cache', _intelligentCacheService!, 'Cache inteligente');

      // LazyLoadingService
      _lazyLoadingService = LazyLoadingService();
      await _lazyLoadingService!.initialize();
      _registerService('lazy', _lazyLoadingService!, 'Carga perezosa');

      // AutomatedBackupService
      _automatedBackupService = AutomatedBackupService();
      await _automatedBackupService!.initialize();
      _registerService('backup', _automatedBackupService!, 'Backup automático');

      LoggingService.info('✅ Servicios principales inicializados');
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicios principales: $e');
      throw e;
    }
  }

  /// Inicializa los servicios de gestión de usuarios
  Future<void> _initializeUserManagementServices() async {
    try {
      LoggingService.info('👤 Inicializando servicios de gestión de usuarios...');

      // UserMigrationService
      _userMigrationService = UserMigrationService();
      _registerService('user_migration', _userMigrationService!, 'Migración de usuarios');

      // UserDataCleanupService
      _userDataCleanupService = UserDataCleanupService();
      _registerService('user_cleanup', _userDataCleanupService!, 'Limpieza de datos');

      // UserSessionManager
      _userSessionManager = UserSessionManager();
      _registerService('session_manager', _userSessionManager!, 'Gestión de sesiones');

      LoggingService.info('✅ Servicios de gestión de usuarios inicializados');
    } catch (e) {
      LoggingService.error('❌ Error inicializando servicios de gestión de usuarios: $e');
      throw e;
    }
  }

  /// Configura las dependencias entre servicios
  Future<void> _configureServiceDependencies() async {
    try {
      LoggingService.info('🔗 Configurando dependencias entre servicios...');

      // Configurar dependencias de DataMigrationService
      _dataMigrationService!.initializeServices(
        datosService: _datosService!,
        mlTrainingService: _mlTrainingService!,
        consentService: _mlConsentService!,
      );

      // Configurar dependencias de UserMigrationService
      _userMigrationService!.initializeServices(
        datosService: _datosService!,
        dataMigrationService: _dataMigrationService!,
        enhancedSyncService: _enhancedSyncService!,
        authService: _authService!,
        cleanupService: _userDataCleanupService!,
        sessionManager: _userSessionManager!,
      );

      // Configurar dependencias de UserDataCleanupService
      _userDataCleanupService!.initializeServices(
        datosService: _datosService!,
        localDb: _datosService!.localDb,
      );

      // Configurar dependencias de UserSessionManager
      _userSessionManager!.initializeServices(
        authService: _authService!,
        datosService: _datosService!,
        enhancedSyncService: _enhancedSyncService!,
        mlTrainingService: _mlTrainingService!,
        intelligentCacheService: _intelligentCacheService!,
        automatedBackupService: _automatedBackupService!,
      );

      LoggingService.info('✅ Dependencias configuradas');
    } catch (e) {
      LoggingService.error('❌ Error configurando dependencias: $e');
      throw e;
    }
  }

  /// Valida la integridad de todos los servicios
  Future<void> _validateServiceIntegrity() async {
    try {
      LoggingService.info('🔍 Validando integridad de servicios...');

      final results = <String, bool>{};
      final errors = <String, String>{};

      for (final entry in _services.entries) {
        final serviceName = entry.key;
        final serviceInfo = entry.value;

        try {
          // Validar que el servicio está inicializado
          if (!serviceInfo.initialized) {
            results[serviceName] = false;
            errors[serviceName] = 'Servicio no inicializado';
            continue;
          }

          // Validar que el servicio tiene las dependencias necesarias
          if (!_validateServiceDependencies(serviceName)) {
            results[serviceName] = false;
            errors[serviceName] = 'Dependencias faltantes';
            continue;
          }

          results[serviceName] = true;
        } catch (e) {
          results[serviceName] = false;
          errors[serviceName] = e.toString();
        }
      }

      final allValid = results.values.every((valid) => valid);
      if (!allValid) {
        LoggingService.error('❌ Algunos servicios no pasaron la validación:');
        for (final entry in errors.entries) {
          LoggingService.error('  - ${entry.key}: ${entry.value}');
        }
        throw Exception('Validación de servicios falló');
      }

      LoggingService.info('✅ Todos los servicios pasaron la validación');
    } catch (e) {
      LoggingService.error('❌ Error validando integridad de servicios: $e');
      throw e;
    }
  }

  /// Valida las dependencias de un servicio específico
  bool _validateServiceDependencies(String serviceName) {
    switch (serviceName) {
      case 'datos':
        return _authService != null;
      case 'sync':
        return _datosService != null && _authService != null;
      case 'migration':
        return _datosService != null && _mlTrainingService != null && _mlConsentService != null;
      case 'ml':
        return _datosService != null;
      case 'user_migration':
        return _datosService != null && _dataMigrationService != null && 
               _enhancedSyncService != null && _authService != null &&
               _userDataCleanupService != null && _userSessionManager != null;
      case 'user_cleanup':
        return _datosService != null;
      case 'session_manager':
        return _authService != null && _datosService != null && _enhancedSyncService != null;
      default:
        return true;
    }
  }

  /// Registra un servicio en el gestor
  void _registerService(String name, dynamic service, String description) {
    _services[name] = ServiceInfo(
      name: name,
      service: service,
      description: description,
      initialized: true,
      lastUpdate: DateTime.now(),
    );
    LoggingService.info('📝 Servicio registrado: $name - $description');
  }

  /// Obtiene un servicio específico
  T? getService<T>(String name) {
    final serviceInfo = _services[name];
    if (serviceInfo == null) {
      LoggingService.warning('⚠️ Servicio no encontrado: $name');
      return null;
    }
    return serviceInfo.service as T?;
  }

  /// Obtiene información de todos los servicios
  Map<String, ServiceInfo> getAllServices() {
    return Map.from(_services);
  }

  /// Verifica si todos los servicios están inicializados
  bool areAllServicesInitialized() {
    return _services.values.every((info) => info.initialized);
  }

  /// Reinicializa un servicio específico
  Future<void> reinitializeService(String name) async {
    try {
      LoggingService.info('🔄 Reinicializando servicio: $name');

      final serviceInfo = _services[name];
      if (serviceInfo == null) {
        throw Exception('Servicio no encontrado: $name');
      }

      // Reinicializar según el tipo de servicio
      switch (name) {
        case 'datos':
          await _datosService!.initialize();
          break;
        case 'sync':
          await _enhancedSyncService!.initialize();
          break;
        case 'ml':
          await _mlTrainingService!.initialize();
          break;
        case 'cache':
          await _intelligentCacheService!.initialize();
          break;
        case 'lazy':
          await _lazyLoadingService!.initialize();
          break;
        case 'backup':
          await _automatedBackupService!.initialize();
          break;
        default:
          LoggingService.warning('⚠️ Reinicialización no implementada para: $name');
      }

      // Actualizar estado
      serviceInfo.initialized = true;
      serviceInfo.lastUpdate = DateTime.now();

      LoggingService.info('✅ Servicio reinicializado: $name');
    } catch (e) {
      LoggingService.error('❌ Error reinicializando servicio $name: $e');
      throw e;
    }
  }

  /// Limpia un servicio específico
  Future<void> cleanupService(String name) async {
    try {
      LoggingService.info('🧹 Limpiando servicio: $name');

      final serviceInfo = _services[name];
      if (serviceInfo == null) {
        throw Exception('Servicio no encontrado: $name');
      }

      // Limpiar según el tipo de servicio
      switch (name) {
        case 'cache':
          await _intelligentCacheService!.clearAllCache();
          break;
        case 'sync':
          await _enhancedSyncService!.clearSyncQueue();
          break;
        default:
          LoggingService.warning('⚠️ Limpieza no implementada para: $name');
      }

      // Actualizar estado
      serviceInfo.initialized = false;
      serviceInfo.lastUpdate = DateTime.now();

      LoggingService.info('✅ Servicio limpiado: $name');
    } catch (e) {
      LoggingService.error('❌ Error limpiando servicio $name: $e');
      throw e;
    }
  }

  /// Obtiene el estado de un servicio
  ServiceState getServiceState(String name) {
    final serviceInfo = _services[name];
    if (serviceInfo == null) {
      return ServiceState(
        name: name,
        initialized: false,
        lastUpdate: DateTime.now(),
        userType: UserType.anonymous,
      );
    }

    return ServiceState(
      name: name,
      initialized: serviceInfo.initialized,
      lastUpdate: serviceInfo.lastUpdate,
      userType: _authService?.isAnonymous == true ? UserType.anonymous : UserType.authenticated,
    );
  }

  /// Obtiene estadísticas de servicios
  ServiceStatistics getServiceStatistics() {
    final totalServices = _services.length;
    final initializedServices = _services.values.where((info) => info.initialized).length;
    final failedServices = totalServices - initializedServices;

    return ServiceStatistics(
      totalServices: totalServices,
      initializedServices: initializedServices,
      failedServices: failedServices,
      initializationRate: totalServices > 0 ? (initializedServices / totalServices) * 100 : 0,
    );
  }

  // Getters para acceder a servicios específicos
  SupabaseAuthService? get authService => _authService;
  DatosService? get datosService => _datosService;
  UserMigrationService? get userMigrationService => _userMigrationService;
  UserDataCleanupService? get userDataCleanupService => _userDataCleanupService;
  UserSessionManager? get userSessionManager => _userSessionManager;
  DataMigrationService? get dataMigrationService => _dataMigrationService;
  EnhancedSyncService? get enhancedSyncService => _enhancedSyncService;
}

/// Información de un servicio
class ServiceInfo {
  final String name;
  final dynamic service;
  final String description;
  bool initialized;
  DateTime lastUpdate;

  ServiceInfo({
    required this.name,
    required this.service,
    required this.description,
    required this.initialized,
    required this.lastUpdate,
  });
}

/// Estado de un servicio
class ServiceState {
  final String name;
  final bool initialized;
  final DateTime lastUpdate;
  final UserType userType;

  ServiceState({
    required this.name,
    required this.initialized,
    required this.lastUpdate,
    required this.userType,
  });
}

/// Tipo de usuario
enum UserType {
  anonymous,
  authenticated,
}

/// Estadísticas de servicios
class ServiceStatistics {
  final int totalServices;
  final int initializedServices;
  final int failedServices;
  final double initializationRate;

  ServiceStatistics({
    required this.totalServices,
    required this.initializedServices,
    required this.failedServices,
    required this.initializationRate,
  });
}
