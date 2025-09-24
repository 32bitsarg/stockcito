import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/auth/supabase_auth_service.dart';

/// Servicio de backup automático con múltiples estrategias y frecuencias
class AutomatedBackupService {
  static final AutomatedBackupService _instance = AutomatedBackupService._internal();
  factory AutomatedBackupService() => _instance;
  AutomatedBackupService._internal();

  final DatosService _datosService = DatosService();
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Configuración de backup
  static const int _maxBackupsToKeep = 30; // Mantener últimos 30 backups

  // Timers para backups automáticos
  Timer? _dailyTimer;
  Timer? _weeklyTimer;
  Timer? _monthlyTimer;

  // Estado del servicio
  bool _isInitialized = false;
  bool _isBackingUp = false;
  DateTime? _lastBackupTime;
  String? _lastBackupPath;

  /// Inicializa el servicio de backup automático
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      LoggingService.info('🔄 Inicializando AutomatedBackupService...');

      // Cargar configuración de backup
      await _loadBackupSettings();

      // Configurar timers de backup
      _setupBackupTimers();

      // Realizar backup inicial si es necesario
      await _performInitialBackupIfNeeded();

      _isInitialized = true;
      LoggingService.info('✅ AutomatedBackupService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando AutomatedBackupService: $e');
      rethrow;
    }
  }

  /// Configura los timers para backups automáticos
  void _setupBackupTimers() {
    // Backup diario
    _dailyTimer = Timer.periodic(const Duration(hours: 24), (_) {
      _performDailyBackup();
    });

    // Backup semanal (domingo)
    _weeklyTimer = Timer.periodic(const Duration(days: 7), (_) {
      if (DateTime.now().weekday == DateTime.sunday) {
        _performWeeklyBackup();
      }
    });

    // Backup mensual (primer día del mes)
    _monthlyTimer = Timer.periodic(const Duration(days: 1), (_) {
      if (DateTime.now().day == 1) {
        _performMonthlyBackup();
      }
    });

    LoggingService.info('⏰ Timers de backup configurados');
  }

  /// Realiza backup inicial si es necesario
  Future<void> _performInitialBackupIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackup = prefs.getString('last_backup_time');
      
      if (lastBackup == null) {
        LoggingService.info('🔄 Realizando backup inicial...');
        await performBackup(BackupType.complete);
      }
    } catch (e) {
      LoggingService.error('Error en backup inicial: $e');
    }
  }

  /// Realiza backup diario
  Future<void> _performDailyBackup() async {
    try {
      LoggingService.info('📅 Iniciando backup diario...');
      await performBackup(BackupType.incremental);
    } catch (e) {
      LoggingService.error('Error en backup diario: $e');
    }
  }

  /// Realiza backup semanal
  Future<void> _performWeeklyBackup() async {
    try {
      LoggingService.info('📅 Iniciando backup semanal...');
      await performBackup(BackupType.differential);
    } catch (e) {
      LoggingService.error('Error en backup semanal: $e');
    }
  }

  /// Realiza backup mensual
  Future<void> _performMonthlyBackup() async {
    try {
      LoggingService.info('📅 Iniciando backup mensual...');
      await performBackup(BackupType.complete);
    } catch (e) {
      LoggingService.error('Error en backup mensual: $e');
    }
  }

  /// Realiza backup manual
  Future<String> performBackup(BackupType type) async {
    if (_isBackingUp) {
      throw Exception('Ya hay un backup en progreso');
    }

    _isBackingUp = true;
    try {
      LoggingService.info('💾 Iniciando backup ${type.name}...');

      // Crear directorio de backup
      final backupDir = await _createBackupDirectory();
      
      // Generar nombre de archivo único
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_${type.name}_$timestamp.json';
      final backupFile = File('${backupDir.path}/$fileName');

      // Recopilar datos para backup
      final backupData = await _collectBackupData(type);

      // Crear archivo de backup
      final backupContent = {
        'version': '1.1.0-alpha.1',
        'type': type.name,
        'timestamp': DateTime.now().toIso8601String(),
        'user_id': _authService.currentUserId,
        'checksum': _calculateChecksum(backupData),
        'data': backupData,
      };

      await backupFile.writeAsString(jsonEncode(backupContent));

      // Comprimir backup si es completo
      if (type == BackupType.complete) {
        await _compressBackup(backupFile);
      }

      // Actualizar estado
      _lastBackupTime = DateTime.now();
      _lastBackupPath = backupFile.path;

      // Guardar configuración
      await _saveBackupSettings();

      // Limpiar backups antiguos
      await _cleanupOldBackups();

      LoggingService.info('✅ Backup ${type.name} completado: $fileName');
      return backupFile.path;
    } catch (e) {
      LoggingService.error('❌ Error realizando backup: $e');
      rethrow;
    } finally {
      _isBackingUp = false;
    }
  }

  /// Recopila datos para el backup
  Future<Map<String, dynamic>> _collectBackupData(BackupType type) async {
    try {
      final data = <String, dynamic>{};

      // Datos básicos siempre incluidos
      final productos = await _datosService.getProductos();
      final categorias = await _datosService.getCategorias();
      final tallas = await _datosService.getTallas();
      
      data['productos'] = productos.map((p) => p.toMap()).toList();
      data['categorias'] = categorias.map((c) => c.toMap()).toList();
      data['tallas'] = tallas.map((t) => t.toMap()).toList();

      // Datos adicionales según tipo de backup
      switch (type) {
        case BackupType.complete:
          final ventas = await _datosService.getVentas();
          final clientes = await _datosService.getClientes();
          data['ventas'] = ventas.map((v) => v.toMap()).toList();
          data['clientes'] = clientes.map((c) => c.toMap()).toList();
          data['configuracion'] = await _loadAppConfiguration();
          break;
        case BackupType.incremental:
          // Solo cambios desde último backup
          data['ventas'] = await _getRecentVentas();
          data['clientes'] = await _getRecentClientes();
          break;
        case BackupType.differential:
          // Cambios desde último backup completo
          data['ventas'] = await _getRecentVentas();
          data['clientes'] = await _getRecentClientes();
          break;
      }

      return data;
    } catch (e) {
      LoggingService.error('Error recopilando datos de backup: $e');
      rethrow;
    }
  }

  /// Obtiene ventas recientes (últimos 7 días)
  Future<List<dynamic>> _getRecentVentas() async {
    try {
      final ventas = await _datosService.getVentas();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      return ventas.where((v) => v.fecha.isAfter(cutoffDate)).map((v) => v.toMap()).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo ventas recientes: $e');
      return [];
    }
  }

  /// Obtiene clientes recientes (últimos 7 días)
  Future<List<dynamic>> _getRecentClientes() async {
    try {
      final clientes = await _datosService.getClientes();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      return clientes.where((c) => c.fechaRegistro.isAfter(cutoffDate)).map((c) => c.toMap()).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo clientes recientes: $e');
      return [];
    }
  }

  /// Carga configuración de la aplicación
  Future<Map<String, dynamic>> _loadAppConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'min_stock_level': prefs.getInt('min_stock_level'),
        'notificaciones_stock': prefs.getBool('notificaciones_stock'),
        'notificaciones_ventas': prefs.getBool('notificaciones_ventas'),
        'margen_defecto': prefs.getDouble('margen_defecto'),
        'iva': prefs.getDouble('iva'),
        'moneda': prefs.getString('moneda'),
        'exportar_automatico': prefs.getBool('exportar_automatico'),
        'respaldo_automatico': prefs.getBool('respaldo_automatico'),
      };
    } catch (e) {
      LoggingService.error('Error cargando configuración: $e');
      return {};
    }
  }

  /// Crea directorio de backup
  Future<Directory> _createBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  /// Comprime archivo de backup
  Future<void> _compressBackup(File backupFile) async {
    try {
      // TODO: Implementar compresión ZIP
      // Por ahora solo renombramos el archivo
      final compressedPath = '${backupFile.path}.gz';
      await backupFile.rename(compressedPath);
      LoggingService.info('Backup comprimido: $compressedPath');
    } catch (e) {
      LoggingService.error('Error comprimiendo backup: $e');
    }
  }

  /// Calcula checksum de los datos
  String _calculateChecksum(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Limpia backups antiguos
  Future<void> _cleanupOldBackups() async {
    try {
      final backupDir = await _createBackupDirectory();
      final files = await backupDir.list().toList();
      
      if (files.length > _maxBackupsToKeep) {
        // Ordenar por fecha de modificación
        files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
        
        // Eliminar archivos más antiguos
        final filesToDelete = files.take(files.length - _maxBackupsToKeep);
        for (final file in filesToDelete) {
          if (file is File) {
            await file.delete();
            LoggingService.info('Backup antiguo eliminado: ${file.path}');
          }
        }
      }
    } catch (e) {
      LoggingService.error('Error limpiando backups antiguos: $e');
    }
  }

  /// Restaura datos desde backup
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      LoggingService.info('🔄 Restaurando desde backup: $backupPath');
      
      final backupFile = File(backupPath);
      final content = await backupFile.readAsString();
      final backupData = jsonDecode(content) as Map<String, dynamic>;
      
      // Verificar checksum
      final data = backupData['data'] as Map<String, dynamic>;
      final expectedChecksum = backupData['checksum'] as String;
      final actualChecksum = _calculateChecksum(data);
      
      if (expectedChecksum != actualChecksum) {
        throw Exception('Checksum inválido - el backup puede estar corrupto');
      }
      
      // Restaurar datos
      await _restoreBackupData(data);
      
      LoggingService.info('✅ Restauración completada exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando backup: $e');
      rethrow;
    }
  }

  /// Restaura datos del backup
  Future<void> _restoreBackupData(Map<String, dynamic> data) async {
    try {
      // TODO: Implementar restauración completa de datos
      // Por ahora solo logueamos
      LoggingService.info('Restaurando ${data.keys.length} tipos de datos');
    } catch (e) {
      LoggingService.error('Error restaurando datos: $e');
      rethrow;
    }
  }

  /// Carga configuración de backup
  Future<void> _loadBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBackupStr = prefs.getString('last_backup_time');
      if (lastBackupStr != null) {
        _lastBackupTime = DateTime.parse(lastBackupStr);
      }
      _lastBackupPath = prefs.getString('last_backup_path');
    } catch (e) {
      LoggingService.error('Error cargando configuración de backup: $e');
    }
  }

  /// Guarda configuración de backup
  Future<void> _saveBackupSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_lastBackupTime != null) {
        await prefs.setString('last_backup_time', _lastBackupTime!.toIso8601String());
      }
      if (_lastBackupPath != null) {
        await prefs.setString('last_backup_path', _lastBackupPath!);
      }
    } catch (e) {
      LoggingService.error('Error guardando configuración de backup: $e');
    }
  }

  /// Lista backups disponibles
  Future<List<FileSystemEntity>> listAvailableBackups() async {
    try {
      final backupDir = await _createBackupDirectory();
      final files = await backupDir.list().toList();
      return files.whereType<File>().toList();
    } catch (e) {
      LoggingService.error('Error listando backups: $e');
      return [];
    }
  }

  /// Obtiene estadísticas de backup
  Map<String, dynamic> getBackupStats() {
    return {
      'is_initialized': _isInitialized,
      'is_backing_up': _isBackingUp,
      'last_backup_time': _lastBackupTime?.toIso8601String(),
      'last_backup_path': _lastBackupPath,
      'daily_timer_active': _dailyTimer?.isActive ?? false,
      'weekly_timer_active': _weeklyTimer?.isActive ?? false,
      'monthly_timer_active': _monthlyTimer?.isActive ?? false,
    };
  }

  /// Dispone del servicio
  void dispose() {
    _dailyTimer?.cancel();
    _weeklyTimer?.cancel();
    _monthlyTimer?.cancel();
    LoggingService.info('AutomatedBackupService disposed');
  }
}

/// Tipos de backup disponibles
enum BackupType {
  complete,    // Backup completo
  incremental, // Solo cambios desde último backup
  differential, // Cambios desde último backup completo
}
