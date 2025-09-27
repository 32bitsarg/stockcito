import 'package:shared_preferences/shared_preferences.dart';
import '../system/logging_service.dart';
import '../auth/supabase_auth_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import 'data_compression_service.dart';

/// Servicio para sincronización incremental de datos ML
/// Optimiza el uso de Supabase enviando solo datos nuevos o modificados
class IncrementalSyncService {
  static final IncrementalSyncService _instance = IncrementalSyncService._internal();
  factory IncrementalSyncService() => _instance;
  IncrementalSyncService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();
  final DataCompressionService _compressionService = DataCompressionService();

  // Claves para almacenar timestamps de última sincronización
  static const String _lastProductSyncKey = 'last_product_sync';
  static const String _lastSalesSyncKey = 'last_sales_sync';
  static const String _lastCustomerSyncKey = 'last_customer_sync';
  static const String _lastAggregatedSyncKey = 'last_aggregated_sync';

  /// Sincroniza datos incrementales de productos
  Future<List<Map<String, dynamic>>> syncIncrementalProducts(
    List<Producto> productos
  ) async {
    try {
      LoggingService.info('🔄 Iniciando sincronización incremental de productos');
      
      final lastSync = await _getLastSyncTime(_lastProductSyncKey);
      final newProducts = _filterNewOrModified(productos, lastSync);
      
      if (newProducts.isEmpty) {
        LoggingService.info('✅ No hay productos nuevos para sincronizar');
        return [];
      }
      
      // Comprimir datos nuevos
      final compressedData = newProducts
          .map((producto) => _compressionService.compressProductData(producto))
          .where((data) => data.isNotEmpty)
          .toList();
      
      // Actualizar timestamp de última sincronización
      await _updateLastSyncTime(_lastProductSyncKey);
      
      LoggingService.info('✅ Sincronizados ${compressedData.length} productos nuevos');
      return compressedData;
      
    } catch (e) {
      LoggingService.error('❌ Error en sincronización incremental de productos: $e');
      return [];
    }
  }

  /// Sincroniza datos incrementales de ventas
  Future<List<Map<String, dynamic>>> syncIncrementalSales(
    List<Venta> ventas
  ) async {
    try {
      LoggingService.info('🔄 Iniciando sincronización incremental de ventas');
      
      final lastSync = await _getLastSyncTime(_lastSalesSyncKey);
      final newSales = _filterNewOrModified(ventas, lastSync);
      
      if (newSales.isEmpty) {
        LoggingService.info('✅ No hay ventas nuevas para sincronizar');
        return [];
      }
      
      // Comprimir datos nuevos
      final compressedData = newSales
          .map((venta) => _compressionService.compressSalesData(venta))
          .where((data) => data.isNotEmpty)
          .toList();
      
      // Actualizar timestamp de última sincronización
      await _updateLastSyncTime(_lastSalesSyncKey);
      
      LoggingService.info('✅ Sincronizadas ${compressedData.length} ventas nuevas');
      return compressedData;
      
    } catch (e) {
      LoggingService.error('❌ Error en sincronización incremental de ventas: $e');
      return [];
    }
  }

  /// Sincroniza datos incrementales de clientes
  Future<List<Map<String, dynamic>>> syncIncrementalCustomers(
    List<Cliente> clientes
  ) async {
    try {
      LoggingService.info('🔄 Iniciando sincronización incremental de clientes');
      
      final lastSync = await _getLastSyncTime(_lastCustomerSyncKey);
      final newCustomers = _filterNewOrModified(clientes, lastSync);
      
      if (newCustomers.isEmpty) {
        LoggingService.info('✅ No hay clientes nuevos para sincronizar');
        return [];
      }
      
      // Comprimir datos nuevos
      final compressedData = newCustomers
          .map((cliente) => _compressionService.compressCustomerData(cliente))
          .where((data) => data.isNotEmpty)
          .toList();
      
      // Actualizar timestamp de última sincronización
      await _updateLastSyncTime(_lastCustomerSyncKey);
      
      LoggingService.info('✅ Sincronizados ${compressedData.length} clientes nuevos');
      return compressedData;
      
    } catch (e) {
      LoggingService.error('❌ Error en sincronización incremental de clientes: $e');
      return [];
    }
  }

  /// Sincroniza datos agregados incrementales
  Future<Map<String, dynamic>?> syncIncrementalAggregatedData(
    List<Producto> productos,
    List<Venta> ventas
  ) async {
    try {
      LoggingService.info('🔄 Iniciando sincronización incremental de datos agregados');
      
      final lastSync = await _getLastSyncTime(_lastAggregatedSyncKey);
      final now = DateTime.now();
      
      // Solo sincronizar datos agregados si han pasado al menos 24 horas
      if (lastSync != null && now.difference(lastSync).inHours < 24) {
        LoggingService.info('✅ Datos agregados ya sincronizados recientemente');
        return null;
      }
      
      // Generar datos agregados comprimidos
      final aggregatedData = _compressionService.generateCompressedAggregatedData(
        productos, 
        ventas
      );
      
      if (aggregatedData.isEmpty) {
        LoggingService.info('✅ No hay datos agregados para sincronizar');
        return null;
      }
      
      // Actualizar timestamp de última sincronización
      await _updateLastSyncTime(_lastAggregatedSyncKey);
      
      LoggingService.info('✅ Datos agregados sincronizados correctamente');
      return aggregatedData;
      
    } catch (e) {
      LoggingService.error('❌ Error en sincronización incremental de datos agregados: $e');
      return null;
    }
  }

  /// Sincroniza todos los datos incrementales
  Future<Map<String, dynamic>> syncAllIncrementalData({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
  }) async {
    try {
      LoggingService.info('🚀 Iniciando sincronización incremental completa');
      
      final results = <String, dynamic>{};
      
      // Sincronizar productos
      final productData = await syncIncrementalProducts(productos);
      results['products'] = productData;
      
      // Sincronizar ventas
      final salesData = await syncIncrementalSales(ventas);
      results['sales'] = salesData;
      
      // Sincronizar clientes
      final customerData = await syncIncrementalCustomers(clientes);
      results['customers'] = customerData;
      
      // Sincronizar datos agregados
      final aggregatedData = await syncIncrementalAggregatedData(productos, ventas);
      results['aggregated'] = aggregatedData;
      
      // Calcular estadísticas de sincronización
      final totalRecords = productData.length + salesData.length + customerData.length;
      final hasAggregated = aggregatedData != null;
      
      results['sync_stats'] = {
        'total_records': totalRecords,
        'has_aggregated_data': hasAggregated,
        'sync_timestamp': DateTime.now().toIso8601String(),
        'user_type': _authService.isAnonymous ? 'anonymous' : 'authenticated',
      };
      
      LoggingService.info('✅ Sincronización incremental completada: $totalRecords registros');
      return results;
      
    } catch (e) {
      LoggingService.error('❌ Error en sincronización incremental completa: $e');
      return {'error': e.toString()};
    }
  }

  /// Filtra elementos nuevos o modificados desde la última sincronización
  List<T> _filterNewOrModified<T>(List<T> items, DateTime? lastSync) {
    if (lastSync == null) {
      // Si no hay última sincronización, devolver todos los elementos
      return items;
    }
    
    return items.where((item) {
      DateTime itemDate;
      
      if (item is Producto) {
        itemDate = item.fechaCreacion;
      } else if (item is Venta) {
        itemDate = item.fecha;
      } else if (item is Cliente) {
        itemDate = DateTime.now(); // Los clientes no tienen fecha de creación
      } else {
        return false;
      }
      
      return itemDate.isAfter(lastSync);
    }).toList();
  }

  /// Obtiene el timestamp de la última sincronización
  Future<DateTime?> _getLastSyncTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(key);
      
      if (timestampString == null) return null;
      
      return DateTime.parse(timestampString);
    } catch (e) {
      LoggingService.error('Error obteniendo timestamp de última sincronización: $e');
      return null;
    }
  }

  /// Actualiza el timestamp de la última sincronización
  Future<void> _updateLastSyncTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, DateTime.now().toIso8601String());
    } catch (e) {
      LoggingService.error('Error actualizando timestamp de última sincronización: $e');
    }
  }

  /// Resetea todos los timestamps de sincronización
  Future<void> resetSyncTimestamps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.remove(_lastProductSyncKey);
      await prefs.remove(_lastSalesSyncKey);
      await prefs.remove(_lastCustomerSyncKey);
      await prefs.remove(_lastAggregatedSyncKey);
      
      LoggingService.info('✅ Timestamps de sincronización reseteados');
    } catch (e) {
      LoggingService.error('Error reseteando timestamps de sincronización: $e');
    }
  }

  /// Obtiene estadísticas de sincronización
  Future<Map<String, dynamic>> getSyncStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'last_product_sync': prefs.getString(_lastProductSyncKey),
        'last_sales_sync': prefs.getString(_lastSalesSyncKey),
        'last_customer_sync': prefs.getString(_lastCustomerSyncKey),
        'last_aggregated_sync': prefs.getString(_lastAggregatedSyncKey),
        'user_type': _authService.isAnonymous ? 'anonymous' : 'authenticated',
        'user_id': _authService.currentUserId,
      };
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de sincronización: $e');
      return {};
    }
  }

  /// Verifica si hay datos pendientes de sincronización
  Future<bool> hasPendingSync({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
  }) async {
    try {
      // Verificar productos
      final lastProductSync = await _getLastSyncTime(_lastProductSyncKey);
      final hasNewProducts = _filterNewOrModified(productos, lastProductSync).isNotEmpty;
      
      // Verificar ventas
      final lastSalesSync = await _getLastSyncTime(_lastSalesSyncKey);
      final hasNewSales = _filterNewOrModified(ventas, lastSalesSync).isNotEmpty;
      
      // Verificar clientes
      final lastCustomerSync = await _getLastSyncTime(_lastCustomerSyncKey);
      final hasNewCustomers = _filterNewOrModified(clientes, lastCustomerSync).isNotEmpty;
      
      // Verificar datos agregados
      final lastAggregatedSync = await _getLastSyncTime(_lastAggregatedSyncKey);
      final now = DateTime.now();
      final needsAggregatedSync = lastAggregatedSync == null || 
          now.difference(lastAggregatedSync).inHours >= 24;
      
      return hasNewProducts || hasNewSales || hasNewCustomers || needsAggregatedSync;
    } catch (e) {
      LoggingService.error('Error verificando sincronización pendiente: $e');
      return false;
    }
  }
}
