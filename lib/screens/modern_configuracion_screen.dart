import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../services/theme_service.dart';
import '../services/datos/smart_alerts_service.dart';
import '../services/ml_consent_service.dart';
import '../widgets/windows_button.dart';

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

  final List<String> _monedas = ['USD', 'EUR', 'ARS', 'MXN', 'COP', 'BRL', 'CLP'];
  final List<String> _temas = ['Claro', 'Oscuro', 'Automático'];
  
  final MLConsentService _consentService = MLConsentService();

  @override
  void initState() {
    super.initState();
    _loadConfiguracion();
  }

  Future<void> _loadConfiguracion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasConsent = await _consentService.hasUserGivenConsent();
      setState(() {
        _stockMinimo = prefs.getInt('min_stock_level') ?? 5;
        _notificacionesStock = prefs.getBool('notificaciones_stock') ?? true;
        _notificacionesVentas = prefs.getBool('notificaciones_ventas') ?? false;
        _margenDefecto = prefs.getDouble('margen_defecto') ?? 50.0;
        _iva = prefs.getDouble('iva') ?? 21.0;
        _moneda = prefs.getString('moneda') ?? 'USD';
        _exportarAutomatico = prefs.getBool('exportar_automatico') ?? false;
        _respaldoAutomatico = prefs.getBool('respaldo_automatico') ?? true;
        _mlConsentimiento = hasConsent;
      });
    } catch (e) {
      print('Error cargando configuración: $e');
    }
  }

  Future<void> _guardarConfiguracion() async {
    // Aquí guardarías la configuración en SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('min_stock_level', _stockMinimo);
      await prefs.setBool('notificaciones_stock', _notificacionesStock);
      await prefs.setBool('notificaciones_ventas', _notificacionesVentas);
      await prefs.setDouble('margen_defecto', _margenDefecto);
      await prefs.setDouble('iva', _iva);
      await prefs.setString('moneda', _moneda);
      await prefs.setBool('exportar_automatico', _exportarAutomatico);
      await prefs.setBool('respaldo_automatico', _respaldoAutomatico);
      
      // Actualizar el servicio de alertas con la nueva configuración
      final alertsService = SmartAlertsService();
      await alertsService.updateMinStockLevel(_stockMinimo);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Configuración guardada exitosamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando configuración: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleMLConsentimiento(bool value) async {
    try {
      setState(() {
        _mlConsentimiento = value;
      });

      // Procesar el consentimiento usando el servicio
      await _consentService.processUserConsent(value);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value 
                ? 'Consentimiento otorgado. La IA se entrenará con todos los datos disponibles.'
                : 'Consentimiento revocado. La IA solo usará datos locales.',
            ),
            backgroundColor: value ? AppTheme.successColor : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error actualizando consentimiento ML: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando consentimiento: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
            _buildHeader(),
            const SizedBox(height: 24),
            // Configuración de precios
            _buildConfiguracionPrecios(),
            const SizedBox(height: 24),
            // Configuración de tema
            _buildConfiguracionTema(),
            const SizedBox(height: 24),
            // Configuración de notificaciones
            _buildConfiguracionNotificaciones(),
            const SizedBox(height: 24),
            // Configuración de IA y Privacidad
            _buildConfiguracionIA(),
            const SizedBox(height: 24),
            // Configuración avanzada
            _buildConfiguracionAvanzada(),
            const SizedBox(height: 24),
            // Botones de acción
            _buildBotonesAccion(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Configuración',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Personaliza tu experiencia y ajusta las preferencias',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botón guardar
          WindowsButton(
            text: 'Guardar',
            type: ButtonType.primary,
            onPressed: _guardarConfiguracion,
            icon: Icons.save,
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionPrecios() {
    return _buildConfiguracionCard(
      'Configuración de Precios',
      Icons.attach_money,
      [
        _buildSliderConfig(
          'Margen de Ganancia por Defecto',
          _margenDefecto,
          0.0,
          200.0,
          '%',
          (value) => setState(() => _margenDefecto = value),
        ),
        const SizedBox(height: 20),
        _buildSliderConfig(
          'IVA',
          _iva,
          0.0,
          50.0,
          '%',
          (value) => setState(() => _iva = value),
        ),
        const SizedBox(height: 20),
        _buildDropdownConfig(
          'Moneda',
          _moneda,
          _monedas,
          (value) => setState(() => _moneda = value!),
        ),
      ],
    );
  }

  Widget _buildConfiguracionTema() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return _buildConfiguracionCard(
          'Apariencia',
          Icons.palette,
          [
            _buildDropdownConfig(
              'Tema',
              themeService.themeName,
              _temas,
              (value) => themeService.setTheme(value!),
            ),
            const SizedBox(height: 20),
            _buildTemaPreview(themeService.themeName),
          ],
        );
      },
    );
  }

  Widget _buildConfiguracionNotificaciones() {
    return _buildConfiguracionCard(
      'Notificaciones',
      Icons.notifications,
      [
        _buildSwitchConfig(
          'Notificaciones de Stock Bajo',
          _notificacionesStock,
          (value) => setState(() => _notificacionesStock = value),
          'Recibe alertas cuando el stock esté por debajo del mínimo',
        ),
        const SizedBox(height: 16),
        _buildNumberConfig(
          'Nivel Mínimo de Stock',
          _stockMinimo,
          (value) => setState(() => _stockMinimo = value),
          'Cantidad mínima de productos antes de generar alertas',
          1,
          100,
        ),
        const SizedBox(height: 16),
        _buildSwitchConfig(
          'Notificaciones de Ventas',
          _notificacionesVentas,
          (value) => setState(() => _notificacionesVentas = value),
          'Recibe notificaciones sobre ventas importantes',
        ),
      ],
    );
  }

  Widget _buildConfiguracionIA() {
    return _buildConfiguracionCard(
      'IA y Privacidad',
      Icons.psychology,
      [
        _buildSwitchConfig(
          'Entrenamiento de IA con Datos',
          _mlConsentimiento,
          _toggleMLConsentimiento,
          'Permite que la IA se entrene con tus datos para mejorar las recomendaciones. Los datos se envían de forma anónima y agregada.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          '¿Qué datos se comparten?',
          'Solo se comparten datos agregados y anónimos para entrenar la IA: patrones de ventas, tendencias de productos y comportamiento de clientes. Nunca se comparten datos personales o identificables.',
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Beneficios',
          'Mejores recomendaciones de productos, predicciones de demanda más precisas y análisis de tendencias más inteligentes.',
        ),
      ],
    );
  }

  Widget _buildConfiguracionAvanzada() {
    return _buildConfiguracionCard(
      'Configuración Avanzada',
      Icons.tune,
      [
        _buildSwitchConfig(
          'Exportación Automática',
          _exportarAutomatico,
          (value) => setState(() => _exportarAutomatico = value),
          'Exporta reportes automáticamente cada semana',
        ),
        const SizedBox(height: 16),
        _buildSwitchConfig(
          'Respaldo Automático',
          _respaldoAutomatico,
          (value) => setState(() => _respaldoAutomatico = value),
          'Crea respaldos automáticos de la base de datos',
        ),
      ],
    );
  }

  Widget _buildConfiguracionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderConfig(
    String label,
    double value,
    double min,
    double max,
    String suffix,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$suffix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.2),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 1).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownConfig(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchConfig(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    String subtitle,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryColor,
          activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildTemaPreview(String temaActual) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vista Previa del Tema',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTemaOption('Claro', 'light_mode', temaActual == 'Claro'),
              const SizedBox(width: 12),
              _buildTemaOption('Oscuro', 'dark_mode', temaActual == 'Oscuro'),
              const SizedBox(width: 12),
              _buildTemaOption('Automático', 'auto_mode', temaActual == 'Automático'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemaOption(String nombre, String icon, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon == 'light_mode' ? Icons.light_mode :
              icon == 'dark_mode' ? Icons.dark_mode : Icons.auto_mode,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesAccion() {
    return Row(
      children: [
        Expanded(
          child: WindowsButton(
            text: 'Restaurar Valores',
            type: ButtonType.secondary,
            onPressed: _restaurarValores,
            icon: Icons.restore,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: WindowsButton(
            text: 'Exportar Configuración',
            type: ButtonType.secondary,
            onPressed: _exportarConfiguracion,
            icon: Icons.download,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: WindowsButton(
            text: 'Importar Configuración',
            type: ButtonType.secondary,
            onPressed: _importarConfiguracion,
            icon: Icons.upload,
          ),
        ),
      ],
    );
  }

  void _restaurarValores() {
    setState(() {
      _margenDefecto = 50.0;
      _iva = 21.0;
      _moneda = 'USD';
      _notificacionesStock = true;
      _notificacionesVentas = false;
      _exportarAutomatico = false;
      _respaldoAutomatico = true;
      _stockMinimo = 5;
    });
  }

  void _exportarConfiguracion() {
    // Implementar exportación de configuración
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcionalidad de exportación en desarrollo'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _importarConfiguracion() {
    // Implementar importación de configuración
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Funcionalidad de importación en desarrollo'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildNumberConfig(
    String title,
    int value,
    ValueChanged<int> onChanged,
    String subtitle,
    int min,
    int max,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 80,
          child: Row(
            children: [
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(
                  Icons.remove,
                  color: value > min ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: value > min 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textSecondary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(
                  Icons.add,
                  color: value < max ? AppTheme.primaryColor : AppTheme.textSecondary,
                  size: 20,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: value < max 
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : AppTheme.textSecondary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
