import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../services/ai/ai_insights_service.dart';
import '../../../services/datos/smart_alerts_service.dart';
import '../../../services/system/logging_service.dart';
import '../../../widgets/ui/ai/simple_recommendations_widget.dart';
import '../../../widgets/ui/ai/ml_customer_analysis_widget.dart';
import '../../../widgets/ui/utility/mini_chart_widget.dart';
import '../../../widgets/ui/utility/progress_indicators_widget.dart';
import '../../../services/export/export_service.dart';

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
  final ExportService _exportService = ExportService();

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
        actionType: 'ver_detalles',
        onAction: () => _showSalesTrendDetails(salesTrend),
      ),
    );
    insights.add(const SizedBox(height: 8));
    
    // Mini gráfico de tendencia
    insights.add(
      MiniChartWidget(
        data: _generateSampleSalesData(),
        color: salesColor,
        title: 'Evolución Semanal',
        showTrend: true,
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
        actionType: 'exportar',
        onAction: () => _exportPopularProducts(popularProducts),
      ),
    );
    insights.add(const SizedBox(height: 8));
    
    // Indicador de progreso de ventas
    insights.add(
      ProgressIndicatorsWidget(
        value: popularProducts.salesCount.toDouble(),
        maxValue: 100.0, // Valor máximo esperado
        label: 'Progreso de Ventas',
        color: popularColor,
        unit: ' ventas',
        showPercentage: true,
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
          actionType: 'aplicar',
          onAction: () => _applyStockRecommendation(recommendation),
        ),
      );
      insights.add(const SizedBox(height: 12));
    }

    return insights;
  }

  // Construir insight directo con botones de acción
  Widget _buildDirectInsightItem(
    IconData icon,
    String title,
    String value,
    String subtitle,
    Color color, {
    String? actionType,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
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
              if (actionType != null && onAction != null)
                _buildActionButton(actionType, onAction, color),
            ],
          ),
          if (actionType != null && onAction != null) ...[
            const SizedBox(height: 8),
            _buildActionDescription(actionType),
          ],
        ],
      ),
    );
  }

  // Botón de acción rápida
  Widget _buildActionButton(String actionType, VoidCallback onAction, Color color) {
    IconData actionIcon;
    String actionText;
    
    switch (actionType.toLowerCase()) {
      case 'ver_detalles':
        actionIcon = Icons.visibility;
        actionText = 'Ver';
        break;
      case 'aplicar':
        actionIcon = Icons.check_circle;
        actionText = 'Aplicar';
        break;
      case 'exportar':
        actionIcon = Icons.download;
        actionText = 'Exportar';
        break;
      case 'configurar':
        actionIcon = Icons.settings;
        actionText = 'Config';
        break;
      default:
        actionIcon = Icons.info;
        actionText = 'Info';
    }

    return GestureDetector(
      onTap: onAction,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(actionIcon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              actionText,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Descripción de la acción
  Widget _buildActionDescription(String actionType) {
    String description;
    
    switch (actionType.toLowerCase()) {
      case 'ver_detalles':
        description = 'Haz clic para ver análisis detallado';
        break;
      case 'aplicar':
        description = 'Haz clic para aplicar esta recomendación';
        break;
      case 'exportar':
        description = 'Haz clic para exportar este insight';
        break;
      case 'configurar':
        description = 'Haz clic para configurar alertas';
        break;
      default:
        description = 'Haz clic para más información';
    }

    return Text(
      description,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 9,
        fontStyle: FontStyle.italic,
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

  // Métodos de acción para insights
  void _showSalesTrendDetails(SalesTrendInsight trend) {
    LoggingService.info('🔍 [AI SIDEBAR] Mostrando detalles de tendencia de ventas');
    LoggingService.info('📊 [AI SIDEBAR] Crecimiento: ${trend.growthPercentage}%, Tendencia: ${trend.trend}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Análisis Detallado de Ventas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Crecimiento', '${trend.growthPercentage.toStringAsFixed(1)}%'),
            _buildDetailRow('Tendencia', trend.trend),
            _buildDetailRow('Mejor Día', trend.bestDay),
            _buildDetailRow('Ventas Semanales', trend.weeklySales.toStringAsFixed(0)),
            _buildDetailRow('Estado', _getTrendStatus(trend.growthPercentage)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              LoggingService.info('📈 [AI SIDEBAR] Exportando análisis de ventas');
              Navigator.pop(context);
              _showExportOptions('tendencia_ventas');
            },
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _exportPopularProducts(PopularProductsInsight products) {
    LoggingService.info('📤 [AI SIDEBAR] Exportando productos populares');
    LoggingService.info('⭐ [AI SIDEBAR] Producto top: ${products.topProduct}, Ventas: ${products.salesCount}');
    
    _showExportOptions('productos_populares');
  }

  void _applyStockRecommendation(StockRecommendationInsight recommendation) {
    LoggingService.info('⚡ [AI SIDEBAR] Aplicando recomendación de stock');
    LoggingService.info('📦 [AI SIDEBAR] Producto: ${recommendation.productName}, Acción: ${recommendation.action}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aplicar Recomendación: ${recommendation.action}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto: ${recommendation.productName}'),
            const SizedBox(height: 8),
            Text('Detalles: ${recommendation.details}'),
            const SizedBox(height: 8),
            Text('Urgencia: ${recommendation.urgency}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              LoggingService.info('✅ [AI SIDEBAR] Recomendación aplicada exitosamente');
              Navigator.pop(context);
              _showSuccessMessage('Recomendación aplicada correctamente');
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(String exportType) {
    LoggingService.info('📋 [AI SIDEBAR] Mostrando opciones de exportación para: $exportType');
    
    // Preparar datos para exportación
    final exportData = _prepareExportData(exportType);
    
    _exportService.showExportDialog(
      context,
      title: 'Exportar $exportType',
      data: exportData,
    );
  }

  // Preparar datos para exportación
  Map<String, dynamic> _prepareExportData(String exportType) {
    if (widget.aiInsights == null) {
      return {'error': 'No hay datos disponibles para exportar'};
    }

    final insights = widget.aiInsights!;
    
    return {
      'exportType': exportType,
      'timestamp': DateTime.now().toIso8601String(),
      'salesTrend': {
        'growthPercentage': insights.salesTrend.growthPercentage,
        'trend': insights.salesTrend.trend,
        'bestDay': insights.salesTrend.bestDay,
        'weeklySales': insights.salesTrend.weeklySales,
      },
      'popularProducts': {
        'topProduct': insights.popularProducts.topProduct,
        'salesCount': insights.popularProducts.salesCount,
        'category': insights.popularProducts.category,
      },
      'stockRecommendations': insights.stockRecommendations.map((rec) => {
        'productName': rec.productName,
        'action': rec.action,
        'details': rec.details,
        'urgency': rec.urgency,
      }).toList(),
    };
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getTrendStatus(double growth) {
    if (growth > 15) return 'Excelente crecimiento';
    if (growth > 5) return 'Buen crecimiento';
    if (growth > -5) return 'Estable';
    return 'Requiere atención';
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }


  // Generar datos de muestra para mini gráficos
  List<double> _generateSampleSalesData() {
    // Generar datos de ventas de los últimos 7 días
    final now = DateTime.now();
    final data = <double>[];
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      // Simular datos con variación aleatoria
      final baseValue = 100.0;
      final variation = (day.weekday - 1) * 20.0; // Más ventas los fines de semana
      final randomFactor = (day.day % 10) * 5.0; // Variación por día del mes
      final value = baseValue + variation + randomFactor;
      data.add(value);
    }
    
    return data;
  }


}
