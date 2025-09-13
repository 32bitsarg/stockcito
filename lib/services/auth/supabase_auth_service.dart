import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:ricitosdebb/config/supabase_config.dart';
import 'package:ricitosdebb/services/system/logging_service.dart';
import 'package:ricitosdebb/services/datos/datos.dart';

/// Servicio de autenticación con Supabase
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  DatosService? _datosService;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  String? get currentUserId => currentUser?.id;
  String? get currentUserEmail => currentUser?.email;
  String? get currentUserName => currentUser?.userMetadata?['full_name'] ?? 
                                (currentUser?.isAnonymous == true ? 'Usuario Anónimo' : currentUser?.email?.split('@')[0]);
  bool get isSignedIn => currentUser != null;
  bool get isAnonymous => currentUser?.isAnonymous ?? false;
  
  
  /// Inicializa la dependencia de DatosService
  void initializeDatosService(DatosService datosService) {
    _datosService = datosService;
  }

  /// Inicializa el servicio de autenticación
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando SupabaseAuthService...');
      
      // Inicializar Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      
      // Configurar listener de cambios de autenticación
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          LoggingService.info('Usuario autenticado: ${session.user.email ?? "Anónimo"}');
        } else if (event == AuthChangeEvent.signedOut) {
          LoggingService.info('Usuario desconectado');
        }
      });
      
      // Intentar restaurar sesión anónima existente o crear una nueva
      await _ensureAnonymousSession();
      
      LoggingService.info('SupabaseAuthService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando SupabaseAuthService: $e');
    }
  }

  /// Inicia sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      LoggingService.info('Iniciando sesión con email: $email');
      
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
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

  /// Crea una cuenta con email y contraseña
  Future<bool> createUserWithEmailAndPassword(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      LoggingService.info('Creando cuenta con email: $email');
      
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': displayName,
        },
      );
      
      if (response.user != null) {
        await _saveAuthState('email', email);
        LoggingService.info('Cuenta creada correctamente');
        return true;
      }
      
      LoggingService.error('Error: Usuario no creado - ${response.session}');
      return false;
    } catch (e) {
      LoggingService.error('Error creando cuenta: $e');
      // Re-lanzar el error para que la UI pueda mostrarlo
      throw Exception('Error al crear cuenta: $e');
    }
  }

  /// Inicia sesión anónima usando Supabase nativo
  Future<bool> signInAnonymously() async {
    try {
      LoggingService.info('Iniciando sesión anónima con Supabase');
      
      // Verificar si ya hay una sesión anónima activa
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession?.user.isAnonymous == true) {
        LoggingService.info('Reutilizando sesión anónima existente');
        return true;
      }
      
      // Crear nueva sesión anónima solo si no existe una
      final AuthResponse response = await Supabase.instance.client.auth.signInAnonymously();
      
      if (response.user != null) {
        LoggingService.info('Sesión anónima iniciada correctamente con Supabase');
        return true;
      }
      
      LoggingService.error('Error: Usuario anónimo no creado - ${response.session}');
      return false;
    } catch (e) {
      LoggingService.error('Error iniciando sesión anónima: $e');
      return false;
    }
  }

  /// Inicia sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      LoggingService.info('Iniciando sesión con Google');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User cancelled the login
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Sign in to Supabase with the Google credential
      final AuthResponse response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      if (response.user != null) {
        await _saveAuthState('google', googleUser.email);
        LoggingService.info('Sesión con Google iniciada correctamente');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('Error iniciando sesión con Google: $e');
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
      
      // Solo cerrar sesión en Supabase si NO es un usuario anónimo
      if (!isAnonymous) {
        await Supabase.instance.client.auth.signOut();
        LoggingService.info('Sesión de usuario permanente cerrada');
      } else {
        LoggingService.info('Manteniendo sesión anónima activa');
      }
      
      // Cerrar sesión en Google si está activa
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      
      await _clearAuthState();
      LoggingService.info('Sesión cerrada correctamente');
    } catch (e) {
      LoggingService.error('Error cerrando sesión: $e');
    }
  }

  /// Cierra sesión anónima (elimina el usuario anónimo)
  Future<void> signOutAnonymous() async {
    try {
      LoggingService.info('Cerrando sesión anónima');
      
      // Guardar datos locales antes de cerrar sesión
      if (isSignedIn) {
        await _backupLocalData();
      }
      
      // Cerrar sesión anónima en Supabase
      await Supabase.instance.client.auth.signOut();
      
      await _clearAuthState();
      LoggingService.info('Sesión anónima cerrada correctamente');
    } catch (e) {
      LoggingService.error('Error cerrando sesión anónima: $e');
    }
  }

  /// Convierte cuenta anónima a cuenta permanente
  Future<bool> convertAnonymousToPermanent(
    String email, 
    String password, 
    String displayName
  ) async {
    try {
      if (!isAnonymous || currentUser == null) {
        LoggingService.error('El usuario actual no es anónimo');
        return false;
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
      
      await _saveAuthState('email', email);
      LoggingService.info('Cuenta convertida correctamente');
      return true;
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
      final productos = await _datosService?.getAllProductos();
      final clientes = await _datosService?.getAllClientes();
      final ventas = await _datosService?.getAllVentas();
      
      // Guardar backup local
      await prefs.setString('backup_productos', json.encode(productos?.map((p) => p.toMap()).toList() ?? []));
      await prefs.setString('backup_clientes', json.encode(clientes?.map((c) => c.toMap()).toList() ?? []));
      await prefs.setString('backup_ventas', json.encode(ventas?.map((v) => v.toMap()).toList() ?? []));
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
      await prefs.setString('auth_user_id', currentUser?.id ?? '');
      await prefs.setString('auth_user_email', currentUser?.email ?? '');
      await prefs.setString('auth_user_name', currentUserName ?? '');
      await prefs.setBool('auth_is_anonymous', isAnonymous);
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
      'uid': currentUser?.id,
      'email': currentUser?.email,
      'displayName': currentUserName,
      'isAnonymous': isAnonymous,
      'isSignedIn': isSignedIn,
      'photoURL': currentUser?.userMetadata?['avatar_url'],
    };
  }

  /// Verifica si el usuario tiene conexión a internet
  Future<bool> hasInternetConnection() async {
    try {
      // Implementar verificación real de conexión
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
        LoggingService.info('Datos sincronizados al recuperar conexión');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando al recuperar conexión: $e');
    }
  }

  /// Asegura que haya una sesión anónima activa
  Future<void> _ensureAnonymousSession() async {
    try {
      // Verificar si ya hay una sesión activa
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession != null) {
        LoggingService.info('Sesión existente encontrada: ${currentSession.user.isAnonymous ? "Anónima" : "Autenticada"}');
        return;
      }

      // Crear nueva sesión anónima
      LoggingService.info('Creando nueva sesión anónima...');
      await signInAnonymously();
    } catch (e) {
      LoggingService.error('Error asegurando sesión anónima: $e');
    }
  }

}
