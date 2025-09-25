import '../system/logging_service.dart';
import '../datos/datos.dart';
import '../system/data_migration_service.dart';
import '../datos/enhanced_sync_service.dart';
import 'supabase_auth_service.dart';
import 'user_data_cleanup_service.dart';
import 'user_session_manager.dart';

/// Servicio que maneja la migración de usuarios anónimos a autenticados
class UserMigrationService {
  static final UserMigrationService _instance = UserMigrationService._internal();
  factory UserMigrationService() => _instance;
  UserMigrationService._internal();

  DatosService? _datosService;
  DataMigrationService? _dataMigrationService;
  EnhancedSyncService? _enhancedSyncService;
  SupabaseAuthService? _authService;
  UserDataCleanupService? _cleanupService;
  UserSessionManager? _sessionManager;

  /// Inicializa las dependencias del servicio
  void initializeServices({
    required DatosService datosService,
    required DataMigrationService dataMigrationService,
    required EnhancedSyncService enhancedSyncService,
    required SupabaseAuthService authService,
    required UserDataCleanupService cleanupService,
    required UserSessionManager sessionManager,
  }) {
    _datosService = datosService;
    _dataMigrationService = dataMigrationService;
    _enhancedSyncService = enhancedSyncService;
    _authService = authService;
    _cleanupService = cleanupService;
    _sessionManager = sessionManager;
  }

  /// Valida si la conversión de usuario es posible
  Future<MigrationValidationResult> validateConversion() async {
    try {
      LoggingService.info('🔍 Validando conversión de usuario anónimo...');

      if (_authService == null || _datosService == null) {
        return MigrationValidationResult(
          isValid: false,
          error: 'Servicios no inicializados',
        );
      }

      // Verificar que el usuario actual es anónimo
      if (!_authService!.isAnonymous) {
        return MigrationValidationResult(
          isValid: false,
          error: 'El usuario actual no es anónimo',
        );
      }

      // Verificar que hay datos para migrar
      final hasData = await _hasDataToMigrate();
      if (!hasData) {
        return MigrationValidationResult(
          isValid: true,
          warning: 'No hay datos para migrar',
        );
      }

      // Verificar integridad de datos locales
      final dataIntegrity = await _validateDataIntegrity();
      if (!dataIntegrity.isValid) {
        return MigrationValidationResult(
          isValid: false,
          error: 'Datos locales corruptos: ${dataIntegrity.error}',
        );
      }

      // Verificar conectividad
      final hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        return MigrationValidationResult(
          isValid: false,
          error: 'Sin conectividad a internet',
        );
      }

      LoggingService.info('✅ Validación de conversión exitosa');
      return MigrationValidationResult(isValid: true);
    } catch (e) {
      LoggingService.error('❌ Error validando conversión: $e');
      return MigrationValidationResult(
        isValid: false,
        error: 'Error interno: $e',
      );
    }
  }

  /// Ejecuta la migración completa de usuario anónimo a autenticado
  Future<MigrationResult> migrateAnonymousToAuthenticated({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      LoggingService.info('🚀 Iniciando migración de usuario anónimo...');

      if (_authService == null || _datosService == null || _cleanupService == null) {
        throw Exception('Servicios no inicializados');
      }

      final anonymousUserId = _authService!.currentUserId;
      if (anonymousUserId == null) {
        throw Exception('No se pudo obtener ID de usuario anónimo');
      }

      // 1. Validar conversión
      final validation = await validateConversion();
      if (!validation.isValid) {
        return MigrationResult(
          success: false,
          error: validation.error,
        );
      }

      // 2. Hacer backup de datos anónimos
      LoggingService.info('💾 Haciendo backup de datos anónimos...');
      final backupResult = await _cleanupService!.backupAnonymousData(anonymousUserId);
      if (!backupResult.success) {
        return MigrationResult(
          success: false,
          error: 'Error haciendo backup: ${backupResult.error}',
        );
      }

      // 3. Convertir cuenta anónima a permanente
      LoggingService.info('🔄 Convirtiendo cuenta anónima...');
      final conversionSuccess = await _authService!.convertAnonymousToPermanent(
        email,
        password,
        displayName,
      );

      if (!conversionSuccess) {
        return MigrationResult(
          success: false,
          error: 'Error convirtiendo cuenta anónima',
        );
      }

      // 4. Migrar datos del usuario
      LoggingService.info('📦 Migrando datos del usuario...');
      final migrationSuccess = await _migrateUserData(anonymousUserId);
      if (!migrationSuccess) {
        // Rollback: revertir conversión
        await _rollbackConversion();
        return MigrationResult(
          success: false,
          error: 'Error migrando datos del usuario',
        );
      }

      // 5. Sincronizar datos migrados
      LoggingService.info('🔄 Sincronizando datos migrados...');
      final syncSuccess = await _syncMigratedData();
      if (!syncSuccess) {
        LoggingService.warning('⚠️ Error sincronizando datos, pero migración local exitosa');
      }

      // 6. Limpiar datos anónimos
      LoggingService.info('🧹 Limpiando datos anónimos...');
      await _cleanupService!.cleanupAnonymousData(anonymousUserId);

      // 7. Reinicializar servicios
      LoggingService.info('🔄 Reinicializando servicios...');
      await _reinitializeServices();

      LoggingService.info('✅ Migración completada exitosamente');
      return MigrationResult(
        success: true,
        message: 'Usuario migrado exitosamente',
      );
    } catch (e) {
      LoggingService.error('❌ Error en migración: $e');
      return MigrationResult(
        success: false,
        error: 'Error interno: $e',
      );
    }
  }

  /// Verifica si hay datos para migrar
  Future<bool> _hasDataToMigrate() async {
    if (_datosService == null) return false;

    try {
      final productos = await _datosService!.getAllProductos();
      final ventas = await _datosService!.getAllVentas();
      final clientes = await _datosService!.getAllClientes();

      return productos.isNotEmpty || ventas.isNotEmpty || clientes.isNotEmpty;
    } catch (e) {
      LoggingService.error('Error verificando datos para migrar: $e');
      return false;
    }
  }

  /// Valida la integridad de los datos locales
  Future<DataIntegrityResult> _validateDataIntegrity() async {
    try {
      // Implementar validaciones específicas
      // - Verificar estructura de datos
      // - Verificar relaciones entre entidades
      // - Verificar timestamps
      
      return DataIntegrityResult(isValid: true);
    } catch (e) {
      return DataIntegrityResult(
        isValid: false,
        error: e.toString(),
      );
    }
  }

  /// Verifica conectividad a internet
  Future<bool> _checkConnectivity() async {
    try {
      // Implementar verificación de conectividad
      return true; // Placeholder
    } catch (e) {
      return false;
    }
  }

  /// Migra los datos del usuario
  Future<bool> _migrateUserData(String anonymousUserId) async {
    try {
      if (_dataMigrationService == null) return false;

      // Migrar datos usando el servicio existente
      await _dataMigrationService!.migrateExistingData();
      return true;
    } catch (e) {
      LoggingService.error('Error migrando datos del usuario: $e');
      return false;
    }
  }

  /// Sincroniza los datos migrados
  Future<bool> _syncMigratedData() async {
    try {
      if (_enhancedSyncService == null) return false;

      // Forzar sincronización de todos los datos
      await _enhancedSyncService!.forceSync();
      return true;
    } catch (e) {
      LoggingService.error('Error sincronizando datos migrados: $e');
      return false;
    }
  }

  /// Hace rollback de la conversión en caso de error
  Future<void> _rollbackConversion() async {
    try {
      LoggingService.warning('🔄 Haciendo rollback de conversión...');
      // Implementar rollback
      // - Revertir cambios en Supabase
      // - Restaurar datos anónimos
      // - Limpiar estado de conversión
    } catch (e) {
      LoggingService.error('Error en rollback: $e');
    }
  }

  /// Reinicializa los servicios después de la migración
  Future<void> _reinitializeServices() async {
    try {
      if (_sessionManager == null) return;

      // Reinicializar servicios usando el session manager
      await _sessionManager!.reinitializeServicesForNewUser();
    } catch (e) {
      LoggingService.error('Error reinicializando servicios: $e');
    }
  }
}

/// Resultado de validación de migración
class MigrationValidationResult {
  final bool isValid;
  final String? error;
  final String? warning;

  MigrationValidationResult({
    required this.isValid,
    this.error,
    this.warning,
  });
}

/// Resultado de migración
class MigrationResult {
  final bool success;
  final String? error;
  final String? message;

  MigrationResult({
    required this.success,
    this.error,
    this.message,
  });
}

/// Resultado de validación de integridad de datos
class DataIntegrityResult {
  final bool isValid;
  final String? error;

  DataIntegrityResult({
    required this.isValid,
    this.error,
  });
}
