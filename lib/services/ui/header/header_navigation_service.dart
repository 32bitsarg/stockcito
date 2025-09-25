import 'package:flutter/material.dart';
import '../../system/logging_service.dart';

/// Modelo para las acciones de navegación del header
class HeaderNavigationAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? badge;

  HeaderNavigationAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
    this.badge,
  });
}

/// Servicio para manejar la navegación y acciones del header
class HeaderNavigationService {
  static final HeaderNavigationService _instance = HeaderNavigationService._internal();
  factory HeaderNavigationService() => _instance;
  HeaderNavigationService._internal();

  /// Obtiene las acciones disponibles para una pantalla específica
  List<HeaderNavigationAction> getActionsForScreen(
    BuildContext context,
    String screenContext,
  ) {
    try {
      switch (screenContext.toLowerCase()) {
        case 'inventario':
          return _getInventarioActions(context);
        case 'ventas':
          return _getVentasActions(context);
        case 'clientes':
          return _getClientesActions(context);
        case 'reportes':
          return _getReportesActions(context);
        case 'calculo_precios':
          return _getCalculoPreciosActions(context);
        case 'configuracion':
          return _getConfiguracionActions(context);
        default:
          return _getDefaultActions(context);
      }
    } catch (e) {
      LoggingService.error('Error obteniendo acciones para pantalla: $e');
      return _getDefaultActions(context);
    }
  }

  /// Acciones para la pantalla de inventario
  List<HeaderNavigationAction> _getInventarioActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'sync',
        label: 'Sincronizar',
        icon: Icons.sync,
        color: Colors.blue,
        onTap: () => _handleSync(context),
      ),
      HeaderNavigationAction(
        id: 'export',
        label: 'Exportar',
        icon: Icons.download,
        color: Colors.green,
        onTap: () => _handleExport(context),
      ),
      HeaderNavigationAction(
        id: 'notifications',
        label: 'Notificaciones',
        icon: Icons.notifications,
        color: Colors.orange,
        onTap: () => _handleNotifications(context),
        badge: '3', // Ejemplo de badge
      ),
    ];
  }

  /// Acciones para la pantalla de ventas
  List<HeaderNavigationAction> _getVentasActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'new_sale',
        label: 'Nueva Venta',
        icon: Icons.add,
        color: Colors.green,
        onTap: () => _handleNewSale(context),
      ),
      HeaderNavigationAction(
        id: 'sync',
        label: 'Sincronizar',
        icon: Icons.sync,
        color: Colors.blue,
        onTap: () => _handleSync(context),
      ),
      HeaderNavigationAction(
        id: 'export',
        label: 'Exportar',
        icon: Icons.download,
        color: Colors.purple,
        onTap: () => _handleExport(context),
      ),
    ];
  }

  /// Acciones para la pantalla de clientes
  List<HeaderNavigationAction> _getClientesActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'new_client',
        label: 'Nuevo Cliente',
        icon: Icons.person_add,
        color: Colors.green,
        onTap: () => _handleNewClient(context),
      ),
      HeaderNavigationAction(
        id: 'sync',
        label: 'Sincronizar',
        icon: Icons.sync,
        color: Colors.blue,
        onTap: () => _handleSync(context),
      ),
    ];
  }

  /// Acciones para la pantalla de reportes
  List<HeaderNavigationAction> _getReportesActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'export_pdf',
        label: 'PDF',
        icon: Icons.picture_as_pdf,
        color: Colors.red,
        onTap: () => _handleExportPDF(context),
      ),
      HeaderNavigationAction(
        id: 'export_csv',
        label: 'CSV',
        icon: Icons.table_chart,
        color: Colors.green,
        onTap: () => _handleExportCSV(context),
      ),
      HeaderNavigationAction(
        id: 'export_json',
        label: 'JSON',
        icon: Icons.code,
        color: Colors.blue,
        onTap: () => _handleExportJSON(context),
      ),
    ];
  }

  /// Acciones para la pantalla de cálculo de precios
  List<HeaderNavigationAction> _getCalculoPreciosActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'save_template',
        label: 'Guardar Plantilla',
        icon: Icons.save,
        color: Colors.green,
        onTap: () => _handleSaveTemplate(context),
      ),
      HeaderNavigationAction(
        id: 'load_template',
        label: 'Cargar Plantilla',
        icon: Icons.folder_open,
        color: Colors.blue,
        onTap: () => _handleLoadTemplate(context),
      ),
    ];
  }

  /// Acciones para la pantalla de configuración
  List<HeaderNavigationAction> _getConfiguracionActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'backup',
        label: 'Respaldo',
        icon: Icons.backup,
        color: Colors.orange,
        onTap: () => _handleBackup(context),
      ),
      HeaderNavigationAction(
        id: 'restore',
        label: 'Restaurar',
        icon: Icons.restore,
        color: Colors.blue,
        onTap: () => _handleRestore(context),
      ),
      HeaderNavigationAction(
        id: 'export_config',
        label: 'Exportar Config',
        icon: Icons.download,
        color: Colors.green,
        onTap: () => _handleExportConfig(context),
      ),
    ];
  }

  /// Acciones por defecto
  List<HeaderNavigationAction> _getDefaultActions(BuildContext context) {
    return [
      HeaderNavigationAction(
        id: 'sync',
        label: 'Sincronizar',
        icon: Icons.sync,
        color: Colors.blue,
        onTap: () => _handleSync(context),
      ),
      HeaderNavigationAction(
        id: 'notifications',
        label: 'Notificaciones',
        icon: Icons.notifications,
        color: Colors.orange,
        onTap: () => _handleNotifications(context),
      ),
    ];
  }

  /// Maneja la sincronización
  void _handleSync(BuildContext context) {
    LoggingService.info('Sincronización iniciada desde header');
    // TODO: Implementar lógica de sincronización
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sincronización iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja la exportación
  void _handleExport(BuildContext context) {
    LoggingService.info('Exportación iniciada desde header');
    // TODO: Implementar lógica de exportación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja las notificaciones
  void _handleNotifications(BuildContext context) {
    LoggingService.info('Notificaciones abiertas desde header');
    // TODO: Implementar lógica de notificaciones
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificaciones abiertas'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja nueva venta
  void _handleNewSale(BuildContext context) {
    LoggingService.info('Nueva venta iniciada desde header');
    // TODO: Implementar navegación a nueva venta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nueva venta iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja nuevo cliente
  void _handleNewClient(BuildContext context) {
    LoggingService.info('Nuevo cliente iniciado desde header');
    // TODO: Implementar navegación a nuevo cliente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nuevo cliente iniciado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja exportación PDF
  void _handleExportPDF(BuildContext context) {
    LoggingService.info('Exportación PDF iniciada desde header');
    // TODO: Implementar lógica de exportación PDF
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación PDF iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja exportación CSV
  void _handleExportCSV(BuildContext context) {
    LoggingService.info('Exportación CSV iniciada desde header');
    // TODO: Implementar lógica de exportación CSV
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación CSV iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja exportación JSON
  void _handleExportJSON(BuildContext context) {
    LoggingService.info('Exportación JSON iniciada desde header');
    // TODO: Implementar lógica de exportación JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación JSON iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja guardar plantilla
  void _handleSaveTemplate(BuildContext context) {
    LoggingService.info('Guardar plantilla iniciado desde header');
    // TODO: Implementar lógica de guardar plantilla
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantilla guardada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja cargar plantilla
  void _handleLoadTemplate(BuildContext context) {
    LoggingService.info('Cargar plantilla iniciado desde header');
    // TODO: Implementar lógica de cargar plantilla
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plantilla cargada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja respaldo
  void _handleBackup(BuildContext context) {
    LoggingService.info('Respaldo iniciado desde header');
    // TODO: Implementar lógica de respaldo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Respaldo iniciado'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja restaurar
  void _handleRestore(BuildContext context) {
    LoggingService.info('Restaurar iniciado desde header');
    // TODO: Implementar lógica de restaurar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restauración iniciada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Maneja exportar configuración
  void _handleExportConfig(BuildContext context) {
    LoggingService.info('Exportar configuración iniciado desde header');
    // TODO: Implementar lógica de exportar configuración
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración exportada'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
