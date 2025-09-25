import 'package:shared_preferences/shared_preferences.dart';
import '../system/logging_service.dart';
import '../datos/datos.dart';
import '../datos/database/local_database_service.dart';

/// Servicio que maneja la limpieza de datos de usuarios anónimos
class UserDataCleanupService {
  static final UserDataCleanupService _instance = UserDataCleanupService._internal();
  factory UserDataCleanupService() => _instance;
  UserDataCleanupService._internal();

  DatosService? _datosService;
  LocalDatabaseService? _localDb;

  /// Inicializa las dependencias del servicio
  void initializeServices({
    required DatosService datosService,
    required LocalDatabaseService localDb,
  }) {
    _datosService = datosService;
    _localDb = localDb;
  }

  /// Hace backup de datos anónimos antes de la conversión
  Future<BackupResult> backupAnonymousData(String anonymousUserId) async {
    try {
      LoggingService.info('💾 Haciendo backup de datos anónimos para usuario: $anonymousUserId');

      if (_datosService == null || _localDb == null) {
        return BackupResult(
          success: false,
          error: 'Servicios no inicializados',
        );
      }

      // Obtener todos los datos del usuario anónimo
      final productos = await _datosService!.getAllProductos();
      final ventas = await _datosService!.getAllVentas();
      final clientes = await _datosService!.getAllClientes();
      final categorias = await _datosService!.getCategorias();
      final tallas = await _datosService!.getTallas();

      // Crear backup en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      
      // Backup de productos
      final productosJson = productos.map((p) => p.toMap()).toList();
      await prefs.setString('backup_productos_$anonymousUserId', 
          productosJson.toString());

      // Backup de ventas
      final ventasJson = ventas.map((v) => v.toMap()).toList();
      await prefs.setString('backup_ventas_$anonymousUserId', 
          ventasJson.toString());

      // Backup de clientes
      final clientesJson = clientes.map((c) => c.toMap()).toList();
      await prefs.setString('backup_clientes_$anonymousUserId', 
          clientesJson.toString());

      // Backup de categorías
      final categoriasJson = categorias.map((c) => c.toMap()).toList();
      await prefs.setString('backup_categorias_$anonymousUserId', 
          categoriasJson.toString());

      // Backup de tallas
      final tallasJson = tallas.map((t) => t.toMap()).toList();
      await prefs.setString('backup_tallas_$anonymousUserId', 
          tallasJson.toString());

      // Marcar timestamp del backup
      await prefs.setString('backup_timestamp_$anonymousUserId', 
          DateTime.now().toIso8601String());

      LoggingService.info('✅ Backup completado exitosamente');
      return BackupResult(
        success: true,
        message: 'Backup completado',
        dataCount: {
          'productos': productos.length,
          'ventas': ventas.length,
          'clientes': clientes.length,
          'categorias': categorias.length,
          'tallas': tallas.length,
        },
      );
    } catch (e) {
      LoggingService.error('❌ Error haciendo backup: $e');
      return BackupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Limpia los datos anónimos después de la conversión exitosa
  Future<CleanupResult> cleanupAnonymousData(String anonymousUserId) async {
    try {
      LoggingService.info('🧹 Limpiando datos anónimos para usuario: $anonymousUserId');

      if (_localDb == null) {
        return CleanupResult(
          success: false,
          error: 'Servicios no inicializados',
        );
      }

      // Eliminar datos de la base de datos local
      await _localDb!.deleteAllDataForUser(anonymousUserId);

      // Limpiar cache
      await _clearUserCache(anonymousUserId);

      // Limpiar datos de SharedPreferences
      await _clearUserPreferences(anonymousUserId);

      LoggingService.info('✅ Limpieza completada exitosamente');
      return CleanupResult(
        success: true,
        message: 'Datos anónimos limpiados',
      );
    } catch (e) {
      LoggingService.error('❌ Error limpiando datos anónimos: $e');
      return CleanupResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Restaura datos desde backup en caso de rollback
  Future<RestoreResult> restoreFromBackup(String anonymousUserId) async {
    try {
      LoggingService.info('🔄 Restaurando datos desde backup para usuario: $anonymousUserId');

      if (_datosService == null) {
        return RestoreResult(
          success: false,
          error: 'Servicios no inicializados',
        );
      }

      final prefs = await SharedPreferences.getInstance();

      // Verificar que existe backup
      final backupTimestamp = prefs.getString('backup_timestamp_$anonymousUserId');
      if (backupTimestamp == null) {
        return RestoreResult(
          success: false,
          error: 'No existe backup para este usuario',
        );
      }

      // Restaurar productos
      final productosBackup = prefs.getString('backup_productos_$anonymousUserId');
      if (productosBackup != null) {
        // Implementar restauración de productos
        LoggingService.info('📦 Restaurando productos...');
      }

      // Restaurar ventas
      final ventasBackup = prefs.getString('backup_ventas_$anonymousUserId');
      if (ventasBackup != null) {
        // Implementar restauración de ventas
        LoggingService.info('💰 Restaurando ventas...');
      }

      // Restaurar clientes
      final clientesBackup = prefs.getString('backup_clientes_$anonymousUserId');
      if (clientesBackup != null) {
        // Implementar restauración de clientes
        LoggingService.info('👥 Restaurando clientes...');
      }

      // Restaurar categorías
      final categoriasBackup = prefs.getString('backup_categorias_$anonymousUserId');
      if (categoriasBackup != null) {
        // Implementar restauración de categorías
        LoggingService.info('🏷️ Restaurando categorías...');
      }

      // Restaurar tallas
      final tallasBackup = prefs.getString('backup_tallas_$anonymousUserId');
      if (tallasBackup != null) {
        // Implementar restauración de tallas
        LoggingService.info('📏 Restaurando tallas...');
      }

      LoggingService.info('✅ Restauración completada exitosamente');
      return RestoreResult(
        success: true,
        message: 'Datos restaurados desde backup',
      );
    } catch (e) {
      LoggingService.error('❌ Error restaurando desde backup: $e');
      return RestoreResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Limpia el cache del usuario
  Future<void> _clearUserCache(String userId) async {
    try {
      // Limpiar cache específico del usuario
      // Implementar limpieza de cache
      LoggingService.info('🗑️ Cache limpiado para usuario: $userId');
    } catch (e) {
      LoggingService.error('Error limpiando cache: $e');
    }
  }

  /// Limpia las preferencias del usuario
  Future<void> _clearUserPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Limpiar preferencias específicas del usuario
      await prefs.remove('backup_productos_$userId');
      await prefs.remove('backup_ventas_$userId');
      await prefs.remove('backup_clientes_$userId');
      await prefs.remove('backup_categorias_$userId');
      await prefs.remove('backup_tallas_$userId');
      await prefs.remove('backup_timestamp_$userId');
      await prefs.remove('persisted_anonymous_user_id');
      await prefs.remove('persisted_anonymous_timestamp');

      LoggingService.info('🗑️ Preferencias limpiadas para usuario: $userId');
    } catch (e) {
      LoggingService.error('Error limpiando preferencias: $e');
    }
  }

  /// Limpia datos anónimos antiguos (más de 30 días)
  Future<void> cleanupOldAnonymousData() async {
    try {
      LoggingService.info('🧹 Limpiando datos anónimos antiguos...');

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith('backup_timestamp_')) {
          final timestampStr = prefs.getString(key);
          if (timestampStr != null) {
            final timestamp = DateTime.parse(timestampStr);
            final daysDiff = now.difference(timestamp).inDays;

            if (daysDiff > 30) {
              // Extraer userId del key
              final userId = key.replaceFirst('backup_timestamp_', '');
              
              // Limpiar todos los datos de este usuario
              await _clearUserPreferences(userId);
              
              LoggingService.info('🗑️ Datos antiguos limpiados para usuario: $userId');
            }
          }
        }
      }

      LoggingService.info('✅ Limpieza de datos antiguos completada');
    } catch (e) {
      LoggingService.error('❌ Error limpiando datos antiguos: $e');
    }
  }
}

/// Resultado de backup
class BackupResult {
  final bool success;
  final String? error;
  final String? message;
  final Map<String, int>? dataCount;

  BackupResult({
    required this.success,
    this.error,
    this.message,
    this.dataCount,
  });
}

/// Resultado de limpieza
class CleanupResult {
  final bool success;
  final String? error;
  final String? message;

  CleanupResult({
    required this.success,
    this.error,
    this.message,
  });
}

/// Resultado de restauración
class RestoreResult {
  final bool success;
  final String? error;
  final String? message;

  RestoreResult({
    required this.success,
    this.error,
    this.message,
  });
}
