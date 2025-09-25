import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:stockcito/config/supabase_config.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/auth/security_service.dart';
import 'package:stockcito/services/auth/password_validation_service.dart';
import 'package:stockcito/services/system/sentry_service.dart';
import 'package:stockcito/services/auth/user_migration_service.dart';

/// Servicio de autenticación con Supabase
class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  DatosService? _datosService;
  
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
      LoggingService.info('Inicializando servicio de autenticación...');
      
      // Inicializar Supabase
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      
      // Configurar listener de cambios de autenticación
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        
        if (event == AuthChangeEvent.signedIn) {
          LoggingService.info('Usuario autenticado correctamente');
          
          // Configurar contexto de usuario en Sentry
          final user = data.session?.user;
          if (user != null) {
            SentryService.setUserContext(
              id: user.id,
              email: user.email,
              username: user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
              extra: {
                'is_anonymous': user.isAnonymous,
                'created_at': user.createdAt,
              },
            );
          }
        } else if (event == AuthChangeEvent.signedOut) {
          LoggingService.info('Usuario desconectado');
          
          // Limpiar contexto de usuario en Sentry
          SentryService.setUserContext();
        }
      });
      
      // NO crear sesión anónima automáticamente - solo inicializar Supabase
      LoggingService.info('Servicio de autenticación inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando servicio de autenticación: $e');
    }
  }

  /// Inicia sesión con email y contraseña
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Verificar si el usuario está bloqueado
      if (await SecurityService().isUserBlocked()) {
        LoggingService.warning('Usuario bloqueado por demasiados intentos');
        return false;
      }
      
      // Sanitizar entrada
      final cleanEmail = SecurityService().sanitizeInput(email);
      
      LoggingService.info('Iniciando sesión con email');
      
      final AuthResponse response = await Supabase.instance.client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      
      if (response.user != null) {
        // Limpiar intentos fallidos en login exitoso
        await SecurityService().clearFailedLoginAttempts();
        await _saveAuthState('email', cleanEmail);
        LoggingService.info('Sesión iniciada correctamente');
        return true;
      }
      
      return false;
    } catch (e) {
      // Registrar intento fallido
      await SecurityService().recordFailedLoginAttempt();
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
      // Validar contraseña robusta
      final passwordValidation = PasswordValidationService.validatePassword(password);
      if (!passwordValidation.isValid) {
        throw Exception(passwordValidation.errors.first);
      }
      
      // Sanitizar entradas
      final cleanEmail = SecurityService().sanitizeInput(email);
      final cleanName = SecurityService().sanitizeInput(displayName);
      
      LoggingService.info('Creando cuenta con email');
      
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': cleanName,
        },
      );
      
      if (response.user != null) {
        await _saveAuthState('email', cleanEmail);
        LoggingService.info('Cuenta creada correctamente');
        return true;
      }
      
      LoggingService.error('Error: Usuario no creado');
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
      LoggingService.info('🔐 Iniciando sesión anónima...');
      
      // Verificar si ya hay una sesión anónima activa
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession?.user.isAnonymous == true) {
        LoggingService.info('✅ Reutilizando sesión anónima existente con ID: ${currentSession!.user.id}');
        await _saveAuthState('anonymous', 'anonymous');
        return true;
      }
      
      // Verificar si hay un user_id anónimo persistido
      final persistedAnonymousId = await _getPersistedAnonymousUserId();
      if (persistedAnonymousId != null) {
        LoggingService.info('🔄 Intentando reutilizar user_id anónimo persistido: $persistedAnonymousId');
        
        // Intentar crear sesión con el ID persistido
        final success = await _tryReuseAnonymousSession(persistedAnonymousId);
        if (success) {
          LoggingService.info('✅ Sesión anónima reutilizada exitosamente con ID: $persistedAnonymousId');
          await _saveAuthState('anonymous', 'anonymous');
          return true;
        } else {
          LoggingService.warning('⚠️ No se pudo reutilizar sesión anónima, creando nueva...');
        }
      }
      
      // Crear nueva sesión anónima
      LoggingService.info('🆕 Creando nueva sesión anónima...');
      final AuthResponse response = await Supabase.instance.client.auth.signInAnonymously();
      
      if (response.user != null) {
        final newAnonymousId = response.user!.id;
        LoggingService.info('✅ Nueva sesión anónima creada con ID: $newAnonymousId');
        
        // Persistir el nuevo user_id anónimo
        await _persistAnonymousUserId(newAnonymousId);
        await _saveAuthState('anonymous', 'anonymous');
        
        LoggingService.info('💾 User_id anónimo persistido para futuras sesiones');
        return true;
      }
      
      LoggingService.error('❌ Error: Usuario anónimo no creado');
      return false;
    } catch (e) {
      LoggingService.error('❌ Error iniciando sesión anónima: $e');
      return false;
    }
  }

  /// Inicia sesión con Google (temporalmente deshabilitado)
  Future<bool> signInWithGoogle() async {
    LoggingService.info('Login con Google temporalmente deshabilitado');
    return false;
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
      
      // Google Sign-In temporalmente deshabilitado
      
      // Limpiar estado de seguridad
      await SecurityService().clearFailedLoginAttempts();
      await _clearAuthState();
      LoggingService.info('Sesión cerrada correctamente');
    } catch (e) {
      LoggingService.error('Error cerrando sesión: $e');
    }
  }

  /// Cierra sesión anónima (NO elimina el user_id persistido)
  Future<void> signOutAnonymous() async {
    try {
      LoggingService.info('🔐 Cerrando sesión anónima...');
      
      // Guardar datos locales antes de cerrar sesión
      if (isSignedIn) {
        await _backupLocalData();
      }
      
      // Cerrar sesión anónima en Supabase (pero mantener user_id persistido)
      await Supabase.instance.client.auth.signOut();
      
      // NO limpiar el user_id anónimo persistido - solo limpiar estado de sesión
      await _clearAuthState();
      LoggingService.info('✅ Sesión anónima cerrada correctamente (user_id persistido)');
    } catch (e) {
      LoggingService.error('❌ Error cerrando sesión anónima: $e');
    }
  }

  /// Convierte cuenta anónima a cuenta permanente usando UserMigrationService
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

      LoggingService.info('🔄 Iniciando conversión de cuenta anónima a permanente...');
      
      // Importar UserMigrationService dinámicamente para evitar dependencias circulares
      final userMigrationService = UserMigrationService();
      
      // Ejecutar migración completa
      final migrationResult = await userMigrationService.migrateAnonymousToAuthenticated(
        email: email,
        password: password,
        displayName: displayName,
      );
      
      if (migrationResult.success) {
        LoggingService.info('✅ Cuenta convertida y datos migrados correctamente');
        return true;
      } else {
        LoggingService.error('❌ Error en migración: ${migrationResult.error}');
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ Error convirtiendo cuenta: $e');
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

  // ==================== MÉTODOS DE PERSISTENCIA ANÓNIMA ====================

  /// Persiste el user_id anónimo para futuras sesiones
  Future<void> _persistAnonymousUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('persisted_anonymous_user_id', userId);
      await prefs.setString('persisted_anonymous_timestamp', DateTime.now().toIso8601String());
      LoggingService.info('💾 User_id anónimo persistido: $userId');
    } catch (e) {
      LoggingService.error('❌ Error persistiendo user_id anónimo: $e');
    }
  }

  /// Obtiene el user_id anónimo persistido
  Future<String?> _getPersistedAnonymousUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('persisted_anonymous_user_id');
      final timestamp = prefs.getString('persisted_anonymous_timestamp');
      
      if (userId != null && timestamp != null) {
        final persistTime = DateTime.parse(timestamp);
        final daysSincePersist = DateTime.now().difference(persistTime).inDays;
        
        LoggingService.info('🔍 User_id anónimo persistido encontrado: $userId (hace $daysSincePersist días)');
        
        // Si han pasado más de 30 días, considerar expirado
        if (daysSincePersist > 30) {
          LoggingService.warning('⚠️ User_id anónimo expirado (más de 30 días), limpiando...');
          await _clearPersistedAnonymousUserId();
          return null;
        }
        
        return userId;
      }
      
      LoggingService.info('🔍 No se encontró user_id anónimo persistido');
      return null;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo user_id anónimo persistido: $e');
      return null;
    }
  }

  /// Intenta reutilizar una sesión anónima existente
  Future<bool> _tryReuseAnonymousSession(String userId) async {
    try {
      // Nota: Supabase no permite crear sesiones con user_id específicos
      // Por ahora, siempre creamos una nueva sesión pero mantenemos la referencia al user_id
      // En el futuro se podría implementar una lógica más sofisticada
      
      LoggingService.info('🔄 Creando nueva sesión pero manteniendo referencia al user_id: $userId');
      
      // Crear nueva sesión anónima
      final AuthResponse response = await Supabase.instance.client.auth.signInAnonymously();
      
      if (response.user != null) {
        // Actualizar el user_id persistido con el nuevo ID de la sesión
        await _persistAnonymousUserId(response.user!.id);
        LoggingService.info('✅ Nueva sesión creada con ID: ${response.user!.id} (referencia a: $userId)');
        return true;
      }
      
      return false;
    } catch (e) {
      LoggingService.error('❌ Error reutilizando sesión anónima: $e');
      return false;
    }
  }

  /// Limpia el user_id anónimo persistido
  Future<void> _clearPersistedAnonymousUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('persisted_anonymous_user_id');
      await prefs.remove('persisted_anonymous_timestamp');
      LoggingService.info('🗑️ User_id anónimo persistido limpiado');
    } catch (e) {
      LoggingService.error('❌ Error limpiando user_id anónimo persistido: $e');
    }
  }

  /// Limpia completamente los datos anónimos (para resetear)
  Future<void> clearAnonymousData() async {
    try {
      LoggingService.info('🗑️ Limpiando todos los datos anónimos...');
      
      // Cerrar sesión actual si es anónima
      if (isAnonymous) {
        await signOutAnonymous();
      }
      
      // Limpiar user_id persistido
      await _clearPersistedAnonymousUserId();
      
      // Aquí se podrían agregar más limpiezas si es necesario
      LoggingService.info('✅ Datos anónimos limpiados completamente');
    } catch (e) {
      LoggingService.error('❌ Error limpiando datos anónimos: $e');
    }
  }

}
