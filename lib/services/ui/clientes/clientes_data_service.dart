import '../../../models/cliente.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/system/connectivity_service.dart';

/// Servicio que maneja la carga y gestión de datos de los clientes
class ClientesDataService {
  final DatosService _datosService = DatosService();
  
  ClientesDataService();

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando ClientesDataService...');
      await _datosService.initialize();
      LoggingService.info('✅ ClientesDataService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando ClientesDataService: $e');
      rethrow;
    }
  }

  /// Obtener todos los clientes
  Future<List<Cliente>> getClientes() async {
    try {
      LoggingService.info('👥 Obteniendo clientes...');
      final clientes = await _datosService.getClientes();
      LoggingService.info('✅ Clientes obtenidos: ${clientes.length}');
      return clientes;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo clientes: $e');
      rethrow;
    }
  }

  /// Guardar cliente
  Future<void> saveCliente(Cliente cliente) async {
    try {
      LoggingService.info('💾 Guardando cliente: ${cliente.nombre}');
      await _datosService.saveCliente(cliente);
      LoggingService.info('✅ Cliente guardado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error guardando cliente: $e');
      rethrow;
    }
  }

  /// Actualizar cliente
  Future<void> updateCliente(Cliente cliente) async {
    try {
      LoggingService.info('✏️ Actualizando cliente: ${cliente.nombre}');
      await _datosService.updateCliente(cliente);
      LoggingService.info('✅ Cliente actualizado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error actualizando cliente: $e');
      rethrow;
    }
  }

  /// Eliminar cliente
  Future<void> deleteCliente(int clienteId) async {
    try {
      LoggingService.info('🗑️ Eliminando cliente: $clienteId');
      await _datosService.deleteCliente(clienteId);
      LoggingService.info('✅ Cliente eliminado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando cliente: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas de los clientes
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      LoggingService.info('📊 Obteniendo estadísticas de clientes...');
      
      final clientes = await getClientes();
      
      final totalClientes = clientes.length;
      final conEmail = clientes.where((c) => c.email.isNotEmpty).length;
      final conTelefono = clientes.where((c) => c.telefono.isNotEmpty).length;
      final conDireccion = clientes.where((c) => c.direccion.isNotEmpty).length;
      
      final estadisticas = {
        'totalClientes': totalClientes,
        'conEmail': conEmail,
        'conTelefono': conTelefono,
        'conDireccion': conDireccion,
        'porcentajeConEmail': totalClientes > 0 ? (conEmail / totalClientes * 100).round() : 0,
        'porcentajeConTelefono': totalClientes > 0 ? (conTelefono / totalClientes * 100).round() : 0,
      };
      
      LoggingService.info('✅ Estadísticas obtenidas: $estadisticas');
      return estadisticas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo estadísticas: $e');
      rethrow;
    }
  }

  /// Buscar clientes
  Future<List<Cliente>> searchClientes(String query) async {
    try {
      LoggingService.info('🔍 Buscando clientes: $query');
      
      final clientes = await getClientes();
      
      if (query.isEmpty) return clientes;
      
      final resultados = clientes.where((cliente) {
        final nombre = cliente.nombre.toLowerCase();
        final telefono = cliente.telefono.toString();
        final email = cliente.email.toLowerCase();
        final direccion = cliente.direccion.toLowerCase();
        final busqueda = query.toLowerCase();
        
        return nombre.contains(busqueda) ||
               telefono.contains(busqueda) ||
               email.contains(busqueda) ||
               direccion.contains(busqueda);
      }).toList();
      
      LoggingService.info('✅ Búsqueda completada: ${resultados.length} resultados');
      return resultados;
    } catch (e) {
      LoggingService.error('❌ Error buscando clientes: $e');
      rethrow;
    }
  }

  /// Sincronizar datos
  Future<void> syncData() async {
    try {
      LoggingService.info('🔄 Sincronizando datos de clientes...');
      await _datosService.forceSync(); // Usar método existente de DatosService
      LoggingService.info('✅ Datos de clientes sincronizados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando datos: $e');
      rethrow;
    }
  }

  /// Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      final connectivityService = ConnectivityService();
      final connectivityInfo = await connectivityService.checkConnectivity();
      return connectivityInfo.hasInternet; // Usar servicio de conectividad existente
    } catch (e) {
      LoggingService.error('❌ Error verificando conectividad: $e');
      return false;
    }
  }
}
