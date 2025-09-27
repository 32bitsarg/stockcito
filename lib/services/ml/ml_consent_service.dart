import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'ml_training_service.dart';
import 'package:stockcito/services/system/data_migration_service.dart';
import 'package:stockcito/services/auth/supabase_auth_service.dart';

/// Servicio para manejar el consentimiento de ML y migración de datos
class MLConsentService {
  static final MLConsentService _instance = MLConsentService._internal();
  factory MLConsentService() => _instance;
  MLConsentService._internal();

  static const String _consentShownKey = 'ml_consent_shown';
  static const String _consentGivenKey = 'ml_consent_given';
  static const String _dataMigratedKey = 'ml_data_migrated';

  MLTrainingService? _mlTrainingService;
  DataMigrationService? _dataMigrationService;

  /// Inicializa los servicios (inyección de dependencia)
  void initializeServices({
    required MLTrainingService mlTrainingService,
    required DataMigrationService dataMigrationService,
  }) {
    _mlTrainingService = mlTrainingService;
    _dataMigrationService = dataMigrationService;
  }

  /// Verifica si ya se mostró el consentimiento
  Future<bool> hasConsentBeenShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_consentShownKey) ?? false;
    } catch (e) {
      LoggingService.error('Error verificando consentimiento mostrado: $e');
      return false;
    }
  }

  /// Marca que el consentimiento ya se mostró
  Future<void> markConsentAsShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentShownKey, true);
      LoggingService.info('Consentimiento marcado como mostrado');
    } catch (e) {
      LoggingService.error('Error marcando consentimiento como mostrado: $e');
    }
  }

  /// Verifica si el usuario dio consentimiento
  Future<bool> hasUserGivenConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasConsent = prefs.getBool(_consentGivenKey);
      
      // Si no hay valor guardado, activar consentimiento por defecto para usuarios autenticados
      if (hasConsent == null) {
        LoggingService.info('Consentimiento no establecido, activando por defecto para usuarios autenticados');
        await _setDefaultConsentForAuthenticatedUsers();
        return prefs.getBool(_consentGivenKey) ?? false;
      }
      
      return hasConsent;
    } catch (e) {
      LoggingService.error('Error verificando consentimiento del usuario: $e');
      return false;
    }
  }

  /// Establece el consentimiento del usuario
  Future<void> setUserConsent(bool consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentGivenKey, consent);
      LoggingService.info('Consentimiento del usuario establecido: $consent');
    } catch (e) {
      LoggingService.error('Error estableciendo consentimiento del usuario: $e');
    }
  }

  /// Establece consentimiento por defecto para usuarios autenticados
  Future<void> _setDefaultConsentForAuthenticatedUsers() async {
    try {
      // Importar el servicio de autenticación para verificar si el usuario está autenticado
      final authService = SupabaseAuthService();
      
      // Solo activar consentimiento por defecto para usuarios autenticados (no anónimos)
      if (authService.isSignedIn && !authService.isAnonymous) {
        LoggingService.info('Usuario autenticado detectado, activando consentimiento por defecto');
        await setUserConsent(true);
        await _markConsentAsAutomatic();
        LoggingService.info('✅ Consentimiento activado por defecto para usuario autenticado');
      } else {
        LoggingService.info('Usuario anónimo o no autenticado, consentimiento permanece desactivado');
        await setUserConsent(false);
      }
    } catch (e) {
      LoggingService.error('Error estableciendo consentimiento por defecto: $e');
      // En caso de error, establecer como false por seguridad
      await setUserConsent(false);
    }
  }

  /// Verifica si los datos ya fueron migrados
  Future<bool> hasDataBeenMigrated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_dataMigratedKey) ?? false;
    } catch (e) {
      LoggingService.error('Error verificando migración de datos: $e');
      return false;
    }
  }

  /// Marca que los datos fueron migrados
  Future<void> markDataAsMigrated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dataMigratedKey, true);
      LoggingService.info('Datos marcados como migrados');
    } catch (e) {
      LoggingService.error('Error marcando datos como migrados: $e');
    }
  }

  /// Procesa el consentimiento del usuario y migra datos si es necesario
  Future<void> processUserConsent(bool consent) async {
    if (_mlTrainingService == null || _dataMigrationService == null) {
      LoggingService.error('Servicios no inicializados en MLConsentService');
      return;
    }

    try {
      LoggingService.info('Procesando consentimiento del usuario: $consent');
      
      // Establecer consentimiento
      await setUserConsent(consent);
      
      if (consent) {
        // Si el usuario da consentimiento, verificar y migrar datos existentes
        LoggingService.info('Usuario activó consentimiento. Verificando datos para migrar...');
        await _dataMigrationService!.checkAndMigrateDataOnConsent();
        
        // Entrenar IA con datos actuales
        LoggingService.info('Entrenando IA con datos actuales...');
        await _mlTrainingService!.initialize();
      } else {
        LoggingService.info('Usuario revocó consentimiento, solo entrenamiento local');
        // Marcar que los datos ya no se migrarán automáticamente
        await _resetMigrationStatus();
      }
    } catch (e) {
      LoggingService.error('Error procesando consentimiento: $e');
    }
  }


  /// Resetea el estado de migración cuando se revoca el consentimiento
  Future<void> _resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dataMigratedKey);
      LoggingService.info('Estado de migración reseteado');
    } catch (e) {
      LoggingService.error('Error reseteando estado de migración: $e');
    }
  }

  /// Resetea el estado del consentimiento (para testing)
  Future<void> resetConsentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentShownKey);
      await prefs.remove(_consentGivenKey);
      await prefs.remove(_dataMigratedKey);
      LoggingService.info('Estado de consentimiento reseteado');
    } catch (e) {
      LoggingService.error('Error reseteando estado de consentimiento: $e');
    }
  }

  /// Verifica si el consentimiento fue establecido automáticamente (por defecto)
  Future<bool> wasConsentSetAutomatically() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('consent_set_automatically') ?? false;
    } catch (e) {
      LoggingService.error('Error verificando si consentimiento fue automático: $e');
      return false;
    }
  }

  /// Marca que el consentimiento fue establecido automáticamente
  Future<void> _markConsentAsAutomatic() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('consent_set_automatically', true);
      LoggingService.info('Consentimiento marcado como establecido automáticamente');
    } catch (e) {
      LoggingService.error('Error marcando consentimiento como automático: $e');
    }
  }

  /// Obtiene estadísticas del consentimiento
  Future<Map<String, dynamic>> getConsentStats() async {
    try {
      final hasShown = await hasConsentBeenShown();
      final hasConsent = await hasUserGivenConsent();
      final hasMigrated = await hasDataBeenMigrated();
      final isAutomatic = await wasConsentSetAutomatically();
      
      return {
        'consent_shown': hasShown,
        'user_consent': hasConsent,
        'data_migrated': hasMigrated,
        'consent_automatic': isAutomatic,
      };
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de consentimiento: $e');
      return {};
    }
  }
}
