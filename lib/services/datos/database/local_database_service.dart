import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../../../models/producto.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio para manejo de base de datos local SQLite
class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;
  String? _currentUserId;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Establece el ID del usuario actual
  void setCurrentUserId(String? userId) {
    _currentUserId = userId;
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
        version: 5,
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
          user_id TEXT NOT NULL,
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
          user_id TEXT NOT NULL,
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
          user_id TEXT NOT NULL,
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
          user_id TEXT NOT NULL,
          venta_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          nombre_producto TEXT NOT NULL,
          categoria TEXT NOT NULL,
          talla TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (venta_id) REFERENCES ventas (id),
          FOREIGN KEY (producto_id) REFERENCES productos (id)
        )
      ''');

      // Tabla de costos directos
      await db.execute('''
        CREATE TABLE costos_directos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL,
          cantidad REAL NOT NULL,
          unidad TEXT NOT NULL,
          precio_unitario REAL NOT NULL,
          desperdicio REAL NOT NULL,
          descripcion TEXT,
          fecha_creacion TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

      // Tabla de costos indirectos
      await db.execute('''
        CREATE TABLE costos_indirectos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          nombre TEXT NOT NULL,
          tipo TEXT NOT NULL,
          costo_mensual REAL NOT NULL,
          productos_estimados_mensuales INTEGER NOT NULL,
          descripcion TEXT,
          fecha_creacion TEXT NOT NULL,
          updated_at TEXT NOT NULL
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
    
    if (oldVersion < 3) {
      // Migración de versión 2 a 3 - Agregar user_id a todas las tablas
      LoggingService.info('Ejecutando migración de base de datos de v2 a v3 - Agregando user_id');
      
      try {
        // Agregar columna user_id a productos
        await db.execute('ALTER TABLE productos ADD COLUMN user_id TEXT');
        await db.execute('UPDATE productos SET user_id = "default" WHERE user_id IS NULL');
        
        // Agregar columna user_id a clientes
        await db.execute('ALTER TABLE clientes ADD COLUMN user_id TEXT');
        await db.execute('UPDATE clientes SET user_id = "default" WHERE user_id IS NULL');
        
        // Agregar columna user_id a ventas
        await db.execute('ALTER TABLE ventas ADD COLUMN user_id TEXT');
        await db.execute('UPDATE ventas SET user_id = "default" WHERE user_id IS NULL');
        
        // Agregar columna user_id a detalles_venta
        await db.execute('ALTER TABLE detalles_venta ADD COLUMN user_id TEXT');
        await db.execute('UPDATE detalles_venta SET user_id = "default" WHERE user_id IS NULL');
        
        LoggingService.info('Migración de base de datos v2 a v3 completada');
      } catch (e) {
        LoggingService.error('Error en migración v2 a v3: $e');
        // Si falla, recrear las tablas con la nueva estructura
        await _recreateTablesWithUserId(db);
      }
    }

    if (oldVersion < 4) {
      // Migración de versión 3 a 4 - Agregar columnas faltantes a detalles_venta
      LoggingService.info('Ejecutando migración de base de datos de v3 a v4 - Agregando columnas a detalles_venta');
      
      try {
        // Agregar columnas faltantes a detalles_venta
        await db.execute('ALTER TABLE detalles_venta ADD COLUMN nombre_producto TEXT');
        await db.execute('ALTER TABLE detalles_venta ADD COLUMN categoria TEXT');
        await db.execute('ALTER TABLE detalles_venta ADD COLUMN talla TEXT');
        
        // Actualizar registros existentes con valores por defecto
        await db.execute('''
          UPDATE detalles_venta 
          SET 
            nombre_producto = COALESCE((SELECT nombre FROM productos WHERE productos.id = detalles_venta.producto_id), 'Producto desconocido'),
            categoria = COALESCE((SELECT categoria FROM productos WHERE productos.id = detalles_venta.producto_id), 'Sin categoría'),
            talla = COALESCE((SELECT talla FROM productos WHERE productos.id = detalles_venta.producto_id), 'Sin talla')
          WHERE nombre_producto IS NULL
        ''');
        
        LoggingService.info('Migración de base de datos v3 a v4 completada');
      } catch (e) {
        LoggingService.error('Error en migración v3 a v4: $e');
        // Si falla, recrear la tabla detalles_venta con la nueva estructura
        await _recreateDetallesVentaTable(db);
      }
    }

    if (oldVersion < 5) {
      // Migración de versión 4 a 5 - Agregar tablas de costos
      LoggingService.info('Ejecutando migración de base de datos de v4 a v5 - Agregando tablas de costos');
      
      try {
        // Crear tabla de costos directos
        await db.execute('''
          CREATE TABLE costos_directos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            nombre TEXT NOT NULL,
            tipo TEXT NOT NULL,
            cantidad REAL NOT NULL,
            unidad TEXT NOT NULL,
            precio_unitario REAL NOT NULL,
            desperdicio REAL NOT NULL,
            descripcion TEXT,
            fecha_creacion TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Crear tabla de costos indirectos
        await db.execute('''
          CREATE TABLE costos_indirectos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            nombre TEXT NOT NULL,
            tipo TEXT NOT NULL,
            costo_mensual REAL NOT NULL,
            productos_estimados_mensuales INTEGER NOT NULL,
            descripcion TEXT,
            fecha_creacion TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        
        LoggingService.info('Migración de base de datos v4 a v5 completada - Tablas de costos creadas');
      } catch (e) {
        LoggingService.error('Error en migración v4 a v5: $e');
        rethrow;
      }
    }
  }
  
  /// Recrea las tablas con user_id si la migración falla
  Future<void> _recreateTablesWithUserId(Database db) async {
    try {
      LoggingService.info('Recreando tablas con user_id...');
      
      // Eliminar tablas existentes
      await db.execute('DROP TABLE IF EXISTS detalles_venta');
      await db.execute('DROP TABLE IF EXISTS ventas');
      await db.execute('DROP TABLE IF EXISTS clientes');
      await db.execute('DROP TABLE IF EXISTS productos');
      
      // Recrear con la nueva estructura
      await _createTables(db, 3);
      
      LoggingService.info('Tablas recreadas con user_id exitosamente');
    } catch (e) {
      LoggingService.error('Error recreando tablas: $e');
      rethrow;
    }
  }

  /// Recrea la tabla detalles_venta con la nueva estructura si la migración falla
  Future<void> _recreateDetallesVentaTable(Database db) async {
    try {
      LoggingService.info('Recreando tabla detalles_venta con nueva estructura...');
      
      // Eliminar tabla existente
      await db.execute('DROP TABLE IF EXISTS detalles_venta');
      
      // Recrear con la nueva estructura completa
      await db.execute('''
        CREATE TABLE detalles_venta (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          venta_id INTEGER NOT NULL,
          producto_id INTEGER NOT NULL,
          nombre_producto TEXT NOT NULL,
          categoria TEXT NOT NULL,
          talla TEXT NOT NULL,
          cantidad INTEGER NOT NULL,
          precio_unitario REAL NOT NULL,
          subtotal REAL NOT NULL,
          FOREIGN KEY (venta_id) REFERENCES ventas (id),
          FOREIGN KEY (producto_id) REFERENCES productos (id)
        )
      ''');
      
      LoggingService.info('Tabla detalles_venta recreada exitosamente');
    } catch (e) {
      LoggingService.error('Error recreando tabla detalles_venta: $e');
      rethrow;
    }
  }

  // ==================== PRODUCTOS ====================

  /// Obtiene todos los productos para un usuario específico
  Future<List<Producto>> getAllProductos({String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'productos',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
      );
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
  Future<int> insertProducto(Producto producto, {String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final productMap = producto.toMap();
      if (userId != null) {
        productMap['user_id'] = userId;
      }
      return await db.insert('productos', productMap);
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

  /// Actualiza solo el stock de un producto
  Future<int> updateProductoStock(int productoId, int nuevoStock) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.update(
        'productos',
        {'stock': nuevoStock},
        where: 'id = ? AND user_id = ?',
        whereArgs: [productoId, _currentUserId ?? 'default'],
      );
    }, 'updateProductoStock');
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

  // ==================== COSTOS DIRECTOS ====================

  /// Inserta un costo directo
  Future<int> insertCostoDirecto(CostoDirecto costo, {String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final costoMap = costo.toMap();
      if (userId != null) {
        costoMap['user_id'] = userId;
      }
      return await db.insert('costos_directos', costoMap);
    }, 'insertCostoDirecto');
  }

  /// Obtiene todos los costos directos
  Future<List<CostoDirecto>> getAllCostosDirectos({String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'costos_directos',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'fecha_creacion DESC',
      );
      return List.generate(maps.length, (i) => CostoDirecto.fromMap(maps[i]));
    }, 'getAllCostosDirectos');
  }

  /// Obtiene un costo directo por ID
  Future<CostoDirecto?> getCostoDirecto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'costos_directos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return CostoDirecto.fromMap(maps.first);
      }
      return null;
    }, 'getCostoDirecto');
  }

  /// Actualiza un costo directo existente
  Future<int> updateCostoDirecto(CostoDirecto costo) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final costoMap = costo.toMap();
      costoMap['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'costos_directos',
        costoMap,
        where: 'id = ?',
        whereArgs: [costo.id],
      );
    }, 'updateCostoDirecto');
  }

  /// Elimina un costo directo
  Future<int> deleteCostoDirecto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'costos_directos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }, 'deleteCostoDirecto');
  }

  // ==================== COSTOS INDIRECTOS ====================

  /// Inserta un costo indirecto
  Future<int> insertCostoIndirecto(CostoIndirecto costo, {String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final costoMap = costo.toMap();
      if (userId != null) {
        costoMap['user_id'] = userId;
      }
      return await db.insert('costos_indirectos', costoMap);
    }, 'insertCostoIndirecto');
  }

  /// Obtiene todos los costos indirectos
  Future<List<CostoIndirecto>> getAllCostosIndirectos({String? userId}) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'costos_indirectos',
        where: userId != null ? 'user_id = ?' : null,
        whereArgs: userId != null ? [userId] : null,
        orderBy: 'fecha_creacion DESC',
      );
      return List.generate(maps.length, (i) => CostoIndirecto.fromMap(maps[i]));
    }, 'getAllCostosIndirectos');
  }

  /// Obtiene un costo indirecto por ID
  Future<CostoIndirecto?> getCostoIndirecto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'costos_indirectos',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return CostoIndirecto.fromMap(maps.first);
      }
      return null;
    }, 'getCostoIndirecto');
  }

  /// Actualiza un costo indirecto existente
  Future<int> updateCostoIndirecto(CostoIndirecto costo) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final costoMap = costo.toMap();
      costoMap['updated_at'] = DateTime.now().toIso8601String();
      return await db.update(
        'costos_indirectos',
        costoMap,
        where: 'id = ?',
        whereArgs: [costo.id],
      );
    }, 'updateCostoIndirecto');
  }

  /// Elimina un costo indirecto
  Future<int> deleteCostoIndirecto(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'costos_indirectos',
        where: 'id = ?',
        whereArgs: [id],
      );
    }, 'deleteCostoIndirecto');
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

  /// Obtiene todas las ventas con sus items
  Future<List<Venta>> getAllVentas() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas',
        where: 'user_id = ?',
        whereArgs: [_currentUserId ?? 'default'],
      );
      
      final List<Venta> ventas = [];
      for (final map in maps) {
        final venta = Venta.fromMap(map);
        // Cargar los items de la venta
        final items = await getDetallesVenta(venta.id!);
        ventas.add(venta.copyWith(items: items));
      }
      
      LoggingService.info('Ventas cargadas: ${ventas.length} con items');
      return ventas;
    }, 'getAllVentas');
  }

  /// Obtiene una venta por ID con sus items
  Future<Venta?> getVenta(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ventas',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, _currentUserId ?? 'default'],
      );
      if (maps.isNotEmpty) {
        final venta = Venta.fromMap(maps.first);
        // Cargar los items de la venta
        final items = await getDetallesVenta(venta.id!);
        return venta.copyWith(items: items);
      }
      return null;
    }, 'getVenta');
  }

  /// Inserta una nueva venta con sus items y reduce el stock
  Future<int> insertVenta(Venta venta) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      
      // Insertar la venta principal
      final ventaData = venta.toMap();
      ventaData['user_id'] = _currentUserId ?? 'default';
      final ventaId = await db.insert('ventas', ventaData);
      
      // Insertar los items de la venta y reducir stock
      for (final item in venta.items) {
        final itemData = item.toMap();
        itemData['venta_id'] = ventaId;
        itemData['user_id'] = _currentUserId ?? 'default';
        await db.insert('detalles_venta', itemData);
        
        // Reducir stock del producto
        await _reduceProductStock(db, item.productoId, item.cantidad);
      }
      
      LoggingService.info('Venta insertada con ${venta.items.length} items - ID: $ventaId');
      return ventaId;
    }, 'insertVenta');
  }

  /// Reduce el stock de un producto
  Future<void> _reduceProductStock(Database db, int productoId, int cantidadVendida) async {
    try {
      // Obtener stock actual
      final List<Map<String, dynamic>> result = await db.query(
        'productos',
        columns: ['stock'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [productoId, _currentUserId ?? 'default'],
      );
      
      if (result.isNotEmpty) {
        final stockActual = result.first['stock'] as int;
        final nuevoStock = stockActual - cantidadVendida;
        
        if (nuevoStock < 0) {
          LoggingService.warning('Stock insuficiente para producto $productoId: $stockActual < $cantidadVendida');
          return;
        }
        
        // Actualizar stock
        await db.update(
          'productos',
          {'stock': nuevoStock},
          where: 'id = ? AND user_id = ?',
          whereArgs: [productoId, _currentUserId ?? 'default'],
        );
        
        LoggingService.info('Stock reducido: Producto $productoId: $stockActual -> $nuevoStock (-$cantidadVendida)');
      } else {
        LoggingService.warning('Producto $productoId no encontrado para reducir stock');
      }
    } catch (e) {
      LoggingService.error('Error reduciendo stock del producto $productoId: $e');
    }
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

  /// Elimina una venta y sus items
  Future<int> deleteVenta(int id) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      
      // Eliminar primero los items de la venta
      await deleteDetallesVenta(id);
      
      // Luego eliminar la venta principal
      final result = await db.delete(
        'ventas',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, _currentUserId ?? 'default'],
      );
      
      LoggingService.info('Venta eliminada con sus items - ID: $id');
      return result;
    }, 'deleteVenta');
  }

  // ==================== DETALLES DE VENTA ====================

  /// Inserta un detalle de venta
  Future<int> insertDetalleVenta(VentaItem detalle) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final data = detalle.toMap();
      data['user_id'] = _currentUserId ?? 'default';
      return await db.insert('detalles_venta', data);
    }, 'insertDetalleVenta');
  }

  /// Obtiene todos los detalles de una venta específica
  Future<List<VentaItem>> getDetallesVenta(int ventaId) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'detalles_venta',
        where: 'venta_id = ? AND user_id = ?',
        whereArgs: [ventaId, _currentUserId ?? 'default'],
      );
      return List.generate(maps.length, (i) => VentaItem.fromMap(maps[i]));
    }, 'getDetallesVenta');
  }

  /// Elimina todos los detalles de una venta específica
  Future<int> deleteDetallesVenta(int ventaId) async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      return await db.delete(
        'detalles_venta',
        where: 'venta_id = ? AND user_id = ?',
        whereArgs: [ventaId, _currentUserId ?? 'default'],
      );
    }, 'deleteDetallesVenta');
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

  /// Inicializa datos de prueba para desarrollo
  Future<void> initializeSampleData() async {
    return await _handleDatabaseOperation(() async {
      final db = await database;
      
      // Verificar si ya hay datos
      final productosCount = await db.rawQuery('SELECT COUNT(*) as count FROM productos');
      if (productosCount.first['count'] as int > 0) {
        LoggingService.info('Ya hay datos en la base de datos, saltando inicialización de datos de prueba');
        return;
      }
      
      LoggingService.info('Inicializando datos de prueba...');
      
      // Insertar productos de ejemplo
      final productosEjemplo = [
        {
          'nombre': 'Camiseta Básica Blanca',
          'categoria': 'Ropa',
          'talla': 'M',
          'precio': 25.99,
          'stock': 15,
          'costo_materiales': 8.50,
          'costo_mano_obra': 5.00,
          'gastos_generales': 2.00,
          'margen_ganancia': 0.40,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'descripcion': 'Camiseta básica de algodón 100%',
          'codigo': 'CAM-001'
        },
        {
          'nombre': 'Pantalón Jeans Azul',
          'categoria': 'Ropa',
          'talla': 'L',
          'precio': 45.99,
          'stock': 8,
          'costo_materiales': 18.00,
          'costo_mano_obra': 8.00,
          'gastos_generales': 4.00,
          'margen_ganancia': 0.35,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'descripcion': 'Pantalón jeans clásico',
          'codigo': 'PAN-001'
        },
        {
          'nombre': 'Zapatillas Deportivas',
          'categoria': 'Calzado',
          'talla': '42',
          'precio': 89.99,
          'stock': 3,
          'costo_materiales': 35.00,
          'costo_mano_obra': 15.00,
          'gastos_generales': 8.00,
          'margen_ganancia': 0.36,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'descripcion': 'Zapatillas deportivas cómodas',
          'codigo': 'ZAP-001'
        },
        {
          'nombre': 'Gorra de Béisbol',
          'categoria': 'Accesorios',
          'talla': 'Única',
          'precio': 19.99,
          'stock': 25,
          'costo_materiales': 6.00,
          'costo_mano_obra': 3.00,
          'gastos_generales': 1.50,
          'margen_ganancia': 0.48,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'descripcion': 'Gorra de béisbol ajustable',
          'codigo': 'GOR-001'
        },
        {
          'nombre': 'Chaqueta de Cuero',
          'categoria': 'Ropa',
          'talla': 'XL',
          'precio': 199.99,
          'stock': 2,
          'costo_materiales': 80.00,
          'costo_mano_obra': 25.00,
          'gastos_generales': 15.00,
          'margen_ganancia': 0.40,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'descripcion': 'Chaqueta de cuero genuino',
          'codigo': 'CHA-001'
        }
      ];
      
      for (final producto in productosEjemplo) {
        await db.insert('productos', producto);
      }
      
      // Insertar clientes de ejemplo
      final clientesEjemplo = [
        {
          'nombre': 'Juan Pérez',
          'email': 'juan.perez@email.com',
          'telefono': '+1234567890',
          'direccion': 'Calle Principal 123',
          'fecha_registro': DateTime.now().toIso8601String(),
          'notas': 'Cliente frecuente'
        },
        {
          'nombre': 'María García',
          'email': 'maria.garcia@email.com',
          'telefono': '+0987654321',
          'direccion': 'Avenida Central 456',
          'fecha_registro': DateTime.now().toIso8601String(),
          'notas': 'Prefiere productos de talla M'
        }
      ];
      
      for (final cliente in clientesEjemplo) {
        await db.insert('clientes', cliente);
      }
      
      LoggingService.info('Datos de prueba inicializados correctamente');
    }, 'initializeSampleData');
  }

  /// Cierra la conexión a la base de datos
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
