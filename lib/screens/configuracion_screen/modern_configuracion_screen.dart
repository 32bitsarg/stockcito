import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';

// Importar widgets refactorizados
import 'widgets/configuracion_header.dart';
import 'widgets/configuracion_precios_section.dart';
import 'widgets/configuracion_tema_section.dart';
import 'widgets/configuracion_notificaciones_section.dart';
import 'widgets/configuracion_ia_section.dart';
import 'widgets/configuracion_avanzada_section.dart';
import 'widgets/configuracion_conectividad_section.dart';
import 'widgets/configuracion_backup_section.dart';
import 'widgets/configuracion_action_buttons.dart';

// Importar funciones
import 'functions/configuracion_functions.dart';

class ModernConfiguracionScreen extends StatefulWidget {
  const ModernConfiguracionScreen({super.key});

  @override
  State<ModernConfiguracionScreen> createState() => _ModernConfiguracionScreenState();
}

class _ModernConfiguracionScreenState extends State<ModernConfiguracionScreen> {
  double _margenDefecto = 50.0;
  double _iva = 21.0;
  String _moneda = 'USD';
  bool _notificacionesStock = true;
  bool _notificacionesVentas = false;
  bool _exportarAutomatico = false;
  bool _respaldoAutomatico = true;
  bool _mlConsentimiento = false;
  int _stockMinimo = 5;

  @override
  void initState() {
    super.initState();
    _loadConfiguracion();
  }

  Future<void> _loadConfiguracion() async {
    try {
      final config = await ConfiguracionFunctions.loadConfiguracion();
      setState(() {
        _stockMinimo = config['stockMinimo'];
        _notificacionesStock = config['notificacionesStock'];
        _notificacionesVentas = config['notificacionesVentas'];
        _margenDefecto = config['margenDefecto'];
        _iva = config['iva'];
        _moneda = config['moneda'];
        _exportarAutomatico = config['exportarAutomatico'];
        _respaldoAutomatico = config['respaldoAutomatico'];
        _mlConsentimiento = config['mlConsentimiento'];
      });
    } catch (e) {
      print('Error cargando configuración: $e');
    }
  }

  Future<void> _guardarConfiguracion() async {
    try {
      final config = {
        'stockMinimo': _stockMinimo,
        'notificacionesStock': _notificacionesStock,
        'notificacionesVentas': _notificacionesVentas,
        'margenDefecto': _margenDefecto,
        'iva': _iva,
        'moneda': _moneda,
        'exportarAutomatico': _exportarAutomatico,
        'respaldoAutomatico': _respaldoAutomatico,
        'mlConsentimiento': _mlConsentimiento,
      };

      final success = await ConfiguracionFunctions.saveConfiguracion(config);
      
      if (success && mounted) {
        ConfiguracionFunctions.showSuccessSnackBar(
          context, 
          'Configuración guardada exitosamente'
        );
      } else if (mounted) {
        ConfiguracionFunctions.showErrorSnackBar(
          context, 
          'Error guardando configuración'
        );
      }
    } catch (e) {
      if (mounted) {
        ConfiguracionFunctions.showErrorSnackBar(
          context, 
          'Error guardando configuración: $e'
        );
      }
    }
  }

  Future<void> _toggleMLConsentimiento(bool value) async {
    try {
      setState(() {
        _mlConsentimiento = value;
      });

      final success = await ConfiguracionFunctions.toggleMLConsentimiento(value);

      if (mounted) {
        if (success) {
          ConfiguracionFunctions.showSuccessSnackBar(
            context,
            value 
              ? 'Consentimiento otorgado. La IA se entrenará con todos los datos disponibles.'
              : 'Consentimiento revocado. La IA solo usará datos locales.',
          );
        } else {
          ConfiguracionFunctions.showErrorSnackBar(
            context,
            'Error actualizando consentimiento'
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ConfiguracionFunctions.showErrorSnackBar(
          context,
          'Error actualizando consentimiento: $e'
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ConfiguracionHeader(onGuardar: _guardarConfiguracion),
            const SizedBox(height: 24),
            // Configuración de precios
            ConfiguracionPreciosSection(
              margenDefecto: _margenDefecto,
              iva: _iva,
              moneda: _moneda,
              onMargenChanged: (value) => setState(() => _margenDefecto = value),
              onIvaChanged: (value) => setState(() => _iva = value),
              onMonedaChanged: (value) => setState(() => _moneda = value),
            ),
            const SizedBox(height: 24),
            // Configuración de tema
            const ConfiguracionTemaSection(),
            const SizedBox(height: 24),
            // Configuración de notificaciones
            ConfiguracionNotificacionesSection(
              notificacionesStock: _notificacionesStock,
              notificacionesVentas: _notificacionesVentas,
              stockMinimo: _stockMinimo,
              onNotificacionesStockChanged: (value) => setState(() => _notificacionesStock = value),
              onNotificacionesVentasChanged: (value) => setState(() => _notificacionesVentas = value),
              onStockMinimoChanged: (value) => setState(() => _stockMinimo = value),
            ),
            const SizedBox(height: 24),
            // Configuración de IA y Privacidad
            ConfiguracionIASection(
              mlConsentimiento: _mlConsentimiento,
              onMLConsentimientoChanged: _toggleMLConsentimiento,
            ),
            const SizedBox(height: 24),
            // Configuración avanzada
            ConfiguracionAvanzadaSection(
              exportarAutomatico: _exportarAutomatico,
              respaldoAutomatico: _respaldoAutomatico,
              onExportarAutomaticoChanged: (value) => setState(() => _exportarAutomatico = value),
              onRespaldoAutomaticoChanged: (value) => setState(() => _respaldoAutomatico = value),
            ),
            const SizedBox(height: 24),
            // Configuración de conectividad y sincronización
            const ConfiguracionConectividadSection(),
            const SizedBox(height: 24),
            // Configuración de backup automático
            const ConfiguracionBackupSection(),
            const SizedBox(height: 24),
            // Botones de acción
            ConfiguracionActionButtons(
              onRestaurar: _restaurarValores,
              onExportar: _exportarConfiguracion,
              onImportar: _importarConfiguracion,
            ),
          ],
        ),
      ),
    );
  }

  void _restaurarValores() {
    setState(() {
      final defaultConfig = ConfiguracionFunctions.getDefaultConfiguracion();
      _margenDefecto = defaultConfig['margenDefecto'];
      _iva = defaultConfig['iva'];
      _moneda = defaultConfig['moneda'];
      _notificacionesStock = defaultConfig['notificacionesStock'];
      _notificacionesVentas = defaultConfig['notificacionesVentas'];
      _exportarAutomatico = defaultConfig['exportarAutomatico'];
      _respaldoAutomatico = defaultConfig['respaldoAutomatico'];
      _stockMinimo = defaultConfig['stockMinimo'];
    });
  }

  void _exportarConfiguracion() {
    // Implementar exportación de configuración
    ConfiguracionFunctions.showWarningSnackBar(
      context,
      'Funcionalidad de exportación en desarrollo'
    );
  }

  void _importarConfiguracion() {
    // Implementar importación de configuración
    ConfiguracionFunctions.showWarningSnackBar(
      context,
      'Funcionalidad de importación en desarrollo'
    );
  }
}
