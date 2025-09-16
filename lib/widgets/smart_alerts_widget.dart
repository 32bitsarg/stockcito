import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/models/smart_alert.dart';
import '../services/datos/smart_alerts_service.dart';
import 'package:stockcito/widgets/animated_widgets.dart';

/// Widget que muestra alertas inteligentes del sistema
class SmartAlertsWidget extends StatefulWidget {
  const SmartAlertsWidget({Key? key}) : super(key: key);

  @override
  State<SmartAlertsWidget> createState() => _SmartAlertsWidgetState();
}

class _SmartAlertsWidgetState extends State<SmartAlertsWidget> {
  final SmartAlertsService _alertsService = SmartAlertsService();
  List<SmartAlert> _alerts = [];
  bool _isLoading = true;
  String _selectedFilter = 'todas'; // todas, no_leidas, criticas, descartadas

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _alertsService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      await _alertsService.initialize();
      _loadAlerts();
    } catch (e) {
      print('Error inicializando servicio de alertas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadAlerts() {
    if (!mounted) return;
    
    setState(() {
      _alerts = _alertsService.getAlerts();
      _isLoading = false;
    });
  }

  List<SmartAlert> get _filteredAlerts {
    switch (_selectedFilter) {
      case 'no_leidas':
        return _alerts.where((a) => !a.isRead).toList();
      case 'criticas':
        return _alerts.where((a) => a.isCritical).toList();
      case 'descartadas':
        return _alerts.where((a) => a.isDismissed).toList();
      default:
        return _alerts.where((a) => !a.isDismissed).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con filtros
          _buildHeader(),
          const SizedBox(height: 12),
          
          // Contenido
          if (_isLoading)
            _buildLoadingState()
          else if (_filteredAlerts.isEmpty)
            _buildEmptyState()
          else
            _buildAlertsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _alerts.where((a) => !a.isRead).length;
    final criticalCount = _alerts.where((a) => a.isCritical).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.warningColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Alertas Inteligentes',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '${_filteredAlerts.length}',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('todas', 'Todas'),
                const SizedBox(width: 8),
                if (unreadCount > 0) ...[
                  _buildFilterChip('no_leidas', 'No leídas ($unreadCount)'),
                  const SizedBox(width: 8),
                ],
                if (criticalCount > 0) ...[
                  _buildFilterChip('criticas', 'Críticas ($criticalCount)'),
                  const SizedBox(width: 8),
                ],
                _buildFilterChip('descartadas', 'Descartadas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warningColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.warningColor : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 60,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none,
            color: AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay alertas',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El sistema monitorea automáticamente tu negocio',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      children: _filteredAlerts
          .map((alert) => _buildAlertCard(alert))
          .toList(),
    );
  }

  Widget _buildAlertCard(SmartAlert alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alert.typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de la alerta
          Row(
            children: [
              Icon(alert.typeIcon, color: alert.typeColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: alert.typeColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              // Prioridad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: alert.priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(alert.priorityIcon, color: alert.priorityColor, size: 10),
                    const SizedBox(width: 2),
                    Text(
                      _getPriorityText(alert.priority),
                      style: TextStyle(
                        color: alert.priorityColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Mensaje
          Text(
            alert.message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          
          if (alert.productName != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Producto: ${alert.productName}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Botones de acción
          _buildActionButtons(alert),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SmartAlert alert) {
    return Row(
      children: [
        if (!alert.isRead) ...[
          _buildActionButton(
            'Marcar como leída',
            Icons.visibility,
            AppTheme.primaryColor,
            () => _markAsRead(alert.id),
          ),
          const SizedBox(width: 8),
        ],
        if (!alert.isDismissed) ...[
          _buildActionButton(
            'Descartar',
            Icons.cancel,
            AppTheme.errorColor,
            () => _dismissAlert(alert.id),
          ),
          const SizedBox(width: 8),
        ],
        if (alert.canBeDeleted) ...[
          _buildActionButton(
            'Eliminar',
            Icons.delete,
            AppTheme.textSecondary,
            () => _deleteAlert(alert.id),
          ),
        ],
        const Spacer(),
        Text(
          alert.timeElapsedDescription,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPriorityText(AlertPriority priority) {
    switch (priority) {
      case AlertPriority.critica:
        return 'Crítica';
      case AlertPriority.alta:
        return 'Alta';
      case AlertPriority.media:
        return 'Media';
      case AlertPriority.baja:
        return 'Baja';
    }
  }

  Future<void> _markAsRead(String alertId) async {
    await _alertsService.markAsRead(alertId);
    _loadAlerts();
  }

  Future<void> _dismissAlert(String alertId) async {
    await _alertsService.dismissAlert(alertId);
    _loadAlerts();
  }

  Future<void> _deleteAlert(String alertId) async {
    await _alertsService.deleteAlert(alertId);
    _loadAlerts();
  }
}

