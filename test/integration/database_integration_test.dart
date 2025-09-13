import 'package:flutter_test/flutter_test.dart';
import 'package:ricitosdebb/services/datos/database/local_database_service.dart';
import 'package:ricitosdebb/models/producto.dart';
import 'package:ricitosdebb/models/venta.dart';
import 'package:ricitosdebb/models/cliente.dart';

void main() {
  group('Database Integration Tests', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
      // Limpiar base de datos antes de cada test
      await databaseService.clearAllData();
    });

    tearDown(() async {
      // Limpiar después de cada test
      await databaseService.clearAllData();
    });

    group('Productos CRUD', () {
      test('debe crear, leer, actualizar y eliminar productos', () async {
        // Crear producto
        final producto = Producto(
          nombre: 'Test Product',
          categoria: 'Ropa',
          talla: 'M',
          precioVenta: 25.99,
          costoTotal: 15.50,
          stock: 10,
          descripcion: 'Producto de prueba',
          codigo: 'TEST001',
        );

        final id = await databaseService.insertProducto(producto);
        expect(id, greaterThan(0));

        // Leer producto
        final productoLeido = await databaseService.getProducto(id);
        expect(productoLeido, isNotNull);
        expect(productoLeido!.nombre, equals('Test Product'));
        expect(productoLeido.categoria, equals('Ropa'));
        expect(productoLeido.precioVenta, equals(25.99));

        // Actualizar producto
        final productoActualizado = productoLeido.copyWith(
          nombre: 'Test Product Updated',
          precioVenta: 29.99,
        );
        await databaseService.updateProducto(productoActualizado);

        final productoActualizadoLeido = await databaseService.getProducto(id);
        expect(productoActualizadoLeido!.nombre, equals('Test Product Updated'));
        expect(productoActualizadoLeido.precioVenta, equals(29.99));

        // Eliminar producto
        await databaseService.deleteProducto(id);
        final productoEliminado = await databaseService.getProducto(id);
        expect(productoEliminado, isNull);
      });

      test('debe obtener todos los productos', () async {
        // Crear varios productos
        final productos = [
          Producto(
            nombre: 'Product 1',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 20.0,
            costoTotal: 10.0,
            stock: 5,
            descripcion: 'Producto 1',
            codigo: 'P001',
          ),
          Producto(
            nombre: 'Product 2',
            categoria: 'Accesorios',
            talla: 'M',
            precioVenta: 30.0,
            costoTotal: 15.0,
            stock: 8,
            descripcion: 'Producto 2',
            codigo: 'P002',
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        final todosLosProductos = await databaseService.getAllProductos();
        expect(todosLosProductos.length, equals(2));
        expect(todosLosProductos.any((p) => p.nombre == 'Product 1'), isTrue);
        expect(todosLosProductos.any((p) => p.nombre == 'Product 2'), isTrue);
      });
    });

    group('Clientes CRUD', () {
      test('debe crear, leer, actualizar y eliminar clientes', () async {
        // Crear cliente
        final cliente = Cliente(
          nombre: 'Juan Pérez',
          telefono: '1234567890',
          email: 'juan@example.com',
          direccion: 'Calle 123',
        );

        final id = await databaseService.insertCliente(cliente);
        expect(id, greaterThan(0));

        // Leer cliente
        final clienteLeido = await databaseService.getCliente(id);
        expect(clienteLeido, isNotNull);
        expect(clienteLeido!.nombre, equals('Juan Pérez'));
        expect(clienteLeido.telefono, equals('1234567890'));

        // Actualizar cliente
        final clienteActualizado = clienteLeido.copyWith(
          nombre: 'Juan Carlos Pérez',
          telefono: '0987654321',
        );
        await databaseService.updateCliente(clienteActualizado);

        final clienteActualizadoLeido = await databaseService.getCliente(id);
        expect(clienteActualizadoLeido!.nombre, equals('Juan Carlos Pérez'));
        expect(clienteActualizadoLeido.telefono, equals('0987654321'));

        // Eliminar cliente
        await databaseService.deleteCliente(id);
        final clienteEliminado = await databaseService.getCliente(id);
        expect(clienteEliminado, isNull);
      });
    });

    group('Ventas CRUD', () {
      test('debe crear, leer, actualizar y eliminar ventas', () async {
        // Crear producto primero
        final producto = Producto(
          nombre: 'Test Product',
          categoria: 'Ropa',
          talla: 'M',
          precioVenta: 25.99,
          costoTotal: 15.50,
          stock: 10,
          descripcion: 'Producto de prueba',
          codigo: 'TEST001',
        );
        final productoId = await databaseService.insertProducto(producto);

        // Crear cliente
        final cliente = Cliente(
          nombre: 'Cliente Test',
          telefono: '1234567890',
          email: 'cliente@example.com',
        );
        final clienteId = await databaseService.insertCliente(cliente);

        // Crear venta
        final venta = Venta(
          cliente: 'Cliente Test',
          telefono: '1234567890',
          email: 'cliente@example.com',
          fecha: DateTime.now(),
          total: 25.99,
          metodoPago: 'Efectivo',
          estado: 'Completada',
          notas: 'Venta de prueba',
          items: [
            VentaItem(
              productoId: productoId,
              nombre: 'Test Product',
              cantidad: 1,
              precioUnitario: 25.99,
              subtotal: 25.99,
            ),
          ],
        );

        final ventaId = await databaseService.insertVenta(venta);
        expect(ventaId, greaterThan(0));

        // Leer venta
        final ventaLeida = await databaseService.getVenta(ventaId);
        expect(ventaLeida, isNotNull);
        expect(ventaLeida!.cliente, equals('Cliente Test'));
        expect(ventaLeida.total, equals(25.99));
        expect(ventaLeida.items.length, equals(1));

        // Verificar que el stock se actualizó
        final productoActualizado = await databaseService.getProducto(productoId);
        expect(productoActualizado!.stock, equals(9)); // 10 - 1

        // Eliminar venta
        await databaseService.deleteVenta(ventaId);
        final ventaEliminada = await databaseService.getVenta(ventaId);
        expect(ventaEliminada, isNull);

        // Verificar que el stock se restauró
        final productoRestaurado = await databaseService.getProducto(productoId);
        expect(productoRestaurado!.stock, equals(10)); // 9 + 1
      });
    });

    group('Consultas complejas', () {
      test('debe obtener ventas del mes', () async {
        final ahora = DateTime.now();
        final inicioMes = DateTime(ahora.year, ahora.month, 1);
        final finMes = DateTime(ahora.year, ahora.month + 1, 0);

        // Crear venta del mes actual
        final venta = Venta(
          cliente: 'Cliente Test',
          telefono: '1234567890',
          email: 'cliente@example.com',
          fecha: ahora,
          total: 100.0,
          metodoPago: 'Efectivo',
          estado: 'Completada',
          items: [],
        );
        await databaseService.insertVenta(venta);

        // Crear venta del mes pasado
        final ventaPasada = Venta(
          cliente: 'Cliente Test',
          telefono: '1234567890',
          email: 'cliente@example.com',
          fecha: DateTime(ahora.year, ahora.month - 1, 15),
          total: 50.0,
          metodoPago: 'Efectivo',
          estado: 'Completada',
          items: [],
        );
        await databaseService.insertVenta(ventaPasada);

        final totalVentasMes = await databaseService.getTotalVentasDelMes();
        expect(totalVentasMes, equals(100.0));
      });

      test('debe obtener productos con stock bajo', () async {
        // Crear productos con diferentes niveles de stock
        final productos = [
          Producto(
            nombre: 'Producto Stock Bajo',
            categoria: 'Ropa',
            talla: 'S',
            precioVenta: 20.0,
            costoTotal: 10.0,
            stock: 5, // Stock bajo
            descripcion: 'Producto con stock bajo',
            codigo: 'P001',
          ),
          Producto(
            nombre: 'Producto Stock Normal',
            categoria: 'Ropa',
            talla: 'M',
            precioVenta: 30.0,
            costoTotal: 15.0,
            stock: 20, // Stock normal
            descripcion: 'Producto con stock normal',
            codigo: 'P002',
          ),
        ];

        for (final producto in productos) {
          await databaseService.insertProducto(producto);
        }

        final productosStockBajo = await databaseService.getProductosStockBajo();
        expect(productosStockBajo.length, equals(1));
        expect(productosStockBajo.first.nombre, equals('Producto Stock Bajo'));
      });
    });

    group('Transacciones', () {
      test('debe manejar transacciones correctamente', () async {
        // Crear producto
        final producto = Producto(
          nombre: 'Test Product',
          categoria: 'Ropa',
          talla: 'M',
          precioVenta: 25.99,
          costoTotal: 15.50,
          stock: 10,
          descripcion: 'Producto de prueba',
          codigo: 'TEST001',
        );
        final productoId = await databaseService.insertProducto(producto);

        // Crear venta que debe actualizar el stock
        final venta = Venta(
          cliente: 'Cliente Test',
          telefono: '1234567890',
          email: 'cliente@example.com',
          fecha: DateTime.now(),
          total: 25.99,
          metodoPago: 'Efectivo',
          estado: 'Completada',
          items: [
            VentaItem(
              productoId: productoId,
              nombre: 'Test Product',
              cantidad: 3,
              precioUnitario: 25.99,
              subtotal: 77.97,
            ),
          ],
        );

        await databaseService.insertVenta(venta);

        // Verificar que el stock se actualizó correctamente
        final productoActualizado = await databaseService.getProducto(productoId);
        expect(productoActualizado!.stock, equals(7)); // 10 - 3
      });
    });
  });
}
