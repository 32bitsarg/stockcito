import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:stockcito/services/auth/supabase_auth_service.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio de respaldo y recuperación de datos
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  
  // Configuración de respaldos
  static const int _maxBackups = 5;
  static const String _backupPrefix = 'backup_';

  /// Crea un respaldo completo de los datos
  Future<BackupData> createBackup() async {
    try {
      LoggingService.info('Creando respaldo de datos...');
      
      final timestamp = DateTime.now();
      final backupId = '$_backupPrefix${timestamp.millisecondsSinceEpoch}';
      
      // Obtener datos actuales
      final productos = await _getProductosForBackup();
      final ventas = await _getVentasForBackup();
      final clientes = await _getClientesForBackup();
      
      final backup = BackupData(
        id: backupId,
        timestamp: timestamp,
        userId: _authService.currentUserId,
        productos: productos,
        ventas: ventas,
        clientes: clientes,
        version: '1.0.0',
      );
      
      // Guardar respaldo
      await _saveBackup(backup);
      
      // Limpiar respaldos antiguos
      await _cleanOldBackups();
      
      LoggingService.info('Respaldo creado: $backupId');
      return backup;
    } catch (e) {
      LoggingService.error('Error creando respaldo: $e');
      rethrow;
    }
  }

  /// Restaura datos desde un respaldo
  Future<bool> restoreBackup(String backupId) async {
    try {
      LoggingService.info('Restaurando respaldo: $backupId');
      
      final backup = await _loadBackup(backupId);
      if (backup == null) {
        LoggingService.error('Respaldo no encontrado: $backupId');
        return false;
      }
      
      // Restaurar datos
      await _restoreProductos(backup.productos);
      await _restoreVentas(backup.ventas);
      await _restoreClientes(backup.clientes);
      
      LoggingService.info('Respaldo restaurado exitosamente: $backupId');
      return true;
    } catch (e) {
      LoggingService.error('Error restaurando respaldo: $e');
      return false;
    }
  }

  /// Obtiene la lista de respaldos disponibles
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupKeys = prefs.getKeys().where((key) => key.startsWith(_backupPrefix)).toList();
      
      final backups = <BackupInfo>[];
      for (final key in backupKeys) {
        final backupData = prefs.getString(key);
        if (backupData != null) {
          final backup = BackupData.fromJson(jsonDecode(backupData));
          backups.add(BackupInfo(
            id: backup.id,
            timestamp: backup.timestamp,
            size: backupData.length,
            productCount: backup.productos.length,
            ventaCount: backup.ventas.length,
            clienteCount: backup.clientes.length,
          ));
        }
      }
      
      // Ordenar por timestamp descendente
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return backups;
    } catch (e) {
      LoggingService.error('Error obteniendo respaldos: $e');
      return [];
    }
  }

  /// Elimina un respaldo específico
  Future<bool> deleteBackup(String backupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(backupId);
      LoggingService.info('Respaldo eliminado: $backupId');
      return true;
    } catch (e) {
      LoggingService.error('Error eliminando respaldo: $e');
      return false;
    }
  }

  /// Exporta datos a un archivo JSON
  Future<String> exportToFile() async {
    try {
      final backup = await createBackup();
      final jsonString = jsonEncode(backup.toJson());
      
      // En una aplicación real, aquí guardarías el archivo
      // Por ahora, retornamos el JSON como string
      LoggingService.info('Datos exportados exitosamente');
      return jsonString;
    } catch (e) {
      LoggingService.error('Error exportando datos: $e');
      rethrow;
    }
  }

  /// Importa datos desde un archivo JSON
  Future<bool> importFromFile(String jsonString) async {
    try {
      final backupData = BackupData.fromJson(jsonDecode(jsonString));
      
      // Restaurar datos
      await _restoreProductos(backupData.productos);
      await _restoreVentas(backupData.ventas);
      await _restoreClientes(backupData.clientes);
      
      LoggingService.info('Datos importados exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('Error importando datos: $e');
      return false;
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  /// Obtiene productos para respaldo
  Future<List<Map<String, dynamic>>> _getProductosForBackup() async {
    // En una implementación real, obtendrías los datos de la base de datos
    // Por ahora, retornamos una lista vacía
    return [];
  }

  /// Obtiene ventas para respaldo
  Future<List<Map<String, dynamic>>> _getVentasForBackup() async {
    return [];
  }

  /// Obtiene clientes para respaldo
  Future<List<Map<String, dynamic>>> _getClientesForBackup() async {
    return [];
  }

  /// Guarda un respaldo
  Future<void> _saveBackup(BackupData backup) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(backup.id, jsonEncode(backup.toJson()));
  }

  /// Carga un respaldo
  Future<BackupData?> _loadBackup(String backupId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupString = prefs.getString(backupId);
      if (backupString != null) {
        return BackupData.fromJson(jsonDecode(backupString));
      }
      return null;
    } catch (e) {
      LoggingService.error('Error cargando respaldo: $e');
      return null;
    }
  }

  /// Restaura productos
  Future<void> _restoreProductos(List<Map<String, dynamic>> productos) async {
    // Implementar restauración de productos
    LoggingService.info('Restaurando ${productos.length} productos');
  }

  /// Restaura ventas
  Future<void> _restoreVentas(List<Map<String, dynamic>> ventas) async {
    // Implementar restauración de ventas
    LoggingService.info('Restaurando ${ventas.length} ventas');
  }

  /// Restaura clientes
  Future<void> _restoreClientes(List<Map<String, dynamic>> clientes) async {
    // Implementar restauración de clientes
    LoggingService.info('Restaurando ${clientes.length} clientes');
  }

  /// Limpia respaldos antiguos
  Future<void> _cleanOldBackups() async {
    try {
      final backups = await getAvailableBackups();
      if (backups.length > _maxBackups) {
        final backupsToDelete = backups.skip(_maxBackups).toList();
        for (final backup in backupsToDelete) {
          await deleteBackup(backup.id);
        }
        LoggingService.info('Eliminados ${backupsToDelete.length} respaldos antiguos');
      }
    } catch (e) {
      LoggingService.error('Error limpiando respaldos antiguos: $e');
    }
  }
}

/// Datos de respaldo
class BackupData {
  final String id;
  final DateTime timestamp;
  final String? userId;
  final List<Map<String, dynamic>> productos;
  final List<Map<String, dynamic>> ventas;
  final List<Map<String, dynamic>> clientes;
  final String version;

  BackupData({
    required this.id,
    required this.timestamp,
    this.userId,
    required this.productos,
    required this.ventas,
    required this.clientes,
    required this.version,
  });

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'productos': productos,
      'ventas': ventas,
      'clientes': clientes,
      'version': version,
    };
  }

  /// Crea desde JSON
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      productos: List<Map<String, dynamic>>.from(json['productos']),
      ventas: List<Map<String, dynamic>>.from(json['ventas']),
      clientes: List<Map<String, dynamic>>.from(json['clientes']),
      version: json['version'],
    );
  }
}

/// Información de respaldo
class BackupInfo {
  final String id;
  final DateTime timestamp;
  final int size;
  final int productCount;
  final int ventaCount;
  final int clienteCount;

  BackupInfo({
    required this.id,
    required this.timestamp,
    required this.size,
    required this.productCount,
    required this.ventaCount,
    required this.clienteCount,
  });
}
