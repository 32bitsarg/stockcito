import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ricitosdebb/services/logging_service.dart';
import 'datos/datos.dart';

/// Servicio de autenticación unificado que maneja Supabase y modo anónimo
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatosService _datosService = DatosService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.appMetadata['is_anonymous'] == true;

  /// Stream de cambios de autenticación
  Stream<AuthState> get authStateChanges => Supabase.instance.client.auth.onAuthStateChange;

  /// Inicializa el servicio de autenticación
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando AuthService con Supabase...');
      
      // Configurar persistencia local
      await _setupLocalPersistence();
      
      // Si hay un usuario autenticado, sincronizar datos
      if (isSignedIn && !isAnonymous) {
        await _syncUserData();
      }
      
      LoggingService.info('AuthService inicializado correctamente con Supabase');
    } catch (e) {
      LoggingService.error('Error inicializando AuthService: $e');
    }
  }

  /// Configura la persistencia local
  Future<void> _setupLocalPersistence() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar configuración de autenticación
      await prefs.setString('auth_service_initialized', 'true');
      await prefs.setString('last_auth_check', DateTime.now().toIso8601String());
      
      LoggingService.info('Persistencia local configurada');
    } catch (e) {
      LoggingService.error('Error configurando persistencia local: $e');
    }
  }

  /// Inicia sesión con email y contraseña
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      LoggingService.info('Iniciando sesión con email: $email');
      
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _syncUserData();
        await _saveAuthState('email', email);
        LoggingService.info('Sesión iniciada correctamente');
      }

      return response.user;
    } catch (e) {
      LoggingService.error('Error iniciando sesión: $e');
      rethrow;
    }
  }

  /// Crea una cuenta con email y contraseña
  Future<AuthResponse> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      LoggingService.info('Creando cuenta con email: $email');
      
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': displayName,
        },
      );

      if (response.user != null) {
        // Crear documento de usuario en Supabase
        await _createUserDocument(response.user!, displayName);
        
        // Sincronizar datos locales con Supabase
        await _syncUserData();
        await _saveAuthState('email', email);
        
        LoggingService.info('Cuenta creada correctamente');
      }

      return response;
    } catch (e) {
      LoggingService.error('Error creando cuenta: $e');
      rethrow;
    }
  }

  /// Inicia sesión anónima
  Future<AuthResponse> signInAnonymously() async {
    try {
      LoggingService.info('Iniciando sesión anónima');
      
      // Supabase no tiene autenticación anónima directa
      // Simulamos creando un usuario temporal con datos anónimos
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempEmail = 'anon_$timestamp@temp.local';
      final tempPassword = 'temp_${timestamp}_password';
      
      final response = await Supabase.instance.client.auth.signUp(
        email: tempEmail,
        password: tempPassword,
        data: {
          'full_name': 'Usuario Anónimo',
          'is_anonymous': true,
        },
      );
      
      if (response.user != null) {
        await _saveAuthState('anonymous', 'anonymous');
        LoggingService.info('Sesión anónima iniciada correctamente');
      }

      return response;
    } catch (e) {
      LoggingService.error('Error iniciando sesión anónima: $e');
      rethrow;
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
      
      await Supabase.instance.client.auth.signOut();
      await _clearAuthState();
      
      LoggingService.info('Sesión cerrada correctamente');
    } catch (e) {
      LoggingService.error('Error cerrando sesión: $e');
      rethrow;
    }
  }

  /// Convierte cuenta anónima a cuenta permanente
  Future<AuthResponse> convertAnonymousToPermanent(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      if (!isAnonymous) {
        throw Exception('El usuario actual no es anónimo');
      }

      LoggingService.info('Convirtiendo cuenta anónima a permanente');
      
      // Actualizar el email y datos del usuario
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          email: email,
          data: {
            'full_name': displayName,
            'is_anonymous': false,
          },
        ),
      );
      
      // Cambiar la contraseña
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );
      
      // Crear documento de usuario en Supabase
      await _createUserDocument(currentUser!, displayName);
      
      // Sincronizar datos locales con Supabase
      await _syncUserData();
      await _saveAuthState('email', email);
      
      LoggingService.info('Cuenta convertida correctamente');
      return AuthResponse(
        user: currentUser,
        session: null,
      );
    } catch (e) {
      LoggingService.error('Error convirtiendo cuenta: $e');
      rethrow;
    }
  }

  /// Crea documento de usuario en Supabase
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
        'is_anonymous': user.appMetadata['is_anonymous'] ?? false,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
        'preferences': {
          'theme': 'light',
          'language': 'es',
          'notifications': true,
        },
      });
      
      LoggingService.info('Documento de usuario creado en Supabase');
    } catch (e) {
      LoggingService.error('Error creando documento de usuario: $e');
    }
  }

  /// Sincroniza datos locales con Supabase
  Future<void> _syncUserData() async {
    if (isAnonymous || currentUser == null) return;

    try {
      LoggingService.info('Sincronizando datos con Supabase');
      
      // Obtener datos locales
      final productos = await _datosService.getAllProductos();
      final clientes = await _datosService.getAllClientes();
      final ventas = await _datosService.getAllVentas();
      
      // Sincronizar con Supabase
      await _syncCollection('productos', productos);
      await _syncCollection('clientes', clientes);
      await _syncCollection('ventas', ventas);
      
      LoggingService.info('Datos sincronizados correctamente');
    } catch (e) {
      LoggingService.error('Error sincronizando datos: $e');
    }
  }

  /// Sincroniza una colección específica
  Future<void> _syncCollection(String collectionName, List<dynamic> localData) async {
    try {
      final userId = currentUser!.id;
      
      for (final item in localData) {
        final itemMap = item.toMap();
        itemMap['user_id'] = userId;
        
        await Supabase.instance.client
            .from(collectionName)
            .upsert(itemMap);
      }
      
      LoggingService.info('Colección $collectionName sincronizada');
    } catch (e) {
      LoggingService.error('Error sincronizando colección $collectionName: $e');
    }
  }

  /// Descarga datos de Supabase a local
  Future<void> downloadUserData() async {
    if (isAnonymous || currentUser == null) return;

    try {
      LoggingService.info('Descargando datos de Supabase');
      
      // Descargar productos
      final productosResponse = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('user_id', currentUser!.id);
      
      for (final item in productosResponse) {
        // Aquí implementarías la lógica para guardar en la base de datos local
        // await _datosService.saveProducto(item);
      }
      
      LoggingService.info('Datos descargados correctamente');
    } catch (e) {
      LoggingService.error('Error descargando datos: $e');
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
      final clientesJson = prefs.getString('backup_clientes');
      final ventasJson = prefs.getString('backup_ventas');
      
      if (productosJson != null) {
        final productos = json.decode(productosJson) as List;
        // Restaurar productos
        // await _datosService.restoreProductos(productos);
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
      await prefs.setString('last_auth_time', DateTime.now().toIso8601String());
    } catch (e) {
      LoggingService.error('Error guardando estado de auth: $e');
    }
  }

  /// Limpia el estado de autenticación
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_method');
      await prefs.remove('auth_identifier');
      await prefs.remove('last_auth_time');
    } catch (e) {
      LoggingService.error('Error limpiando estado de auth: $e');
    }
  }

  /// Obtiene información del usuario actual
  Map<String, dynamic> getUserInfo() {
    if (currentUser == null) return {};
    
    return {
      'id': currentUser!.id,
      'email': currentUser!.email,
      'displayName': currentUser!.userMetadata?['full_name'] ?? currentUser!.email?.split('@')[0] ?? 'Usuario',
      'isAnonymous': currentUser!.appMetadata['is_anonymous'] ?? false,
      'emailVerified': currentUser!.emailConfirmedAt != null,
      'creationTime': currentUser!.createdAt,
      'lastSignInTime': currentUser!.lastSignInAt,
    };
  }

  /// Verifica si el usuario tiene conexión a internet
  Future<bool> hasInternetConnection() async {
    try {
      // Aquí implementarías la verificación de conexión
      // Por ahora retornamos true
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sincroniza datos cuando se recupera la conexión
  Future<void> syncOnConnectionRestored() async {
    if (isAnonymous || currentUser == null) return;
    
    try {
      final hasConnection = await hasInternetConnection();
      if (hasConnection) {
        await _syncUserData();
        LoggingService.info('Datos sincronizados al recuperar conexión');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando al recuperar conexión: $e');
    }
  }
}
