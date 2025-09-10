import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/trend_analysis_service.dart';

class AIRecommendationsWidget extends StatefulWidget {
  const AIRecommendationsWidget({super.key});

  @override
  State<AIRecommendationsWidget> createState() => _AIRecommendationsWidgetState();
}

class _AIRecommendationsWidgetState extends State<AIRecommendationsWidget> {
  final TrendAnalysisService _trendService = TrendAnalysisService();
  Map<String, dynamic>? _inventoryTrends;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final inventoryTrends = await _trendService.analyzeInventoryTrends();
      
      if (mounted) {
        setState(() {
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

    if (_inventoryTrends?['hasData'] != true) {
      return _buildNoDataState();
    }

    final recomendaciones = _inventoryTrends!['recomendaciones'] as List<Map<String, dynamic>>;
    final resumen = _inventoryTrends!['resumen'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildSummaryCard(resumen),
          const SizedBox(height: 12),
          _buildRecommendationsList(recomendaciones),
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
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analizando inventario con IA...'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: const Center(
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.chartLine,
              size: 32,
              color: AppTheme.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'No hay datos suficientes para análisis',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
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
          'Recomendaciones de IA',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: _loadRecommendations,
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

  Widget _buildSummaryCard(Map<String, dynamic> resumen) {
    final totalProductos = resumen['totalProductos'] as int;
    final stockCritico = resumen['stockCritico'] as int;
    final stockBajo = resumen['stockBajo'] as int;
    final stockAdecuado = resumen['stockAdecuado'] as int;
    final porcentajeCritico = resumen['porcentajeCritico'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
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
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.chartPie, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 8),
              Text(
                'Resumen del Inventario',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric('Total', totalProductos.toString(), AppTheme.primaryColor),
              ),
              Expanded(
                child: _buildSummaryMetric('Crítico', stockCritico.toString(), AppTheme.errorColor),
              ),
              Expanded(
                child: _buildSummaryMetric('Bajo', stockBajo.toString(), AppTheme.warningColor),
              ),
              Expanded(
                child: _buildSummaryMetric('Adecuado', stockAdecuado.toString(), AppTheme.successColor),
              ),
            ],
          ),
          if (porcentajeCritico > 20) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.exclamationTriangle, color: AppTheme.errorColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡Atención! ${porcentajeCritico.toStringAsFixed(1)}% de productos tienen stock crítico',
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

  Widget _buildSummaryMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsList(List<Map<String, dynamic>> recomendaciones) {
    if (recomendaciones.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.successColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            FaIcon(FontAwesomeIcons.checkCircle, color: AppTheme.successColor, size: 20),
            SizedBox(width: 12),
            Text(
              '¡Excelente! Tu inventario está en perfecto estado',
              style: TextStyle(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: recomendaciones.take(5).map((rec) => _buildRecommendationCard(rec)).toList(),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recomendacion) {
    final nombre = recomendacion['nombre'] as String;
    final categoria = recomendacion['categoria'] as String;
    final stockActual = recomendacion['stockActual'] as int;
    final promedioDiario = recomendacion['promedioDiario'] as double;
    final diasRestantes = recomendacion['diasRestantes'] as double;
    final recomendacionText = recomendacion['recomendacion'] as String;
    final prioridad = recomendacion['prioridad'] as String;
    final cantidadRecomendada = recomendacion['cantidadRecomendada'] as int;

    Color priorityColor;
    IconData priorityIcon;

    switch (prioridad) {
      case 'alta':
        priorityColor = AppTheme.errorColor;
        priorityIcon = FontAwesomeIcons.exclamationTriangle;
        break;
      case 'media':
        priorityColor = AppTheme.warningColor;
        priorityIcon = FontAwesomeIcons.exclamation;
        break;
      case 'baja':
      default:
        priorityColor = AppTheme.successColor;
        priorityIcon = FontAwesomeIcons.checkCircle;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(priorityIcon, color: priorityColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  prioridad.toUpperCase(),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(categoria, AppTheme.primaryColor),
              const SizedBox(width: 8),
              _buildInfoChip('Stock: $stockActual', AppTheme.textSecondary),
              const SizedBox(width: 8),
              _buildInfoChip('Promedio: ${promedioDiario.toStringAsFixed(1)}/día', AppTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recomendacionText,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          if (cantidadRecomendada > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.lightbulb, color: AppTheme.primaryColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Cantidad recomendada: $cantidadRecomendada unidades',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (diasRestantes < 7) ...[
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
                  const FaIcon(FontAwesomeIcons.clock, color: AppTheme.errorColor, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    'Solo quedan ${diasRestantes.toStringAsFixed(1)} días de stock',
                    style: const TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
