import 'package:flutter/material.dart';
import 'ml_consent_service.dart';
import 'logging_service.dart';
import '../widgets/ml_consent_widget.dart';

/// Servicio para manejar la lógica de mostrar el consentimiento ML
class ConsentManagerService {
  static final ConsentManagerService _instance = ConsentManagerService._internal();
  factory ConsentManagerService() => _instance;
  ConsentManagerService._internal();

  final MLConsentService _consentService = MLConsentService();

  /// Verifica si debe mostrar el consentimiento y lo muestra si es necesario
  Future<void> checkAndShowConsentIfNeeded(BuildContext context) async {
    try {
      LoggingService.info('Verificando si debe mostrar consentimiento ML...');
      
      // Verificar si ya se mostró el consentimiento
      final hasShown = await _consentService.hasConsentBeenShown();
      
      if (!hasShown) {
        LoggingService.info('Mostrando consentimiento ML por primera vez');
        await _showConsentModal(context);
        await _consentService.markConsentAsShown();
      } else {
        LoggingService.info('Consentimiento ya fue mostrado anteriormente');
      }
    } catch (e) {
      LoggingService.error('Error verificando consentimiento: $e');
    }
  }

  /// Muestra el modal de consentimiento
  Future<void> _showConsentModal(BuildContext context) async {
    try {
      await MLConsentWidget.showConsentModal(context);
      LoggingService.info('Modal de consentimiento mostrado');
    } catch (e) {
      LoggingService.error('Error mostrando modal de consentimiento: $e');
    }
  }

  /// Fuerza la visualización del consentimiento (para testing o configuración)
  Future<void> forceShowConsent(BuildContext context) async {
    try {
      LoggingService.info('Forzando visualización de consentimiento ML');
      await _showConsentModal(context);
    } catch (e) {
      LoggingService.error('Error forzando visualización de consentimiento: $e');
    }
  }

  /// Resetea el estado del consentimiento (para testing)
  Future<void> resetConsentState() async {
    try {
      await _consentService.resetConsentState();
      LoggingService.info('Estado de consentimiento reseteado');
    } catch (e) {
      LoggingService.error('Error reseteando estado de consentimiento: $e');
    }
  }

  /// Obtiene estadísticas del consentimiento
  Future<Map<String, dynamic>> getConsentStats() async {
    try {
      return await _consentService.getConsentStats();
    } catch (e) {
      LoggingService.error('Error obteniendo estadísticas de consentimiento: $e');
      return {};
    }
  }
}
