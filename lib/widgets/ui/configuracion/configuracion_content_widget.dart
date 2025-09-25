import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ui/configuracion/configuracion_state_service.dart';
import '../../../services/ui/configuracion/configuracion_logic_service.dart';
import '../../../services/ui/configuracion/configuracion_navigation_service.dart';
import 'configuracion_stats_cards.dart';

/// Widget que contiene el contenido principal de la pantalla de configuración
class ConfiguracionContentWidget extends StatelessWidget {
  const ConfiguracionContentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfiguracionStateService>(
      builder: (context, stateService, child) {
        final logicService = Provider.of<ConfiguracionLogicService>(context, listen: false);
        final navigationService = Provider.of<ConfiguracionNavigationService>(context, listen: false);
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Estadísticas principales
              const ConfiguracionStatsCards(),
              
              const SizedBox(height: 24),
              
              // Secciones simplificadas
              _buildPreciosSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildTemaSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildNotificacionesSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildIASection(context, stateService, logicService, navigationService),
              
              const SizedBox(height: 24),
              
              _buildAvanzadaSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildConectividadSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildBackupSection(context, stateService),
              
              const SizedBox(height: 24),
              
              _buildActionButtons(context, logicService, navigationService),
              
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _guardarConfiguracion(
    BuildContext context,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) async {
    final success = await logicService.saveConfiguracion();
    
    if (success) {
      navigationService.showSuccessMessage(context, 'Configuración guardada exitosamente');
    } else {
      navigationService.showErrorMessage(context, 'Error guardando configuración');
    }
  }

  void _resetearConfiguracion(
    BuildContext context,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) async {
    final confirmed = await navigationService.showResetDialog(context);
    
    if (confirmed) {
      final success = await logicService.resetearConfiguracion();
      
      if (success) {
        navigationService.showSuccessMessage(context, 'Configuración reseteada exitosamente');
      } else {
        navigationService.showErrorMessage(context, 'Error reseteando configuración');
      }
    }
  }

  void _exportarConfiguracion(
    BuildContext context,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) async {
    final confirmed = await navigationService.showExportDialog(context);
    
    if (confirmed) {
      final success = await logicService.exportarConfiguracion();
      
      if (success) {
        navigationService.showSuccessMessage(context, 'Configuración exportada exitosamente');
      } else {
        navigationService.showErrorMessage(context, 'Error exportando configuración');
      }
    }
  }

  void _importarConfiguracion(
    BuildContext context,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) async {
    final config = await navigationService.showImportDialog(context);
    
    if (config != null) {
      final success = await logicService.importarConfiguracion(config);
      
      if (success) {
        navigationService.showSuccessMessage(context, 'Configuración importada exitosamente');
      } else {
        navigationService.showErrorMessage(context, 'Error importando configuración');
      }
    }
  }

  Widget _buildPreciosSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de Precios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Margen por Defecto'),
                    Slider(
                      value: stateService.margenDefecto,
                      min: 0,
                      max: 100,
                      divisions: 100,
                      onChanged: (value) => stateService.updateMargenDefecto(value),
                    ),
                    Text('${stateService.margenDefecto.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IVA'),
                    Slider(
                      value: stateService.iva,
                      min: 0,
                      max: 50,
                      divisions: 50,
                      onChanged: (value) => stateService.updateIVA(value),
                    ),
                    Text('${stateService.iva.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemaSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de Tema',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tema actual: Claro'),
        ],
      ),
    );
  }

  Widget _buildNotificacionesSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de Notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Notificaciones de Stock'),
            subtitle: const Text('Recibir alertas cuando el stock esté bajo'),
            value: stateService.notificacionesStock,
            onChanged: (value) => stateService.updateNotificacionesStock(value),
          ),
          SwitchListTile(
            title: const Text('Notificaciones de Ventas'),
            subtitle: const Text('Recibir alertas de nuevas ventas'),
            value: stateService.notificacionesVentas,
            onChanged: (value) => stateService.updateNotificacionesVentas(value),
          ),
        ],
      ),
    );
  }

  Widget _buildIASection(
    BuildContext context,
    ConfiguracionStateService stateService,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de IA/ML',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Consentimiento ML'),
            subtitle: const Text('Permitir el uso de Machine Learning para mejoras'),
            value: stateService.mlConsentimiento,
            onChanged: (value) async {
              final success = await logicService.toggleMLConsentimiento(value);
              if (success) {
                navigationService.showSuccessMessage(context, 'Consentimiento ML actualizado');
              } else {
                navigationService.showErrorMessage(context, 'Error actualizando consentimiento ML');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvanzadaSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración Avanzada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Exportación Automática'),
            subtitle: const Text('Exportar datos automáticamente'),
            value: stateService.exportarAutomatico,
            onChanged: (value) => stateService.updateExportarAutomatico(value),
          ),
        ],
      ),
    );
  }

  Widget _buildConectividadSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de Conectividad',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Estado de conexión: Conectado'),
        ],
      ),
    );
  }

  Widget _buildBackupSection(BuildContext context, ConfiguracionStateService stateService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Configuración de Backup',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Respaldo Automático'),
            subtitle: const Text('Crear respaldos automáticamente'),
            value: stateService.respaldoAutomatico,
            onChanged: (value) => stateService.updateRespaldoAutomatico(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ConfiguracionLogicService logicService,
    ConfiguracionNavigationService navigationService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Text(
            'Acciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _guardarConfiguracion(context, logicService, navigationService),
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _resetearConfiguracion(context, logicService, navigationService),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Resetear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _exportarConfiguracion(context, logicService, navigationService),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Exportar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _importarConfiguracion(context, logicService, navigationService),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Importar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
