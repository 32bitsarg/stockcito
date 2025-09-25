import '../../../models/cliente.dart';
import '../../../services/datos/datos.dart';
import '../../../services/system/logging_service.dart';
import 'clientes_state_service.dart';
import '../../../screens/clientes_screen/functions/clientes_functions.dart';

/// Servicio que maneja la lógica de negocio de los clientes
class ClientesLogicService {
  final DatosService _datosService = DatosService();
  late final ClientesStateService _stateService;
  
  ClientesLogicService(ClientesStateService stateService) : _stateService = stateService;

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando ClientesLogicService...');
      await _datosService.initialize();
      LoggingService.info('✅ ClientesLogicService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando ClientesLogicService: $e');
      _stateService.updateError('Error inicializando servicio: $e');
    }
  }

  /// Cargar clientes
  Future<void> loadClientes() async {
    try {
      _stateService.updateLoading(true);
      _stateService.clearError();
      
      LoggingService.info('👥 Cargando clientes...');
      final clientes = await _datosService.getClientes();
      
      _stateService.updateClientes(clientes);
      _stateService.updateLoading(false);
      
      LoggingService.info('✅ Clientes cargados: ${clientes.length}');
    } catch (e) {
      LoggingService.error('❌ Error cargando clientes: $e');
      _stateService.updateError('Error cargando clientes: $e');
      _stateService.updateLoading(false);
    }
  }

  /// Crear cliente
  Future<bool> crearCliente({
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) async {
    try {
      LoggingService.info('➕ Creando cliente: $nombre');
      
      final nuevoCliente = ClientesFunctions.createCliente(
        nombre: nombre,
        telefono: telefono,
        email: email,
        direccion: direccion,
        notas: notas,
      );
      
      await _datosService.saveCliente(nuevoCliente);
      
      // Recargar clientes después de crear
      await loadClientes();
      
      LoggingService.info('✅ Cliente creado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error creando cliente: $e');
      _stateService.updateError('Error creando cliente: $e');
      return false;
    }
  }

  /// Actualizar cliente
  Future<bool> actualizarCliente({
    required Cliente cliente,
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) async {
    try {
      LoggingService.info('✏️ Actualizando cliente: ${cliente.nombre}');
      
      final clienteActualizado = ClientesFunctions.updateCliente(
        cliente: cliente,
        nombre: nombre,
        telefono: telefono,
        email: email,
        direccion: direccion,
        notas: notas,
      );
      
      await _datosService.updateCliente(clienteActualizado);
      
      // Recargar clientes después de actualizar
      await loadClientes();
      
      LoggingService.info('✅ Cliente actualizado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error actualizando cliente: $e');
      _stateService.updateError('Error actualizando cliente: $e');
      return false;
    }
  }

  /// Eliminar cliente
  Future<bool> eliminarCliente(int clienteId) async {
    try {
      LoggingService.info('🗑️ Eliminando cliente: $clienteId');
      
      await _datosService.deleteCliente(clienteId);
      
      // Recargar clientes después de eliminar
      await loadClientes();
      
      LoggingService.info('✅ Cliente eliminado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error eliminando cliente: $e');
      _stateService.updateError('Error eliminando cliente: $e');
      return false;
    }
  }

  /// Validar formulario de cliente
  Map<String, String?> validateFormulario({
    required String nombre,
    required String telefono,
    required String email,
    required String direccion,
    required String notas,
  }) {
    return {
      'nombre': ClientesFunctions.validateNombre(nombre),
      'telefono': ClientesFunctions.validateTelefono(telefono),
      'email': ClientesFunctions.validateEmail(email),
      'direccion': null, // Dirección es opcional
      'notas': null, // Notas son opcionales
    };
  }

  /// Recargar datos
  Future<void> refreshData() async {
    try {
      LoggingService.info('🔄 Recargando datos de clientes...');
      await loadClientes();
      LoggingService.info('✅ Datos de clientes recargados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error recargando datos: $e');
      _stateService.updateError('Error recargando datos: $e');
    }
  }
}
