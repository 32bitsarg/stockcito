import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/producto.dart';
import '../models/venta.dart';
import '../models/cliente.dart';
import 'logging_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

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

      String path = join(await getDatabasesPath(), 'stockcito.db');
      return await _handleDatabaseOperation(
        () => openDatabase(
          path,
          version: 2,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
        'initDatabase',
      );
    } catch (e, stackTrace) {
      LoggingService.error(
        'Failed to initialize database',
        tag: 'DATABASE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de productos
    await db.execute('''
      CREATE TABLE productos(
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
      CREATE TABLE clientes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT NOT NULL,
        direccion TEXT NOT NULL,
        fecha_registro TEXT NOT NULL,
        notas TEXT,
        total_compras INTEGER DEFAULT 0,
        total_gastado REAL DEFAULT 0.0
      )
    ''');

    // Tabla de ventas
    await db.execute('''
      CREATE TABLE ventas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cliente TEXT NOT NULL,
        telefono TEXT NOT NULL,
        email TEXT NOT NULL,
        fecha TEXT NOT NULL,
        total REAL NOT NULL,
        metodo_pago TEXT NOT NULL,
        estado TEXT NOT NULL,
        notas TEXT
      )
    ''');

    // Tabla de items de venta
    await db.execute('''
      CREATE TABLE venta_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar nuevas tablas para la versión 2
      await db.execute('''
        CREATE TABLE clientes(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          telefono TEXT NOT NULL,
          email TEXT NOT NULL,
          direccion TEXT NOT NULL,
          fecha_registro TEXT NOT NULL,
          notas TEXT,
          total_compras INTEGER DEFAULT 0,
          total_gastado REAL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE ventas(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cliente TEXT NOT NULL,
          telefono TEXT NOT NULL,
          email TEXT NOT NULL,
          fecha TEXT NOT NULL,
          total REAL NOT NULL,
          metodo_pago TEXT NOT NULL,
          estado TEXT NOT NULL,
          notas TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE venta_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
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
    }
  }

  // CRUD Operations
  Future<int> insertProducto(Producto producto) async {
    return await _handleDatabaseOperation(
      () async {
        final db = await database;
        return await db.insert('productos', producto.toMap());
      },
      'insertProducto',
    );
  }

  Future<List<Producto>> getAllProductos() async {
    return await _handleDatabaseOperation(
      () async {
        final db = await database;
        final List<Map<String, dynamic>> maps = await db.query('productos');
        return List.generate(maps.length, (i) => Producto.fromMap(maps[i]));
      },
      'getAllProductos',
    );
  }

  Future<Producto?> getProducto(int id) async {
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
  }

  Future<int> updateProducto(Producto producto) async {
    final db = await database;
    return await db.update(
      'productos',
      producto.toMap(),
      where: 'id = ?',
      whereArgs: [producto.id],
    );
  }

  Future<int> deleteProducto(int id) async {
    final db = await database;
    return await db.delete(
      'productos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Método para actualizar stock de un producto
  Future<int> updateStockProducto(int productoId, int nuevaCantidad) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE productos SET stock = ? WHERE id = ?',
      [nuevaCantidad, productoId],
    );
  }

  // CRUD Operations para Clientes
  Future<int> insertCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert('clientes', cliente.toMap());
  }

  Future<List<Cliente>> getAllClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('clientes');
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  Future<Cliente?> getCliente(int id) async {
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
  }

  Future<int> updateCliente(Cliente cliente) async {
    final db = await database;
    return await db.update(
      'clientes',
      cliente.toMap(),
      where: 'id = ?',
      whereArgs: [cliente.id],
    );
  }

  Future<int> deleteCliente(int id) async {
    final db = await database;
    return await db.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations para Ventas
  Future<int> insertVenta(Venta venta) async {
    final db = await database;
    
    // Usar transacción para asegurar consistencia
    return await db.transaction((txn) async {
      // Insertar venta
      final ventaId = await txn.insert('ventas', venta.toMap());
      
      // Insertar items de la venta y actualizar stock
      for (var item in venta.items) {
        // Insertar item de venta
        await txn.insert('venta_items', {
          ...item.toMap(),
          'venta_id': ventaId,
        });
        
        // Actualizar stock del producto
        await txn.rawUpdate(
          'UPDATE productos SET stock = stock - ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }
      
      return ventaId;
    });
  }

  Future<List<Venta>> getAllVentas() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('ventas');
    final ventas = <Venta>[];
    
    for (var map in maps) {
      final venta = Venta.fromMap(map);
      // Cargar items de la venta
      final items = await _getVentaItems(venta.id!);
      ventas.add(venta.copyWith(items: items));
    }
    
    return ventas;
  }

  Future<List<VentaItem>> _getVentaItems(int ventaId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'venta_items',
      where: 'venta_id = ?',
      whereArgs: [ventaId],
    );
    return List.generate(maps.length, (i) => VentaItem.fromMap(maps[i]));
  }

  Future<Venta?> getVenta(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final venta = Venta.fromMap(maps.first);
      final items = await _getVentaItems(venta.id!);
      return venta.copyWith(items: items);
    }
    return null;
  }

  Future<int> updateVenta(Venta venta) async {
    final db = await database;
    
    // Usar transacción para asegurar consistencia
    return await db.transaction((txn) async {
      // Obtener items originales para restaurar stock
      final itemsOriginales = await _getVentaItems(venta.id!);
      
      // Restaurar stock de items originales
      for (var item in itemsOriginales) {
        await txn.rawUpdate(
          'UPDATE productos SET stock = stock + ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }
      
      // Actualizar venta
      await txn.update(
        'ventas',
        venta.toMap(),
        where: 'id = ?',
        whereArgs: [venta.id],
      );
      
      // Eliminar items existentes
      await txn.delete(
        'venta_items',
        where: 'venta_id = ?',
        whereArgs: [venta.id],
      );
      
      // Insertar nuevos items y actualizar stock
      for (var item in venta.items) {
        await txn.insert('venta_items', {
          ...item.toMap(),
          'venta_id': venta.id,
        });
        
        // Actualizar stock del producto
        await txn.rawUpdate(
          'UPDATE productos SET stock = stock - ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }
      
      return venta.id!;
    });
  }

  Future<int> deleteVenta(int id) async {
    final db = await database;
    
    // Usar transacción para asegurar consistencia
    return await db.transaction((txn) async {
      // Obtener items de la venta para restaurar stock
      final items = await _getVentaItems(id);
      
      // Restaurar stock de los productos
      for (var item in items) {
        await txn.rawUpdate(
          'UPDATE productos SET stock = stock + ? WHERE id = ?',
          [item.cantidad, item.productoId],
        );
      }
      
      // Eliminar items de la venta
      await txn.delete(
        'venta_items',
        where: 'venta_id = ?',
        whereArgs: [id],
      );
      
      // Eliminar venta
      return await txn.delete(
        'ventas',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  // Métodos de consulta específicos
  Future<List<Venta>> getVentasDelMes() async {
    final db = await database;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    final List<Map<String, dynamic>> maps = await db.query(
      'ventas',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String(),
      ],
    );
    
    final ventas = <Venta>[];
    for (var map in maps) {
      final venta = Venta.fromMap(map);
      final items = await _getVentaItems(venta.id!);
      ventas.add(venta.copyWith(items: items));
    }
    
    return ventas;
  }

  Future<double> getTotalVentasDelMes() async {
    final ventas = await getVentasDelMes();
    double total = 0.0;
    for (var venta in ventas) {
      total += venta.total;
    }
    return total;
  }

  Future<int> getTotalVentasDelMesCount() async {
    final ventas = await getVentasDelMes();
    return ventas.length;
  }
}