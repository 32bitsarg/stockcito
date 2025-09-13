import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../services/ai/ai_insights_service.dart';
import '../../../services/datos/smart_alerts_service.dart';
import '../../../widgets/simple_recommendations_widget.dart';
import '../../../widgets/ml_customer_analysis_widget.dart';

class DashboardAISidebar extends StatefulWidget {
  final AIInsights? aiInsights;
  final bool isLoadingInsights;

  const DashboardAISidebar({
    super.key,
    required this.aiInsights,
    required this.isLoadingInsights,
  });

  @override
  State<DashboardAISidebar> createState() => _DashboardAISidebarState();
}

class _DashboardAISidebarState extends State<DashboardAISidebar> {
  String _selectedTab = 'insights'; // insights, recomendaciones, clientes, alertas
  final SmartAlertsService _alertsService = SmartAlertsService();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pestañas de IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildAITab('Insights', 'insights'),
                const SizedBox(width: 8),
                _buildAITab('Recomendaciones', 'recomendaciones'),
                const SizedBox(width: 8),
                _buildAITab('Clientes', 'clientes'),
                const SizedBox(width: 8),
                _buildAITab('Alertas', 'alertas'),
              ],
            ),
          ),
          
          // Contenido de IA - Usar todo el espacio disponible con scroll mejorado
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  // Construir insights generados por IA
  List<Widget> _buildAIInsights() {
    final List<Widget> insights = [];
    
    if (widget.aiInsights == null) return insights;

    // Tendencia de ventas
    final salesTrend = widget.aiInsights!.salesTrend;
    final salesColor = _getColorFromString(salesTrend.color);
    insights.add(
      _buildDirectInsightItem(
        FontAwesomeIcons.chartLine,
        'Tendencia de Ventas',
        '${salesTrend.growthPercentage.toStringAsFixed(1)}% ${salesTrend.trend.toLowerCase()}',
        '${salesTrend.bestDay}: mejor día de ventas',
        salesColor,
      ),
    );
    insights.add(const SizedBox(height: 12));

    // Productos populares
    final popularProducts = widget.aiInsights!.popularProducts;
    final popularColor = _getColorFromString(popularProducts.color);
    insights.add(
      _buildDirectInsightItem(
        FontAwesomeIcons.star,
        'Productos Populares',
        popularProducts.topProduct,
        '${popularProducts.salesCount} ventas esta semana',
        popularColor,
      ),
    );
    insights.add(const SizedBox(height: 12));

    // Recomendaciones de stock
    for (final recommendation in widget.aiInsights!.stockRecommendations) {
      final stockColor = _getColorFromString(recommendation.color);
      final icon = _getIconFromAction(recommendation.action);
      
      insights.add(
        _buildDirectInsightItem(
          icon,
          recommendation.productName,
          recommendation.details,
          '💡 ${recommendation.action}',
          stockColor,
        ),
      );
      insights.add(const SizedBox(height: 12));
    }

    return insights;
  }

  // Construir insight directo
  Widget _buildDirectInsightItem(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget de carga
  Widget _buildLoadingInsight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Generando insights de IA...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Widget sin datos
  Widget _buildNoDataInsight() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            FontAwesomeIcons.chartLine,
            color: Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay datos suficientes para generar insights',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Construir pestaña de IA
  Widget _buildAITab(String label, String tabId) {
    final isSelected = _selectedTab == tabId;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // Construir contenido según la pestaña seleccionada
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 'insights':
        return _buildInsightsContent();
      case 'recomendaciones':
        return _buildRecommendationsContent();
      case 'clientes':
        return _buildClientsContent();
      case 'alertas':
        return _buildAlertsContent();
      default:
        return _buildInsightsContent();
    }
  }

  // Contenido de Insights
  Widget _buildInsightsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título principal
        const Text(
          'Análisis de IA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtítulo explicativo
        Text(
          'Insights automáticos basados en tus datos',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Insights principales - Generados por IA
        if (widget.isLoadingInsights)
          _buildLoadingInsight()
        else if (widget.aiInsights != null)
          ..._buildAIInsights()
        else
          _buildNoDataInsight(),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // Contenido de Recomendaciones
  Widget _buildRecommendationsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recomendaciones de IA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtítulo explicativo
        Text(
          'Acciones sugeridas basadas en análisis inteligente',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Widget simplificado de recomendaciones con altura flexible
        Expanded(
          child: const SimpleRecommendationsWidget(),
        ),
      ],
    );
  }

  // Contenido de Clientes
  Widget _buildClientsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis de Clientes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Análisis de clientes con ML
        const MLCustomerAnalysisWidget(),
        
        const SizedBox(height: 20),
      ],
    );
  }

  // Contenido de Alertas
  Widget _buildAlertsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertas Inteligentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        
        // Subtítulo explicativo
        Text(
          'Notificaciones críticas que requieren atención',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        
        // Lista de alertas con altura flexible
        Expanded(
          child: Builder(
            builder: (context) {
              try {
                final alerts = _alertsService.getUnreadAlerts();
                if (alerts.isEmpty) {
                  return _buildEmptyAlerts();
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertCard(alerts[index]);
                  },
                );
              } catch (e) {
                return _buildErrorAlerts();
              }
            },
          ),
        ),
      ],
    );
  }


  Widget _buildErrorAlerts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          'Error cargando alertas',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyAlerts() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          'No hay alertas pendientes',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(alert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alert.typeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: alert.typeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                alert.typeIcon,
                color: alert.typeColor,
                size: 16,
              ),
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
              GestureDetector(
                onTap: () => _deleteAlert(alert),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 12,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                alert.timeElapsedDescription,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              GestureDetector(
                onTap: () => _markAlertAsRead(alert),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Marcar como leída',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

  Future<void> _markAlertAsRead(alert) async {
    await _alertsService.markAsRead(alert.id);
    setState(() {}); // Refrescar la UI
  }

  Future<void> _deleteAlert(alert) async {
    await _alertsService.deleteAlert(alert.id);
    setState(() {}); // Refrescar la UI
  }

  // Obtener color desde string
  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      default:
        return AppTheme.primaryColor;
    }
  }

  // Obtener icono desde acción
  IconData _getIconFromAction(String action) {
    if (action.toLowerCase().contains('stock') || action.toLowerCase().contains('inventario')) {
      return FontAwesomeIcons.boxesStacked;
    } else if (action.toLowerCase().contains('precio') || action.toLowerCase().contains('costo')) {
      return FontAwesomeIcons.dollarSign;
    } else if (action.toLowerCase().contains('venta') || action.toLowerCase().contains('promocion')) {
      return FontAwesomeIcons.chartLine;
    } else if (action.toLowerCase().contains('cliente') || action.toLowerCase().contains('marketing')) {
      return FontAwesomeIcons.users;
    } else {
      return FontAwesomeIcons.lightbulb;
    }
  }
}
