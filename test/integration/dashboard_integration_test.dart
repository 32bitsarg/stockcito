import 'package:flutter_test/flutter_test.dart';
import 'package:stockcito/services/datos/dashboard_service.dart';
import 'package:stockcito/services/datos/database/local_database_service.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/venta.dart';
import 'package:stockcito/models/cliente.dart';

void main() {
  group('Dashboard Integration Tests', () {
    late DashboardService dashboardService;
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
      dashboardService = DashboardService();
      
      // Limpiar base de datos antes de cada test
      await databaseService.clearAllData();
    });

    tearDown(() async {
      // Limpiar después de cada test
      await databaseService.clearAllData();
    });

    group('Carga de datos del dashboard', () {
      test('debe cargar datos correctamente con productos y ventas', () async {
        // Crear datos de prueba
        await _crearDatosDePrueba();

        // Cargar datos del dashboard
        await dashboardService.cargarDatos();

        // Verificar métricas
        expect(dashboardService.totalProductos, equals(3));
        expect(dashboardService.totalClientes, equals(2));
        expect(dashboardService.totalVentas, equals(2));
        expect(dashboardService.stockBajo, equals(1)); // 1 producto con stock < 10
        expect(dashboardService.valorInventario, greaterThan(0));
        expect(dashboardService.margenPromedio, greaterThan(0));
      });

      test('debe manejar dashboard vacío', () async {
        // No crear datos, dashboard vacío
        await dashboardService.cargarDatos();

        // Verificar métricas vacías
        expect(dashboardService.totalProductos, equals(0));
        expect(dashboardService.totalClientes, equals(0));
        expect(dashboardService.totalVentas, equals(0));
        expect(dashboardService.stockBajo, equals(0));
        expect(dashboardService.valorInventario, equals(0.0));
        expect(dashboardService.margenPromedio, equals(0.0));
      });

      test('debe actualizar datos después de cambios', () async {
        // Cargar datos iniciales
        await _crearDatosDePrueba();
        await dashboardService.cargarDatos();
        
        final productosIniciales = dashboardService.totalProductos;
        final ventasIniciales = dashboardService.totalVentas;

        // Agregar nuevo producto
        final nuevoProducto = Producto(
          nombre: 'Nuevo Producto',
          categoria: 'Ropa',
          talla: 'L',
          precioVenta: 35.0,
          costoTotal: 20.0,
          stock: 15,
          descripcion: 'Producto nuevo',
          codigo: 'NUEVO001',
        );
        await databaseService.insertProducto(nuevoProducto);

        // Actualizar dashboard
        await dashboardService.actualizarDatos();

        // Verificar que se actualizó
        expect(dashboardService.totalProductos, equals(productosIniciales + 1));
      });
    });

    group('Cálculo de métricas', () {
      test('debe calcular margen promedio correctamente', () async {
        // Crear productos con márgenes conocidos
        final productos = [
          Producto(
            nombre: 'Producto 1',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 100.0,
            costoTotal: 50.0, // Margen: 50%
            stock: 10,
            descripcion: 'Producto 1',
            codigo: 'P001',
          ),
          Producto(
            nombre: 'Producto 2',
            categoria: 'Ropa',
            talla: 'M',
            precioVenta: 200.0,
            costoTotal: 100.0, // Margen: 50%
            stock: 5,
            descripcion: 'Producto 2',
            codigo: 'P002',
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        await dashboardService.cargarDatos();

        // Margen promedio debería ser 50%
        expect(dashboardService.margenPromedio, closeTo(50.0, 0.1));
      });

      test('debe calcular valor del inventario correctamente', () async {
        final productos = [
          Producto(
            nombre: 'Producto 1',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 100.0,
            costoTotal: 50.0,
            stock: 10, // Valor: 1000
            descripcion: 'Producto 1',
            codigo: 'P001',
          ),
          Producto(
            nombre: 'Producto 2',
            categoria: 'Ropa',
            talla: 'M',
            precioVenta: 200.0,
            costoTotal: 100.0,
            stock: 5, // Valor: 1000
            descripcion: 'Producto 2',
            codigo: 'P002',
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        await dashboardService.cargarDatos();

        // Valor total del inventario: 2000
        expect(dashboardService.valorInventario, equals(2000.0));
      });

      test('debe contar productos con stock bajo correctamente', () async {
        final productos = [
          Producto(
            nombre: 'Producto Stock Bajo',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 100.0,
            costoTotal: 50.0,
            stock: 5, // Stock bajo (< 10)
            descripcion: 'Producto con stock bajo',
            codigo: 'P001',
          ),
          Producto(
            nombre: 'Producto Stock Normal',
            categoria: 'Ropa',
            talla: 'M',
            precioVenta: 200.0,
            costoTotal: 100.0,
            stock: 20, // Stock normal (>= 10)
            descripcion: 'Producto con stock normal',
            codigo: 'P002',
          ),
          Producto(
            nombre: 'Producto Stock Bajo 2',
            categoria: 'Ropa',
            talla: 'L',
            precioVenta: 150.0,
            costoTotal: 75.0,
            stock: 3, // Stock bajo (< 10)
            descripcion: 'Otro producto con stock bajo',
            codigo: 'P003',
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        await dashboardService.cargarDatos();

        // Debería haber 2 productos con stock bajo
        expect(dashboardService.stockBajo, equals(2));
      });
    });

    group('Productos y ventas recientes', () {
      test('debe obtener productos recientes ordenados por fecha', () async {
        final ahora = DateTime.now();
        
        final productos = [
          Producto(
            nombre: 'Producto Antiguo',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 100.0,
            costoTotal: 50.0,
            stock: 10,
            descripcion: 'Producto antiguo',
            codigo: 'P001',
            fechaCreacion: ahora.subtract(const Duration(days: 2)),
          ),
          Producto(
            nombre: 'Producto Reciente',
            categoria: 'Ropa',
            talla: 'M',
            precioVenta: 200.0,
            costoTotal: 100.0,
            stock: 5,
            descripcion: 'Producto reciente',
            codigo: 'P002',
            fechaCreacion: ahora,
          ),
          Producto(
            nombre: 'Producto Medio',
            categoria: 'Ropa',
            talla: 'L',
            precioVenta: 150.0,
            costoTotal: 75.0,
            stock: 8,
            descripcion: 'Producto medio',
            codigo: 'P003',
            fechaCreacion: ahora.subtract(const Duration(days: 1)),
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        await dashboardService.cargarDatos();

        final productosRecientes = dashboardService.productosRecientes;
        expect(productosRecientes.length, equals(3));
        expect(productosRecientes.first.nombre, equals('Producto Reciente'));
        expect(productosRecientes.last.nombre, equals('Producto Antiguo'));
      });

      test('debe obtener ventas recientes ordenadas por fecha', () async {
        final ahora = DateTime.now();
        
        final ventas = [
          Venta(
            cliente: 'Cliente 1',
            telefono: '1234567890',
            email: 'cliente1@example.com',
            fecha: ahora.subtract(const Duration(days: 2)),
            total: 100.0,
            metodoPago: 'Efectivo',
            estado: 'Completada',
            items: [],
          ),
          Venta(
            cliente: 'Cliente 2',
            telefono: '0987654321',
            email: 'cliente2@example.com',
            fecha: ahora,
            total: 200.0,
            metodoPago: 'Tarjeta',
            estado: 'Completada',
            items: [],
          ),
          Venta(
            cliente: 'Cliente 3',
            telefono: '5555555555',
            email: 'cliente3@example.com',
            fecha: ahora.subtract(const Duration(days: 1)),
            total: 150.0,
            metodoPago: 'Efectivo',
            estado: 'Completada',
            items: [],
          ),
        ];

        for (final venta in ventas) {
          await databaseService.insertVenta(venta);
        }

        await dashboardService.cargarDatos();

        final ventasRecientes = dashboardService.ventasRecientes;
        expect(ventasRecientes.length, equals(3));
        expect(ventasRecientes.first.cliente, equals('Cliente 2'));
        expect(ventasRecientes.last.cliente, equals('Cliente 1'));
      });
    });

    group('Manejo de errores', () {
      test('debe manejar errores de carga de datos', () async {
        // Simular error cerrando la base de datos
        await databaseService.close();

        // Intentar cargar datos debería manejar el error
        await dashboardService.cargarDatos();

        // Verificar que el estado de error se estableció
        expect(dashboardService.error, isNotNull);
        expect(dashboardService.isLoading, isFalse);
      });
    });
  });

  // Función auxiliar para crear datos de prueba
  Future<void> _crearDatosDePrueba() async {
    final databaseService = DatabaseService();

    // Crear productos
    final productos = [
      Producto(
        nombre: 'Producto 1',
        categoria: 'Ropa',
        talla: 'S',
        precioVenta: 100.0,
        costoTotal: 50.0,
        stock: 5, // Stock bajo
        descripcion: 'Producto 1',
        codigo: 'P001',
      ),
      Producto(
        nombre: 'Producto 2',
        categoria: 'Ropa',
        talla: 'M',
        precioVenta: 200.0,
        costoTotal: 100.0,
        stock: 20,
        descripcion: 'Producto 2',
        codigo: 'P002',
      ),
      Producto(
        nombre: 'Producto 3',
        categoria: 'Accesorios',
        talla: 'L',
        precioVenta: 150.0,
        costoTotal: 75.0,
        stock: 15,
        descripcion: 'Producto 3',
        codigo: 'P003',
      ),
    ];

    for (final producto in productos) {
      await databaseService.insertProducto(producto);
    }

    // Crear clientes
    final clientes = [
      Cliente(
        nombre: 'Cliente 1',
        telefono: '1234567890',
        email: 'cliente1@example.com',
        direccion: 'Dirección 1',
      ),
      Cliente(
        nombre: 'Cliente 2',
        telefono: '0987654321',
        email: 'cliente2@example.com',
        direccion: 'Dirección 2',
      ),
    ];

    for (final cliente in clientes) {
      await databaseService.insertCliente(cliente);
    }

    // Crear ventas
    final ventas = [
      Venta(
        cliente: 'Cliente 1',
        telefono: '1234567890',
        email: 'cliente1@example.com',
        fecha: DateTime.now(),
        total: 100.0,
        metodoPago: 'Efectivo',
        estado: 'Completada',
        items: [],
      ),
      Venta(
        cliente: 'Cliente 2',
        telefono: '0987654321',
        email: 'cliente2@example.com',
        fecha: DateTime.now(),
        total: 200.0,
        metodoPago: 'Tarjeta',
        estado: 'Completada',
        items: [],
      ),
    ];

    for (final venta in ventas) {
      await databaseService.insertVenta(venta);
    }
  }
}
