import 'package:flutter/material.dart';
import 'package:ricitosdebb/config/app_theme.dart';
import 'package:ricitosdebb/models/smart_alert.dart';
import '../services/datos/smart_alerts_service.dart';
import 'package:ricitosdebb/widgets/animated_widgets.dart';

/// Widget unificado que combina alertas inteligentes y recomendaciones de stock
class UnifiedAlertsWidget extends StatefulWidget {
  const UnifiedAlertsWidget({Key? key}) : super(key: key);

  @override
  State<UnifiedAlertsWidget> createState() => _UnifiedAlertsWidgetState();
}

class _UnifiedAlertsWidgetState extends State<UnifiedAlertsWidget> {
  final SmartAlertsService _alertsService = SmartAlertsService();
  
  List<SmartAlert> _alerts = [];
  List<Map<String, dynamic>> _stockRecommendations = [];
  bool _isLoading = true;
  String _selectedTab = 'alertas'; // alertas, stock

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _alertsService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _alertsService.initialize();
      _loadData();
    } catch (e) {
      print('Error inicializando servicios de alertas: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadData() {
    if (!mounted) return;
    
    setState(() {
      _alerts = _alertsService.getAlerts();
      _stockRecommendations = _generateStockRecommendations();
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _generateStockRecommendations() {
    // Generar recomendaciones de stock basadas en datos reales
    // Esto es una implementación simplificada
    return [
      {
        'title': 'Stock Bajo',
        'message': 'Algunos productos tienen stock bajo',
        'priority': 'high',
        'action': 'Revisar inventario',
        'icon': Icons.inventory_2,
        'color': Colors.red,
      },
      {
        'title': 'Productos Populares',
        'message': 'Considera aumentar el stock de productos más vendidos',
        'priority': 'medium',
        'action': 'Analizar ventas',
        'icon': Icons.trending_up,
        'color': Colors.blue,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con pestañas
          _buildHeader(),
          const SizedBox(height: 8),
          
          // Contenido
          if (_isLoading)
            _buildLoadingState()
          else
            _buildContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unreadCount = _alerts.where((a) => !a.isRead).length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.warningColor.withOpacity(0.1), AppTheme.errorColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active, color: AppTheme.warningColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Alertas y Recomendaciones',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (unreadCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Pestañas
          Row(
            children: [
              _buildTab('alertas', 'Alertas', unreadCount > 0 ? '($unreadCount)' : ''),
              const SizedBox(width: 6),
              _buildTab('stock', 'Stock', ''),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String value, String label, String badge) {
    final isSelected = _selectedTab == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.warningColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.warningColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (badge.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                badge,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.errorColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
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

  Widget _buildContent() {
    if (_selectedTab == 'alertas') {
      return _buildAlertsContent();
    } else {
      return _buildStockContent();
    }
  }

  Widget _buildAlertsContent() {
    final activeAlerts = _alerts.where((a) => !a.isDismissed).toList();
    
    if (activeAlerts.isEmpty) {
      return _buildEmptyState('No hay alertas activas', Icons.notifications_none);
    }

    return Column(
      children: activeAlerts
          .map((alert) => _buildAlertCard(alert))
          .toList(),
    );
  }

  Widget _buildStockContent() {
    if (_stockRecommendations.isEmpty) {
      return _buildEmptyState('No hay recomendaciones de stock', Icons.inventory_2);
    }

    return Column(
      children: _stockRecommendations
          .map((recommendation) => _buildStockCard(recommendation))
          .toList(),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
              if (alert.isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CRÍTICA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!alert.isRead) ...[
                Flexible(
                  child: _buildActionButton(
                    'Marcar como leída',
                    Icons.visibility,
                    AppTheme.primaryColor,
                    () => _markAsRead(alert.id),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              if (!alert.isDismissed) ...[
                Flexible(
                  child: _buildActionButton(
                    'Descartar',
                    Icons.cancel,
                    AppTheme.errorColor,
                    () => _dismissAlert(alert.id),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Spacer(),
              Flexible(
                child: Text(
                  alert.timeElapsedDescription,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> recommendation) {
    final priority = recommendation['priority'] as String;
    final title = recommendation['title'] as String;
    final message = recommendation['message'] as String;
    final action = recommendation['action'] as String;
    final icon = recommendation['icon'] as IconData;
    final color = recommendation['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '💡 $action',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
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


  Future<void> _markAsRead(String alertId) async {
    await _alertsService.markAsRead(alertId);
    _loadData();
  }

  Future<void> _dismissAlert(String alertId) async {
    await _alertsService.dismissAlert(alertId);
    _loadData();
  }
}
