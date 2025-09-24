import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/auth/supabase_auth_service.dart';
import 'package:stockcito/services/system/backup_conflict_resolver.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/categoria.dart';
import 'package:stockcito/models/talla.dart';
import 'package:stockcito/models/venta.dart';
import 'package:stockcito/models/cliente.dart';

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

  /// Comprime archivo de backup a ZIP
  Future<void> _compressBackup(File backupFile) async {
    try {
      LoggingService.info('🗜️ Comprimiendo backup a ZIP...');
      
      // Leer contenido del archivo JSON
      final jsonContent = await backupFile.readAsString();
      final jsonBytes = utf8.encode(jsonContent);
      
      // Crear archivo ZIP
      final archive = Archive();
      final fileName = backupFile.path.split('/').last;
      archive.addFile(ArchiveFile(fileName, jsonBytes.length, jsonBytes));
      
      // Comprimir a ZIP
      final zipEncoder = ZipEncoder();
      final zipBytes = zipEncoder.encode(archive);
      
      if (zipBytes == null) {
        throw Exception('Error al comprimir el archivo ZIP');
      }
      
      // Crear archivo ZIP
      final zipPath = backupFile.path.replaceAll('.json', '.zip');
      final zipFile = File(zipPath);
      await zipFile.writeAsBytes(zipBytes);
      
      // Verificar integridad del ZIP
      await _verifyZipIntegrity(zipFile, jsonBytes);
      
      // Eliminar archivo JSON original
      await backupFile.delete();
      
      LoggingService.info('✅ Backup comprimido exitosamente: $zipPath');
      LoggingService.info('📊 Reducción de tamaño: ${((jsonBytes.length - zipBytes.length) / jsonBytes.length * 100).toStringAsFixed(1)}%');
    } catch (e) {
      LoggingService.error('❌ Error comprimiendo backup: $e');
      // Si falla la compresión, mantener el archivo original
      LoggingService.info('⚠️ Manteniendo archivo JSON original debido a error de compresión');
    }
  }

  /// Verifica la integridad del archivo ZIP creado
  Future<void> _verifyZipIntegrity(File zipFile, List<int> originalBytes) async {
    try {
      // Leer y descomprimir el ZIP
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      
      if (archive.isEmpty) {
        throw Exception('ZIP vacío');
      }
      
      final extractedFile = archive.first;
      final extractedBytes = extractedFile.content as List<int>;
      
      // Comparar con bytes originales
      if (extractedBytes.length != originalBytes.length) {
        throw Exception('Tamaño de archivo extraído no coincide');
      }
      
      for (int i = 0; i < originalBytes.length; i++) {
        if (extractedBytes[i] != originalBytes[i]) {
          throw Exception('Contenido extraído no coincide en posición $i');
        }
      }
      
      LoggingService.info('✅ Integridad del ZIP verificada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error verificando integridad del ZIP: $e');
      // Eliminar ZIP corrupto
      await zipFile.delete();
      rethrow;
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

  /// Analiza un archivo de backup y retorna información detallada
  Future<Map<String, dynamic>> analyzeBackup(String backupPath) async {
    try {
      LoggingService.info('🔍 Analizando backup: $backupPath');
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('El archivo de backup no existe');
      }
      
      // Leer contenido del backup
      String content;
      if (backupPath.endsWith('.zip')) {
        content = await _extractZipContent(backupFile);
      } else {
        content = await backupFile.readAsString();
      }
      
      final backupData = jsonDecode(content) as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;
      
      // Verificar checksum
      final expectedChecksum = backupData['checksum'] as String;
      final actualChecksum = _calculateChecksum(data);
      
      if (expectedChecksum != actualChecksum) {
        throw Exception('Checksum inválido - el backup puede estar corrupto');
      }
      
      // Generar información del backup
      return {
        'version': backupData['version'],
        'type': backupData['type'],
        'timestamp': backupData['timestamp'],
        'user_id': backupData['user_id'],
        'checksum': expectedChecksum,
        'productos_count': (data['productos'] as List?)?.length ?? 0,
        'ventas_count': (data['ventas'] as List?)?.length ?? 0,
        'clientes_count': (data['clientes'] as List?)?.length ?? 0,
        'categorias_count': (data['categorias'] as List?)?.length ?? 0,
        'tallas_count': (data['tallas'] as List?)?.length ?? 0,
        'file_size': await backupFile.length(),
        'file_path': backupPath,
      };
    } catch (e) {
      LoggingService.error('❌ Error analizando backup: $e');
      rethrow;
    }
  }

  /// Extrae contenido de un archivo ZIP
  Future<String> _extractZipContent(File zipFile) async {
    try {
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      
      if (archive.isEmpty) {
        throw Exception('El archivo ZIP está vacío');
      }
      
      final file = archive.first;
      final content = utf8.decode(file.content as List<int>);
      return content;
    } catch (e) {
      LoggingService.error('Error extrayendo contenido ZIP: $e');
      rethrow;
    }
  }

  /// Restaura datos desde backup
  Future<void> restoreFromBackup(String backupPath) async {
    try {
      LoggingService.info('🔄 Restaurando desde backup: $backupPath');
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('El archivo de backup no existe');
      }
      
      // Leer contenido del backup
      String content;
      if (backupPath.endsWith('.zip')) {
        content = await _extractZipContent(backupFile);
      } else {
        content = await backupFile.readAsString();
      }
      
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
      LoggingService.info('🔄 Iniciando restauración de ${data.keys.length} tipos de datos');
      
      // Crear backup de seguridad de datos actuales
      await _createSafetyBackup();
      
      // Restaurar productos
      if (data.containsKey('productos')) {
        await _restoreProductos(data['productos'] as List<dynamic>);
      }
      
      // Restaurar categorías
      if (data.containsKey('categorias')) {
        await _restoreCategorias(data['categorias'] as List<dynamic>);
      }
      
      // Restaurar tallas
      if (data.containsKey('tallas')) {
        await _restoreTallas(data['tallas'] as List<dynamic>);
      }
      
      // Restaurar ventas
      if (data.containsKey('ventas')) {
        await _restoreVentas(data['ventas'] as List<dynamic>);
      }
      
      // Restaurar clientes
      if (data.containsKey('clientes')) {
        await _restoreClientes(data['clientes'] as List<dynamic>);
      }
      
      // Restaurar configuración
      if (data.containsKey('configuracion')) {
        await _restoreConfiguracion(data['configuracion'] as Map<String, dynamic>);
      }
      
      // Limpiar cache y forzar sincronización
      _datosService.clearCache();
      _datosService.forceSync();
      
      LoggingService.info('✅ Restauración de datos completada exitosamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando datos: $e');
      rethrow;
    }
  }

  /// Crea un backup de seguridad antes de restaurar
  Future<void> _createSafetyBackup() async {
    try {
      LoggingService.info('🛡️ Creando backup de seguridad...');
      await performBackup(BackupType.complete);
      LoggingService.info('✅ Backup de seguridad creado');
    } catch (e) {
      LoggingService.error('⚠️ Error creando backup de seguridad: $e');
      // No fallar la restauración por esto, solo advertir
    }
  }

  /// Restaura productos desde backup
  Future<void> _restoreProductos(List<dynamic> productosData) async {
    try {
      LoggingService.info('📦 Restaurando ${productosData.length} productos...');
      
      for (final productoData in productosData) {
        try {
          // Verificar si el producto ya existe
          final existingProductos = await _datosService.getProductos();
          Producto? existingProducto;
          try {
            existingProducto = existingProductos.firstWhere(
              (p) => p.id == productoData['id'],
            );
          } catch (e) {
            existingProducto = null;
          }
          
          if (existingProducto != null) {
            // Resolver conflicto
            final conflictResolver = BackupConflictResolver();
            final resolution = await conflictResolver.resolveConflict(
              entityType: 'producto',
              entityId: productoData['id'].toString(),
              existingData: existingProducto.toMap(),
              backupData: Map<String, dynamic>.from(productoData),
              conflictType: ConflictType.entityExists,
            );
            
            if (resolution.action == ConflictAction.replace) {
              final updatedProducto = Producto(
                id: existingProducto.id,
                nombre: productoData['nombre'],
                categoria: productoData['categoria'],
                talla: productoData['talla'],
                costoMateriales: productoData['costoMateriales']?.toDouble() ?? existingProducto.costoMateriales,
                costoManoObra: productoData['costoManoObra']?.toDouble() ?? existingProducto.costoManoObra,
                gastosGenerales: productoData['gastosGenerales']?.toDouble() ?? existingProducto.gastosGenerales,
                margenGanancia: productoData['margenGanancia']?.toDouble() ?? existingProducto.margenGanancia,
                stock: productoData['stock'] ?? existingProducto.stock,
                fechaCreacion: existingProducto.fechaCreacion,
              );
              await _datosService.updateProducto(updatedProducto);
            }
          } else {
            // Crear nuevo producto
            final nuevoProducto = Producto(
              id: productoData['id'],
              nombre: productoData['nombre'],
              categoria: productoData['categoria'],
              talla: productoData['talla'],
              costoMateriales: productoData['costoMateriales']?.toDouble() ?? 0.0,
              costoManoObra: productoData['costoManoObra']?.toDouble() ?? 0.0,
              gastosGenerales: productoData['gastosGenerales']?.toDouble() ?? 0.0,
              margenGanancia: productoData['margenGanancia']?.toDouble() ?? 0.0,
              stock: productoData['stock'] ?? 0,
              fechaCreacion: DateTime.parse(productoData['fechaCreacion']),
            );
            await _datosService.saveProducto(nuevoProducto);
          }
        } catch (e) {
          LoggingService.error('Error restaurando producto ${productoData['id']}: $e');
          // Continuar con el siguiente producto
        }
      }
      
      LoggingService.info('✅ Productos restaurados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando productos: $e');
      rethrow;
    }
  }

  /// Restaura categorías desde backup
  Future<void> _restoreCategorias(List<dynamic> categoriasData) async {
    try {
      LoggingService.info('🏷️ Restaurando ${categoriasData.length} categorías...');
      
      for (final categoriaData in categoriasData) {
        try {
          final existingCategorias = await _datosService.getCategorias();
          Categoria? existingCategoria;
          try {
            existingCategoria = existingCategorias.firstWhere(
              (c) => c.id == categoriaData['id'],
            );
          } catch (e) {
            existingCategoria = null;
          }
          
          if (existingCategoria == null) {
            await _datosService.saveCategoria(Categoria(
              id: categoriaData['id'],
              nombre: categoriaData['nombre'],
              color: categoriaData['color'] ?? '#3B82F6',
              icono: categoriaData['icono'] ?? 'tag',
              descripcion: categoriaData['descripcion'],
              userId: categoriaData['userId'] ?? _authService.currentUserId ?? 'default',
              fechaCreacion: DateTime.parse(categoriaData['fechaCreacion']),
              updatedAt: DateTime.now(),
              isDefault: categoriaData['isDefault'] ?? false,
            ));
          }
        } catch (e) {
          LoggingService.error('Error restaurando categoría ${categoriaData['id']}: $e');
        }
      }
      
      LoggingService.info('✅ Categorías restauradas correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando categorías: $e');
      rethrow;
    }
  }

  /// Restaura tallas desde backup
  Future<void> _restoreTallas(List<dynamic> tallasData) async {
    try {
      LoggingService.info('📏 Restaurando ${tallasData.length} tallas...');
      
      for (final tallaData in tallasData) {
        try {
          final existingTallas = await _datosService.getTallas();
          Talla? existingTalla;
          try {
            existingTalla = existingTallas.firstWhere(
              (t) => t.id == tallaData['id'],
            );
          } catch (e) {
            existingTalla = null;
          }
          
          if (existingTalla == null) {
            await _datosService.saveTalla(Talla(
              id: tallaData['id'],
              nombre: tallaData['nombre'],
              descripcion: tallaData['descripcion'],
              userId: tallaData['userId'] ?? _authService.currentUserId ?? 'default',
              fechaCreacion: DateTime.parse(tallaData['fechaCreacion']),
              updatedAt: DateTime.now(),
            ));
          }
        } catch (e) {
          LoggingService.error('Error restaurando talla ${tallaData['id']}: $e');
        }
      }
      
      LoggingService.info('✅ Tallas restauradas correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando tallas: $e');
      rethrow;
    }
  }

  /// Restaura ventas desde backup
  Future<void> _restoreVentas(List<dynamic> ventasData) async {
    try {
      LoggingService.info('🛒 Restaurando ${ventasData.length} ventas...');
      
      for (final ventaData in ventasData) {
        try {
          final existingVentas = await _datosService.getVentas();
          Venta? existingVenta;
          try {
            existingVenta = existingVentas.firstWhere(
              (v) => v.id == ventaData['id'],
            );
          } catch (e) {
            existingVenta = null;
          }
          
          if (existingVenta == null) {
            // Crear nueva venta
            final nuevaVenta = Venta(
              id: ventaData['id'],
              cliente: ventaData['cliente'],
              telefono: ventaData['telefono'],
              email: ventaData['email'],
              total: ventaData['total']?.toDouble() ?? 0.0,
              fecha: DateTime.parse(ventaData['fecha']),
              metodoPago: ventaData['metodoPago'],
              estado: ventaData['estado'],
              notas: ventaData['notas'] ?? '',
              items: (ventaData['items'] as List<dynamic>).map((item) => VentaItem(
                id: item['id'],
                ventaId: ventaData['id'],
                productoId: item['productoId'],
                nombreProducto: item['nombreProducto'],
                categoria: item['categoria'] ?? 'Sin categoría',
                talla: item['talla'] ?? 'Sin talla',
                cantidad: item['cantidad'],
                precioUnitario: item['precioUnitario']?.toDouble() ?? 0.0,
                subtotal: item['subtotal']?.toDouble() ?? 0.0,
              )).toList(),
            );
            await _datosService.saveVenta(nuevaVenta);
          }
        } catch (e) {
          LoggingService.error('Error restaurando venta ${ventaData['id']}: $e');
        }
      }
      
      LoggingService.info('✅ Ventas restauradas correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando ventas: $e');
      rethrow;
    }
  }

  /// Restaura clientes desde backup
  Future<void> _restoreClientes(List<dynamic> clientesData) async {
    try {
      LoggingService.info('👥 Restaurando ${clientesData.length} clientes...');
      
      for (final clienteData in clientesData) {
        try {
          final existingClientes = await _datosService.getClientes();
          Cliente? existingCliente;
          try {
            existingCliente = existingClientes.firstWhere(
              (c) => c.id == clienteData['id'],
            );
          } catch (e) {
            existingCliente = null;
          }
          
          if (existingCliente == null) {
            final nuevoCliente = Cliente(
              id: clienteData['id'],
              nombre: clienteData['nombre'],
              telefono: clienteData['telefono'],
              email: clienteData['email'],
              direccion: clienteData['direccion'],
              fechaRegistro: DateTime.parse(clienteData['fechaRegistro']),
              notas: clienteData['notas'] ?? '',
              totalCompras: clienteData['totalCompras'] ?? 0,
              totalGastado: clienteData['totalGastado']?.toDouble() ?? 0.0,
            );
            await _datosService.saveCliente(nuevoCliente);
          }
        } catch (e) {
          LoggingService.error('Error restaurando cliente ${clienteData['id']}: $e');
        }
      }
      
      LoggingService.info('✅ Clientes restaurados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando clientes: $e');
      rethrow;
    }
  }

  /// Restaura configuración desde backup
  Future<void> _restoreConfiguracion(Map<String, dynamic> configData) async {
    try {
      LoggingService.info('⚙️ Restaurando configuración...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Restaurar configuraciones específicas
      for (final entry in configData.entries) {
        if (entry.value is String) {
          await prefs.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else if (entry.value is double) {
          await prefs.setDouble(entry.key, entry.value);
        } else if (entry.value is bool) {
          await prefs.setBool(entry.key, entry.value);
        }
      }
      
      LoggingService.info('✅ Configuración restaurada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error restaurando configuración: $e');
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
