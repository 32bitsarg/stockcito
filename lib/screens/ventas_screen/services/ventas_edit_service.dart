import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/venta.dart';

/// Servicio para la edición de ventas con validaciones de negocio
class VentasEditService {
  static final VentasEditService _instance = VentasEditService._internal();
  factory VentasEditService() => _instance;
  VentasEditService._internal();

  final DatosService _datosService = DatosService();

  /// Actualiza una venta existente con validaciones
  Future<Venta> updateVenta(Venta venta) async {
    try {
      LoggingService.info('📝 Iniciando actualización de venta: ${venta.id}');

      // Validaciones de negocio
      await _validateVenta(venta);

      // Actualizar en el servicio de datos
      final ventaActualizada = await _datosService.updateVenta(venta);

      LoggingService.info('✅ Venta actualizada exitosamente: ${venta.id}');
      return ventaActualizada;
    } catch (e) {
      LoggingService.error('❌ Error actualizando venta: $e');
      rethrow;
    }
  }

  /// Valida los datos de la venta antes de actualizar
  Future<void> _validateVenta(Venta venta) async {
    // Validar que la venta existe
    if (venta.id == null) {
      throw Exception('La venta debe tener un ID válido');
    }

    // Validar campos obligatorios
    if (venta.cliente.trim().isEmpty) {
      throw Exception('El nombre del cliente es obligatorio');
    }

    if (venta.estado.trim().isEmpty) {
      throw Exception('El estado de la venta es obligatorio');
    }

    if (venta.metodoPago.trim().isEmpty) {
      throw Exception('El método de pago es obligatorio');
    }

    // Validar que el total sea positivo
    if (venta.total <= 0) {
      throw Exception('El total de la venta debe ser mayor a 0');
    }

    // Validar que tenga al menos un item
    if (venta.items.isEmpty) {
      throw Exception('La venta debe tener al menos un producto');
    }

    // Validar items
    for (final item in venta.items) {
      if (item.cantidad <= 0) {
        throw Exception('La cantidad del producto "${item.nombreProducto}" debe ser mayor a 0');
      }
      if (item.precioUnitario <= 0) {
        throw Exception('El precio del producto "${item.nombreProducto}" debe ser mayor a 0');
      }
    }

    LoggingService.info('✅ Validaciones de venta completadas exitosamente');
  }

  /// Obtiene una venta por ID para verificar que existe
  Future<Venta?> getVentaById(int id) async {
    try {
      final ventas = await _datosService.getVentas();
      return ventas.where((v) => v.id == id).firstOrNull;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo venta por ID: $e');
      return null;
    }
  }

  /// Valida si una venta puede ser editada
  Future<bool> canEditVenta(int id) async {
    try {
      final venta = await getVentaById(id);
      if (venta == null) return false;

      // Reglas de negocio para edición
      // Por ejemplo: no se puede editar ventas canceladas
      if (venta.estado.toLowerCase() == 'cancelada') {
        return false;
      }

      return true;
    } catch (e) {
      LoggingService.error('❌ Error validando si se puede editar venta: $e');
      return false;
    }
  }

  /// Calcula el total de la venta basado en los items
  double calculateTotal(List<VentaItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.cantidad * item.precioUnitario));
  }

  /// Valida que el total calculado coincida con el total de la venta
  bool validateTotal(Venta venta) {
    final calculatedTotal = calculateTotal(venta.items);
    return (calculatedTotal - venta.total).abs() < 0.01; // Tolerancia de 1 centavo
  }
}
