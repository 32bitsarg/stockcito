import 'package:stockcito/services/ui/inventario/inventario_state_service.dart';
import 'package:stockcito/services/ui/ventas/ventas_state_service.dart';
import 'package:stockcito/services/ui/clientes/clientes_state_service.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Servicio centralizado para manejar la selección específica de elementos en pantallas
class ScreenSelectionService {
  static final ScreenSelectionService _instance = ScreenSelectionService._internal();
  factory ScreenSelectionService() => _instance;
  ScreenSelectionService._internal();

  /// Seleccionar un producto específico
  Future<bool> selectProduct(String productId) async {
    try {
      LoggingService.info('🎯 ScreenSelectionService: Seleccionando producto $productId');
      
      final inventarioService = InventarioStateService();
      final success = await inventarioService.selectProductById(productId);
      
      if (success) {
        LoggingService.info('✅ Producto seleccionado exitosamente: $productId');
      } else {
        LoggingService.warning('⚠️ No se pudo seleccionar el producto: $productId');
      }
      
      return success;
    } catch (e) {
      LoggingService.error('❌ Error en ScreenSelectionService.selectProduct: $e');
      return false;
    }
  }

  /// Seleccionar una venta específica
  Future<bool> selectSale(String saleId) async {
    try {
      LoggingService.info('🎯 ScreenSelectionService: Seleccionando venta $saleId');
      
      final ventasService = VentasStateService();
      final success = await ventasService.selectSaleById(saleId);
      
      if (success) {
        LoggingService.info('✅ Venta seleccionada exitosamente: $saleId');
      } else {
        LoggingService.warning('⚠️ No se pudo seleccionar la venta: $saleId');
      }
      
      return success;
    } catch (e) {
      LoggingService.error('❌ Error en ScreenSelectionService.selectSale: $e');
      return false;
    }
  }

  /// Seleccionar un cliente específico
  Future<bool> selectClient(String clientId) async {
    try {
      LoggingService.info('🎯 ScreenSelectionService: Seleccionando cliente $clientId');
      
      final clientesService = ClientesStateService();
      final success = await clientesService.selectClientById(clientId);
      
      if (success) {
        LoggingService.info('✅ Cliente seleccionado exitosamente: $clientId');
      } else {
        LoggingService.warning('⚠️ No se pudo seleccionar el cliente: $clientId');
      }
      
      return success;
    } catch (e) {
      LoggingService.error('❌ Error en ScreenSelectionService.selectClient: $e');
      return false;
    }
  }

  /// Limpiar todas las selecciones específicas
  void clearAllSelections() {
    try {
      LoggingService.info('🔄 Limpiando todas las selecciones específicas');
      
      InventarioStateService().clearProductSelection();
      VentasStateService().clearSaleSelection();
      ClientesStateService().clearClientSelection();
      
      LoggingService.info('✅ Todas las selecciones limpiadas');
    } catch (e) {
      LoggingService.error('❌ Error limpiando selecciones: $e');
    }
  }

  /// Obtener el estado de selección actual
  Map<String, dynamic> getSelectionState() {
    return {
      'inventario': {
        'selectedProductId': InventarioStateService().selectedProductId,
        'isSelecting': InventarioStateService().isSelectingProduct,
      },
      'ventas': {
        'selectedSaleId': VentasStateService().selectedSaleId,
        'isSelecting': VentasStateService().isSelectingSale,
      },
      'clientes': {
        'selectedClientId': ClientesStateService().selectedClientId,
        'isSelecting': ClientesStateService().isSelectingClient,
      },
    };
  }
}
