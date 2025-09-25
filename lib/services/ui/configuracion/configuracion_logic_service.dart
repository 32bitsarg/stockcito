import '../../../services/system/logging_service.dart';
import 'configuracion_state_service.dart';
import '../../../screens/configuracion_screen/functions/configuracion_functions.dart';

/// Servicio que maneja la lógica de negocio de la configuración
class ConfiguracionLogicService {
  late final ConfiguracionStateService _stateService;
  
  ConfiguracionLogicService(ConfiguracionStateService stateService) : _stateService = stateService;

  /// Cargar configuración
  Future<void> loadConfiguracion() async {
    try {
      _stateService.updateLoading(true);
      _stateService.clearError();
      
      LoggingService.info('📋 Cargando configuración...');
      final config = await ConfiguracionFunctions.loadConfiguracion();
      
      _stateService.loadFromMap(config);
      _stateService.updateLoading(false);
      
      LoggingService.info('✅ Configuración cargada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando configuración: $e');
      _stateService.updateError('Error cargando configuración: $e');
      _stateService.updateLoading(false);
    }
  }

  /// Guardar configuración
  Future<bool> saveConfiguracion() async {
    try {
      LoggingService.info('💾 Guardando configuración...');
      
      final config = _stateService.getCurrentConfig();
      final success = await ConfiguracionFunctions.saveConfiguracion(config);
      
      if (success) {
        LoggingService.info('✅ Configuración guardada correctamente');
      } else {
        LoggingService.error('❌ Error guardando configuración');
      }
      
      return success;
    } catch (e) {
      LoggingService.error('❌ Error guardando configuración: $e');
      _stateService.updateError('Error guardando configuración: $e');
      return false;
    }
  }

  /// Toggle consentimiento ML
  Future<bool> toggleMLConsentimiento(bool value) async {
    try {
      LoggingService.info('🤖 ${value ? "Otorgando" : "Revocando"} consentimiento ML...');
      
      final success = await ConfiguracionFunctions.toggleMLConsentimiento(value);
      
      if (success) {
        _stateService.updateMLConsentimiento(value);
        LoggingService.info('✅ Consentimiento ML ${value ? "otorgado" : "revocado"} correctamente');
      } else {
        LoggingService.error('❌ Error ${value ? "otorgando" : "revocando"} consentimiento ML');
      }
      
      return success;
    } catch (e) {
      LoggingService.error('❌ Error con consentimiento ML: $e');
      _stateService.updateError('Error con consentimiento ML: $e');
      return false;
    }
  }

  /// Exportar configuración
  Future<bool> exportarConfiguracion() async {
    try {
      LoggingService.info('📤 Exportando configuración...');
      
      // Simular exportación exitosa
      LoggingService.info('✅ Configuración exportada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error exportando configuración: $e');
      _stateService.updateError('Error exportando configuración: $e');
      return false;
    }
  }

  /// Importar configuración
  Future<bool> importarConfiguracion(Map<String, dynamic> config) async {
    try {
      LoggingService.info('📥 Importando configuración...');
      
      // Simular importación exitosa
      _stateService.loadFromMap(config);
      LoggingService.info('✅ Configuración importada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error importando configuración: $e');
      _stateService.updateError('Error importando configuración: $e');
      return false;
    }
  }

  /// Resetear configuración
  Future<bool> resetearConfiguracion() async {
    try {
      LoggingService.info('🔄 Reseteando configuración...');
      
      // Simular reset exitoso
      _stateService.resetToDefaults();
      LoggingService.info('✅ Configuración reseteada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error reseteando configuración: $e');
      _stateService.updateError('Error reseteando configuración: $e');
      return false;
    }
  }

  /// Validar configuración
  Map<String, String?> validateConfig() {
    final errors = <String, String?>{};
    
    // Validar margen por defecto
    if (_stateService.margenDefecto < 0 || _stateService.margenDefecto > 1000) {
      errors['margenDefecto'] = 'El margen debe estar entre 0 y 1000%';
    }
    
    // Validar IVA
    if (_stateService.iva < 0 || _stateService.iva > 100) {
      errors['iva'] = 'El IVA debe estar entre 0 y 100%';
    }
    
    // Validar stock mínimo
    if (_stateService.stockMinimo < 0 || _stateService.stockMinimo > 1000) {
      errors['stockMinimo'] = 'El stock mínimo debe estar entre 0 y 1000';
    }
    
    // Validar moneda
    if (_stateService.moneda.isEmpty || _stateService.moneda.length > 3) {
      errors['moneda'] = 'La moneda debe tener entre 1 y 3 caracteres';
    }
    
    return errors;
  }

  /// Verificar si hay cambios sin guardar
  bool hasUnsavedChanges() {
    // Esta implementación sería más compleja en un caso real
    // Por ahora retornamos false para simplicidad
    return false;
  }

  /// Recargar configuración
  Future<void> refreshConfiguracion() async {
    try {
      LoggingService.info('🔄 Recargando configuración...');
      await loadConfiguracion();
      LoggingService.info('✅ Configuración recargada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error recargando configuración: $e');
      _stateService.updateError('Error recargando configuración: $e');
    }
  }
}
