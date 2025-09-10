import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/trend_analysis_service.dart';

class AIInsightsWidget extends StatefulWidget {
  const AIInsightsWidget({super.key});

  @override
  State<AIInsightsWidget> createState() => _AIInsightsWidgetState();
}

class _AIInsightsWidgetState extends State<AIInsightsWidget> {
  final TrendAnalysisService _trendService = TrendAnalysisService();
  Map<String, dynamic>? _businessTrends;
  Map<String, dynamic>? _inventoryTrends;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final businessTrends = await _trendService.analyzeBusinessTrends();
      final inventoryTrends = await _trendService.analyzeInventoryTrends();
      
      if (mounted) {
        setState(() {
          _businessTrends = businessTrends;
          _inventoryTrends = inventoryTrends;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          if (_businessTrends?['hasData'] == true) ...[
            _buildBusinessInsightsCompact(),
            const SizedBox(height: 8),
          ],
          if (_inventoryTrends?['hasData'] == true) ...[
            _buildInventoryInsightsCompact(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando datos con IA...'),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const FaIcon(
            FontAwesomeIcons.brain,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Insights de IA',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadInsights,
          icon: const FaIcon(
            FontAwesomeIcons.arrowsRotate,
            color: AppTheme.primaryColor,
            size: 16,
          ),
          tooltip: 'Actualizar análisis',
        ),
      ],
    );
  }

  Widget _buildBusinessInsights() {
    final trends = _businessTrends!;
    final tendencia = trends['tendenciaTemporal'] as String;
    final categoriaTop = trends['categoriaTop'] as String;
    final recomendaciones = trends['recomendaciones'] as List<String>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis del Negocio',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTrendCard(tendencia),
        const SizedBox(height: 8),
        _buildCategoryCard(categoriaTop),
        const SizedBox(height: 8),
        _buildRecommendationsCard(recomendaciones),
      ],
    );
  }

  Widget _buildBusinessInsightsCompact() {
    final trends = _businessTrends!;
    final tendencia = trends['tendenciaTemporal'] as String;
    final categoriaTop = trends['categoriaTop'] as String;

    return Row(
      children: [
        Expanded(
          child: _buildTrendCardCompact(tendencia),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCategoryCardCompact(categoriaTop),
        ),
      ],
    );
  }

  Widget _buildInventoryInsights() {
    final trends = _inventoryTrends!;
    final resumen = trends['resumen'] as Map<String, dynamic>;
    final recomendaciones = trends['recomendaciones'] as List<Map<String, dynamic>>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis de Inventario',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildInventorySummaryCard(resumen),
        const SizedBox(height: 8),
        _buildInventoryRecommendationsCard(recomendaciones),
      ],
    );
  }

  Widget _buildInventoryInsightsCompact() {
    final trends = _inventoryTrends!;
    final resumen = trends['resumen'] as Map<String, dynamic>;
    final stockCritico = resumen['stockCritico'] as int;
    final stockBajo = resumen['stockBajo'] as int;
    final stockAdecuado = resumen['stockAdecuado'] as int;

    return Row(
      children: [
        Expanded(
          child: _buildInventoryMetricCompact('Crítico', stockCritico.toString(), AppTheme.errorColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInventoryMetricCompact('Bajo', stockBajo.toString(), AppTheme.warningColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInventoryMetricCompact('Adecuado', stockAdecuado.toString(), AppTheme.successColor),
        ),
      ],
    );
  }

  Widget _buildTrendCard(String tendencia) {
    Color color;
    IconData icon;
    String text;

    switch (tendencia) {
      case 'increasing':
        color = AppTheme.successColor;
        icon = FontAwesomeIcons.arrowTrendUp;
        text = 'Tendencia al alza';
        break;
      case 'decreasing':
        color = AppTheme.errorColor;
        icon = FontAwesomeIcons.arrowTrendDown;
        text = 'Tendencia a la baja';
        break;
      case 'stable':
      default:
        color = AppTheme.warningColor;
        icon = FontAwesomeIcons.minus;
        text = 'Tendencia estable';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          FaIcon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String categoria) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.trophy, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Text(
            'Categoría top: $categoria',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recomendaciones) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.lightbulb, color: AppTheme.warningColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recomendaciones.take(3).map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(
                  child: Text(
                    rec,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryCard(Map<String, dynamic> resumen) {
    final totalProductos = resumen['totalProductos'] as int;
    final stockCritico = resumen['stockCritico'] as int;
    final stockBajo = resumen['stockBajo'] as int;
    final stockAdecuado = resumen['stockAdecuado'] as int;
    final porcentajeCritico = resumen['porcentajeCritico'] as double;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.boxesStacked, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Resumen de Inventario',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInventoryMetric('Total', totalProductos.toString(), AppTheme.primaryColor),
              ),
              Expanded(
                child: _buildInventoryMetric('Crítico', stockCritico.toString(), AppTheme.errorColor),
              ),
              Expanded(
                child: _buildInventoryMetric('Bajo', stockBajo.toString(), AppTheme.warningColor),
              ),
              Expanded(
                child: _buildInventoryMetric('Adecuado', stockAdecuado.toString(), AppTheme.successColor),
              ),
            ],
          ),
          if (porcentajeCritico > 20) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.exclamationTriangle, color: AppTheme.errorColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${porcentajeCritico.toStringAsFixed(1)}% de productos con stock crítico',
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryRecommendationsCard(List<Map<String, dynamic>> recomendaciones) {
    final recomendacionesCriticas = recomendaciones.where((r) => r['prioridad'] == 'alta').take(3).toList();
    
    if (recomendacionesCriticas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            FaIcon(FontAwesomeIcons.checkCircle, color: AppTheme.successColor, size: 16),
            SizedBox(width: 8),
            Text(
              'Inventario en buen estado',
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.exclamationTriangle, color: AppTheme.errorColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Acciones Requeridas',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recomendacionesCriticas.map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec['nombre'] as String,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rec['recomendacion'] as String,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (rec['cantidadRecomendada'] > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Cantidad recomendada: ${rec['cantidadRecomendada']}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTrendCardCompact(String tendencia) {
    Color color;
    IconData icon;
    String text;

    switch (tendencia) {
      case 'increasing':
        color = AppTheme.successColor;
        icon = FontAwesomeIcons.arrowTrendUp;
        text = 'Alza';
        break;
      case 'decreasing':
        color = AppTheme.errorColor;
        icon = FontAwesomeIcons.arrowTrendDown;
        text = 'Baja';
        break;
      case 'stable':
      default:
        color = AppTheme.warningColor;
        icon = FontAwesomeIcons.minus;
        text = 'Estable';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCardCompact(String categoria) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.trophy, color: AppTheme.primaryColor, size: 12),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              categoria,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMetricCompact(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
