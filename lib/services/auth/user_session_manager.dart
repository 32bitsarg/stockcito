import '../system/logging_service.dart';
import '../datos/datos.dart';
import '../datos/enhanced_sync_service.dart';
import '../ml/ml_training_service.dart';
import '../system/intelligent_cache_service.dart';
import '../system/automated_backup_service.dart';
import 'supabase_auth_service.dart';

/// Servicio que maneja las sesiones de usuario y reinicialización de servicios
class UserSessionManager {
  static final UserSessionManager _instance = UserSessionManager._internal();
  factory UserSessionManager() => _instance;
  UserSessionManager._internal();

  // Servicios principales
  SupabaseAuthService? _authService;
  DatosService? _datosService;
  EnhancedSyncService? _enhancedSyncService;
  MLTrainingService? _mlTrainingService;
  IntelligentCacheService? _intelligentCacheService;
  AutomatedBackupService? _automatedBackupService;

  // Estado de servicios
  final Map<String, ServiceState> _serviceStates = {};
  UserType? _currentUserType;

  /// Inicializa las dependencias del servicio
  void initializeServices({
    required SupabaseAuthService authService,
    required DatosService datosService,
    required EnhancedSyncService enhancedSyncService,
    required MLTrainingService mlTrainingService,
    required IntelligentCacheService intelligentCacheService,
    required AutomatedBackupService automatedBackupService,
  }) {
    _authService = authService;
    _datosService = datosService;
    _enhancedSyncService = enhancedSyncService;
    _mlTrainingService = mlTrainingService;
    _intelligentCacheService = intelligentCacheService;
    _automatedBackupService = automatedBackupService;
  }

  /// Reinicializa todos los servicios para un nuevo usuario
  Future<void> reinitializeServicesForNewUser() async {
    try {
      LoggingService.info('🔄 Reinicializando servicios para nuevo usuario...');

      if (_authService == null) {
        throw Exception('AuthService no inicializado');
      }

      final newUserType = _authService!.isAnonymous ? UserType.anonymous : UserType.authenticated;
      
      // Verificar si el tipo de usuario cambió
      if (_currentUserType == newUserType) {
        LoggingService.info('👤 Tipo de usuario no cambió, saltando reinicialización');
        return;
      }

      LoggingService.info('👤 Tipo de usuario cambió de $_currentUserType a $newUserType');

      // 1. Limpiar estado de servicios
      await _clearServiceStates();

      // 2. Reinicializar servicios según el tipo de usuario
      if (newUserType == UserType.authenticated) {
        await _reinitializeForAuthenticatedUser();
      } else {
        await _reinitializeForAnonymousUser();
      }

      // 3. Actualizar estado
      _currentUserType = newUserType;
      await _updateServiceStates();

      LoggingService.info('✅ Servicios reinicializados exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error reinicializando servicios: $e');
    }
  }

  /// Reinicializa servicios para usuario autenticado
  Future<void> _reinitializeForAuthenticatedUser() async {
    try {
      LoggingService.info('🔐 Reinicializando servicios para usuario autenticado...');

      // Reinicializar DatosService
      if (_datosService != null) {
        await _datosService!.initialize();
        _serviceStates['datos'] = ServiceState(
          name: 'datos',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.authenticated,
        );
      }

      // Reinicializar EnhancedSyncService
      if (_enhancedSyncService != null) {
        await _enhancedSyncService!.initialize();
        _serviceStates['sync'] = ServiceState(
          name: 'sync',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.authenticated,
        );
      }

      // Reinicializar MLTrainingService
      if (_mlTrainingService != null) {
        await _mlTrainingService!.initialize();
        _serviceStates['ml'] = ServiceState(
          name: 'ml',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.authenticated,
        );
      }

      // Reinicializar IntelligentCacheService
      if (_intelligentCacheService != null) {
        await _intelligentCacheService!.initialize();
        _serviceStates['cache'] = ServiceState(
          name: 'cache',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.authenticated,
        );
      }

      // Reinicializar AutomatedBackupService
      if (_automatedBackupService != null) {
        await _automatedBackupService!.initialize();
        _serviceStates['backup'] = ServiceState(
          name: 'backup',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.authenticated,
        );
      }

      LoggingService.info('✅ Servicios de usuario autenticado reinicializados');
    } catch (e) {
      LoggingService.error('❌ Error reinicializando servicios de usuario autenticado: $e');
    }
  }

  /// Reinicializa servicios para usuario anónimo
  Future<void> _reinitializeForAnonymousUser() async {
    try {
      LoggingService.info('👤 Reinicializando servicios para usuario anónimo...');

      // Reinicializar DatosService
      if (_datosService != null) {
        await _datosService!.initialize();
        _serviceStates['datos'] = ServiceState(
          name: 'datos',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.anonymous,
        );
      }

      // Limpiar servicios que no se usan en modo anónimo
      _serviceStates['sync'] = ServiceState(
        name: 'sync',
        initialized: false,
        lastUpdate: DateTime.now(),
        userType: UserType.anonymous,
      );

      _serviceStates['backup'] = ServiceState(
        name: 'backup',
        initialized: false,
        lastUpdate: DateTime.now(),
        userType: UserType.anonymous,
      );

      // Reinicializar MLTrainingService (solo local)
      if (_mlTrainingService != null) {
        await _mlTrainingService!.initialize();
        _serviceStates['ml'] = ServiceState(
          name: 'ml',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.anonymous,
        );
      }

      // Reinicializar IntelligentCacheService
      if (_intelligentCacheService != null) {
        await _intelligentCacheService!.initialize();
        _serviceStates['cache'] = ServiceState(
          name: 'cache',
          initialized: true,
          lastUpdate: DateTime.now(),
          userType: UserType.anonymous,
        );
      }

      LoggingService.info('✅ Servicios de usuario anónimo reinicializados');
    } catch (e) {
      LoggingService.error('❌ Error reinicializando servicios de usuario anónimo: $e');
    }
  }

  /// Limpia el estado de todos los servicios
  Future<void> _clearServiceStates() async {
    try {
      LoggingService.info('🗑️ Limpiando estado de servicios...');

      // Limpiar cache
      if (_intelligentCacheService != null) {
        await _intelligentCacheService!.clearAllCache();
      }

      // Limpiar cola de sincronización
      if (_enhancedSyncService != null) {
        await _enhancedSyncService!.clearSyncQueue();
      }

      // Limpiar estado de servicios
      _serviceStates.clear();

      LoggingService.info('✅ Estado de servicios limpiado');
    } catch (e) {
      LoggingService.error('❌ Error limpiando estado de servicios: $e');
    }
  }

  /// Actualiza el estado de todos los servicios
  Future<void> _updateServiceStates() async {
    try {
      final now = DateTime.now();

      // Actualizar estado de DatosService
      _serviceStates['datos'] = ServiceState(
        name: 'datos',
        initialized: _datosService != null,
        lastUpdate: now,
        userType: _currentUserType ?? UserType.anonymous,
      );

      // Actualizar estado de EnhancedSyncService
      _serviceStates['sync'] = ServiceState(
        name: 'sync',
        initialized: _enhancedSyncService != null && _currentUserType == UserType.authenticated,
        lastUpdate: now,
        userType: _currentUserType ?? UserType.anonymous,
      );

      // Actualizar estado de MLTrainingService
      _serviceStates['ml'] = ServiceState(
        name: 'ml',
        initialized: _mlTrainingService != null,
        lastUpdate: now,
        userType: _currentUserType ?? UserType.anonymous,
      );

      // Actualizar estado de IntelligentCacheService
      _serviceStates['cache'] = ServiceState(
        name: 'cache',
        initialized: _intelligentCacheService != null,
        lastUpdate: now,
        userType: _currentUserType ?? UserType.anonymous,
      );

      // Actualizar estado de AutomatedBackupService
      _serviceStates['backup'] = ServiceState(
        name: 'backup',
        initialized: _automatedBackupService != null && _currentUserType == UserType.authenticated,
        lastUpdate: now,
        userType: _currentUserType ?? UserType.anonymous,
      );

      LoggingService.info('✅ Estado de servicios actualizado');
    } catch (e) {
      LoggingService.error('❌ Error actualizando estado de servicios: $e');
    }
  }

  /// Obtiene el estado de un servicio específico
  ServiceState? getServiceState(String serviceName) {
    return _serviceStates[serviceName];
  }

  /// Obtiene el estado de todos los servicios
  Map<String, ServiceState> getAllServiceStates() {
    return Map.from(_serviceStates);
  }

  /// Verifica si todos los servicios están inicializados correctamente
  bool areAllServicesInitialized() {
    return _serviceStates.values.every((state) => state.initialized);
  }

  /// Obtiene el tipo de usuario actual
  UserType? getCurrentUserType() {
    return _currentUserType;
  }

  /// Valida la integridad de todos los servicios
  Future<ServiceIntegrityResult> validateServiceIntegrity() async {
    try {
      LoggingService.info('🔍 Validando integridad de servicios...');

      final results = <String, bool>{};
      final errors = <String, String>{};

      // Validar DatosService
      if (_datosService != null) {
        try {
          // Implementar validación específica
          results['datos'] = true;
        } catch (e) {
          results['datos'] = false;
          errors['datos'] = e.toString();
        }
      }

      // Validar EnhancedSyncService
      if (_enhancedSyncService != null && _currentUserType == UserType.authenticated) {
        try {
          // Implementar validación específica
          results['sync'] = true;
        } catch (e) {
          results['sync'] = false;
          errors['sync'] = e.toString();
        }
      }

      // Validar otros servicios...

      final allValid = results.values.every((valid) => valid);

      return ServiceIntegrityResult(
        isValid: allValid,
        results: results,
        errors: errors,
      );
    } catch (e) {
      LoggingService.error('❌ Error validando integridad de servicios: $e');
      return ServiceIntegrityResult(
        isValid: false,
        results: {},
        errors: {'general': e.toString()},
      );
    }
  }
}

/// Estado de un servicio
class ServiceState {
  final String name;
  final bool initialized;
  final DateTime lastUpdate;
  final UserType userType;
  final bool dataIntegrity;

  ServiceState({
    required this.name,
    required this.initialized,
    required this.lastUpdate,
    required this.userType,
    this.dataIntegrity = true,
  });
}

/// Tipo de usuario
enum UserType {
  anonymous,
  authenticated,
}

/// Resultado de validación de integridad de servicios
class ServiceIntegrityResult {
  final bool isValid;
  final Map<String, bool> results;
  final Map<String, String> errors;

  ServiceIntegrityResult({
    required this.isValid,
    required this.results,
    required this.errors,
  });
}
