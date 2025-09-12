import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../../../models/producto.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../logging_service.dart';

/// Servicio para manejo de base de datos local SQLite
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Wrapper para manejar errores en operaciones de base de datos
  Future<T> _handleDatabaseOperation<T>(
    Future<T> Function() operation,
    String operationName, {
    T? defaultValue,
  }) async {
    try {
      LoggingService.database(operationName);
      final result = await operation();
      LoggingService.database('$operationName completed successfully');
      return result;
    } catch (e, stackTrace) {
      LoggingService.error(
        'Database operation failed: $operationName',
        tag: 'DATABASE',
        error: e,
        stackTrace: stackTrace,
      );
      
      // Re-lanzar la excepción para que sea manejada por el ErrorHandlerService
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      // Configurar para escritorio si es necesario
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'ricitosdebb.db');

      return await openDatabase(
        path,
        version: 2,
        onCreate: _createTables,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      LoggingService.error('Error inicializando base de datos: $e');
      rethrow;
    }
  }

  Future<void> _createTables(Database db, int version) async {
    try {
      // Tabla de productos
      await db.execute('''
        CREATE TABLE productos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          categoria TEXT NOT NULL,
          talla TEXT NOT NULL,
          costo_materiales REAL NOT NULL,
          costo_mano_obra REAL NOT NULL,
          gastos_generales REAL NOT NULL,
          margen_ganancia REAL NOT NULL,
          stock INTEGER NOT NULL,
          fecha_creacion TEXT NOT NULL
        )
      ''');

      // Tabla de clientes
      await db.execute('''
        CREATE TABLE clientes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          telefono TEXT,
          email TEXT,
          direccion TEXT,
          fecha_registro TEXT NOT NULL,
          notas TEXT
        )
      ''');

      // Tabla de ventas
      await db.execute('''
        CREATE TABLE ventas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cliente TEXT NOT NULL,
          telefono TEXT,
          email TEXT,
          total REAL NOT NULL,
          fecha TEXT NOT NULL,
          metodo_pago TEXT,
          estado TEXT NOT NULL,
          notas TEXT
        )
      ''');

      // Tabla de detalles de venta
      await db.execute('''
        CREATE TABLE detalles_venta (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          venta_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (venta_id) REFERENCES ventas (id),
          FOREIGN KEY (producto_id) REFERENCES productos (id)
        )
      ''');

      LoggingService.info('Tablas de base de datos creadas exitosamente');
    } catch (e) {
      LoggingService.error('Error creando tablas: $e');
      rethrow;
    }
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    LoggingService.info('Actualizando base de datos de versión $oldVersion a $newVersion');
    
    if (oldVersion < 2) {
      // Migración de versión 1 a 2: Actualizar tabla ventas
      try {
        LoggingService.info('Migrando tabla ventas...');
        
        // Crear tabla temporal con la nueva estructura
        await db.execute('''
          CREATE TABLE ventas_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT NOT NULL,
            telefono TEXT,
            email TEXT,
            total REAL NOT NULL,
            fecha TEXT NOT NULL,
            metodo_pago TEXT,
            estado TEXT NOT NULL,
            notas TEXT
          )
        ''');
        
        // Copiar datos de la tabla antigua a la nueva
        await db.execute('''
          INSERT INTO ventas_new (id, cliente, telefono, email, total, fecha, metodo_pago, estado, notas)
          SELECT 
            id,
            COALESCE((SELECT nombre FROM clientes WHERE clientes.id = ventas.cliente_id), 'Cliente no especificado') as cliente,
            COALESCE((SELECT telefono FROM clientes WHERE clientes.id = ventas.cliente_id), '') as telefono,
            COALESCE((SELECT email FROM clientes WHERE clientes.id = ventas.cliente_id), '') as email,
            total,
            fecha,
            metodo_pago,
            estado,
            notas
          FROM ventas
        ''');
        
        // Eliminar tabla antigua
        await db.execute('DROP TABLE ventas');
        
        // Renombrar tabla nueva
        await db.execute('ALTER TABLE ventas_new RENAME TO ventas');
        
        LoggingService.info('Migración de tabla ventas completada');
      } catch (e) {
        LoggingService.error('Error en migración de tabla ventas: $e');
        // Si hay error, recrear la tabla desde cero
        await db.execute('DROP TABLE IF EXISTS ventas');
        await db.execute('''
          CREATE TABLE ventas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            cliente TEXT NOT NULL,
            telefono TEXT,
            email TEXT,
            total REAL NOT NULL,
            fecha TEXT NOT NULL,
            metodo_pago TEXT,
            estado TEXT NOT NULL,
            notas TEXT
          )
        ''');
        LoggingService.info('Tabla ventas recreada desde cero');
      }
    }
  }

  // ==================== PRODUCTOS ====================

  /// Obtiene todos los productos
  Future<List<Producto>> getAllProductos() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('productos');
      return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
    }, 'getAllProductos');
  }

  /// Obtiene un producto por ID
  Future<Producto?> getProducto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Producto.fromMap(maps.first);
      }
      return null;
    }, 'getProducto');
  }

  /// Inserta un nuevo producto
  Future<int> insertProducto(Producto producto) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.insert('productos', producto.toMap());
    }, 'insertProducto');
  }

  /// Actualiza un producto existente
  Future<int> updateProducto(Producto producto) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.update(
        'productos',
        producto.toMap(),
        where: 'id = ?',
        whereArgs: [producto.id],
      );
    }, 'updateProducto');
  }

  /// Elimina un producto
  Future<int> deleteProducto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'productos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }, 'deleteProducto');
  }

  // ==================== CLIENTES ====================

  /// Obtiene todos los clientes
  Future<List<Cliente>> getAllClientes() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('clientes');
      return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
    }, 'getAllClientes');
  }

  /// Obtiene un cliente por ID
  Future<Cliente?> getCliente(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Cliente.fromMap(maps.first);
      }
      return null;
    }, 'getCliente');
  }

  /// Inserta un nuevo cliente
  Future<int> insertCliente(Cliente cliente) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.insert('clientes', cliente.toMap());
    }, 'insertCliente');
  }

  /// Actualiza un cliente existente
  Future<int> updateCliente(Cliente cliente) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.update(
        'clientes',
        cliente.toMap(),
        where: 'id = ?',
        whereArgs: [cliente.id],
      );
    }, 'updateCliente');
  }

  /// Elimina un cliente
  Future<int> deleteCliente(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [id],
      );
    }, 'deleteCliente');
  }

  // ==================== VENTAS ====================

  /// Obtiene todas las ventas
  Future<List<Venta>> getAllVentas() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('ventas');
      return List.generate(maps.length, (i) => Venta.fromMap(maps[i]));
    }, 'getAllVentas');
  }

  /// Obtiene una venta por ID
  Future<Venta?> getVenta(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Venta.fromMap(maps.first);
      }
      return null;
    }, 'getVenta');
  }

  /// Inserta una nueva venta
  Future<int> insertVenta(Venta venta) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.insert('ventas', venta.toMap());
    }, 'insertVenta');
  }

  /// Actualiza una venta existente
  Future<int> updateVenta(Venta venta) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.update(
        'ventas',
        venta.toMap(),
        where: 'id = ?',
        whereArgs: [venta.id],
      );
    }, 'updateVenta');
  }

  /// Elimina una venta
  Future<int> deleteVenta(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'ventas',
        where: 'id = ?',
        whereArgs: [id],
      );
    }, 'deleteVenta');
  }

  // ==================== MÉTRICAS ====================

  /// Obtiene el total de ventas del mes actual
  Future<double> getTotalVentasDelMes() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final ahora = DateTime.now();
      final inicioDelMes = DateTime(ahora.year, ahora.month, 1);
      
      final result = await db.rawQuery('''
        SELECT SUM(total) as total
        FROM ventas
        WHERE fecha >= ? AND fecha < ?
      ''', [inicioDelMes.toIso8601String(), ahora.toIso8601String()]);
      
      return result.first['total'] as double? ?? 0.0;
    }, 'getTotalVentasDelMes');
  }

  /// Obtiene las ventas de los últimos 7 días
  Future<List<Map<String, dynamic>>> getVentasUltimos7Dias() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final ahora = DateTime.now();
      final hace7Dias = ahora.subtract(const Duration(days: 7));
      
      final result = await db.rawQuery('''
        SELECT DATE(fecha) as fecha, SUM(total) as total
        FROM ventas
        WHERE fecha >= ? AND fecha < ?
        GROUP BY DATE(fecha)
        ORDER BY fecha
      ''', [hace7Dias.toIso8601String(), ahora.toIso8601String()]);
      
      return result;
    }, 'getVentasUltimos7Dias');
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
