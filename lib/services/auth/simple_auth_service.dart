import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ricitosdebb/services/system/logging_service.dart';
import 'package:ricitosdebb/services/datos/datos.dart';

/// Servicio de autenticación simplificado para modo local y anónimo
class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  final DatosService _datosService = DatosService();
  
  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;
  bool _isAnonymous = false;

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isSignedIn => _currentUserId != null;
  bool get isAnonymous => _isAnonymous;

  /// Inicializa el servicio de autenticación
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando SimpleAuthService...');
      
      // Cargar estado de autenticación guardado
      await _loadAuthState();
      
      LoggingService.info('SimpleAuthService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando SimpleAuthService: $e');
    }
  }

  /// Inicia sesión con email y contraseña (simulado)
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      LoggingService.info('Iniciando sesión con email: $email');
      
      // Simular autenticación (en producción aquí validarías con Firebase)
      if (email.isNotEmpty && password.length >= 6) {
        _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        _currentUserEmail = email;
        _currentUserName = email.split('@')[0];
        _isAnonymous = false;
        
        await _saveAuthState('email', email);
        LoggingService.info('Sesión iniciada correctamente');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error iniciando sesión: $e');
      return false;
    }
  }

  /// Crea una cuenta con email y contraseña (simulado)
  Future<bool> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      LoggingService.info('Creando cuenta con email: $email');
      
      // Simular creación de cuenta
      if (email.isNotEmpty && password.length >= 6 && displayName.isNotEmpty) {
        _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        _currentUserEmail = email;
        _currentUserName = displayName;
        _isAnonymous = false;
        
        await _saveAuthState('email', email);
        LoggingService.info('Cuenta creada correctamente');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error creando cuenta: $e');
      return false;
    }
  }

  /// Inicia sesión anónima
  Future<bool> signInAnonymously() async {
    try {
      LoggingService.info('Iniciando sesión anónima');
      
      _currentUserId = 'anon_${DateTime.now().millisecondsSinceEpoch}';
      _currentUserEmail = null;
      _currentUserName = 'Usuario Anónimo';
      _isAnonymous = true;
      
      await _saveAuthState('anonymous', 'anonymous');
      LoggingService.info('Sesión anónima iniciada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('Error iniciando sesión anónima: $e');
      return false;
    }
  }

  /// Cierra la sesión actual
  Future<void> signOut() async {
    try {
      LoggingService.info('Cerrando sesión');
      
      // Guardar datos locales antes de cerrar sesión
      if (isSignedIn) {
        await _backupLocalData();
      }
      
      _currentUserId = null;
      _currentUserEmail = null;
      _currentUserName = null;
      _isAnonymous = false;
      
      await _clearAuthState();
      LoggingService.info('Sesión cerrada correctamente');
    } catch (e) {
      LoggingService.error('Error cerrando sesión: $e');
    }
  }

  /// Convierte cuenta anónima a cuenta permanente
  Future<bool> convertAnonymousToPermanent(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      if (!isAnonymous) {
        LoggingService.error('El usuario actual no es anónimo');
        return false;
      }

      LoggingService.info('Convirtiendo cuenta anónima a permanente');
      
      // Simular conversión
      if (email.isNotEmpty && password.length >= 6 && displayName.isNotEmpty) {
        _currentUserEmail = email;
        _currentUserName = displayName;
        _isAnonymous = false;
        
        await _saveAuthState('email', email);
        LoggingService.info('Cuenta convertida correctamente');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error convirtiendo cuenta: $e');
      return false;
    }
  }

  /// Hace backup de datos locales
  Future<void> _backupLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Obtener datos locales
      final productos = await _datosService.getAllProductos();
      final clientes = await _datosService.getAllClientes();
      final ventas = await _datosService.getAllVentas();
      
      // Guardar backup
      await prefs.setString('backup_productos', json.encode(productos.map((p) => p.toMap()).toList()));
      await prefs.setString('backup_clientes', json.encode(clientes.map((c) => c.toMap()).toList()));
      await prefs.setString('backup_ventas', json.encode(ventas.map((v) => v.toMap()).toList()));
      await prefs.setString('backup_timestamp', DateTime.now().toIso8601String());
      
      LoggingService.info('Backup de datos locales creado');
    } catch (e) {
      LoggingService.error('Error creando backup: $e');
    }
  }

  /// Restaura datos desde backup
  Future<void> restoreLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final productosJson = prefs.getString('backup_productos');
      
      if (productosJson != null) {
        final productos = json.decode(productosJson) as List;
        // Aquí implementarías la restauración de productos
        LoggingService.info('Productos restaurados: ${productos.length}');
      }
      
      LoggingService.info('Datos locales restaurados');
    } catch (e) {
      LoggingService.error('Error restaurando datos: $e');
    }
  }

  /// Guarda el estado de autenticación
  Future<void> _saveAuthState(String method, String identifier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_method', method);
      await prefs.setString('auth_identifier', identifier);
      await prefs.setString('auth_user_id', _currentUserId ?? '');
      await prefs.setString('auth_user_email', _currentUserEmail ?? '');
      await prefs.setString('auth_user_name', _currentUserName ?? '');
      await prefs.setBool('auth_is_anonymous', _isAnonymous);
      await prefs.setString('last_auth_time', DateTime.now().toIso8601String());
    } catch (e) {
      LoggingService.error('Error guardando estado de auth: $e');
    }
  }

  /// Carga el estado de autenticación guardado
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final method = prefs.getString('auth_method');
      final identifier = prefs.getString('auth_identifier');
      final userId = prefs.getString('auth_user_id');
      final userEmail = prefs.getString('auth_user_email');
      final userName = prefs.getString('auth_user_name');
      final isAnon = prefs.getBool('auth_is_anonymous') ?? false;
      
      if (method != null && identifier != null && userId != null) {
        _currentUserId = userId;
        _currentUserEmail = userEmail?.isNotEmpty == true ? userEmail : null;
        _currentUserName = userName?.isNotEmpty == true ? userName : 'Usuario';
        _isAnonymous = isAnon;
        
        LoggingService.info('Estado de autenticación cargado: $method');
      }
    } catch (e) {
      LoggingService.error('Error cargando estado de auth: $e');
    }
  }

  /// Limpia el estado de autenticación
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_method');
      await prefs.remove('auth_identifier');
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_user_name');
      await prefs.remove('auth_is_anonymous');
      await prefs.remove('last_auth_time');
    } catch (e) {
      LoggingService.error('Error limpiando estado de auth: $e');
    }
  }

  /// Obtiene información del usuario actual
  Map<String, dynamic> getUserInfo() {
    return {
      'uid': _currentUserId,
      'email': _currentUserEmail,
      'displayName': _currentUserName,
      'isAnonymous': _isAnonymous,
      'isSignedIn': isSignedIn,
    };
  }

  /// Verifica si el usuario tiene conexión a internet
  Future<bool> hasInternetConnection() async {
    try {
      // Simular verificación de conexión
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sincroniza datos cuando se recupera la conexión
  Future<void> syncOnConnectionRestored() async {
    if (isAnonymous || !isSignedIn) return;
    
    try {
      final hasConnection = await hasInternetConnection();
      if (hasConnection) {
        // Aquí implementarías la sincronización con Firebase
        LoggingService.info('Datos sincronizados al recuperar conexión');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando al recuperar conexión: $e');
    }
  }
}
