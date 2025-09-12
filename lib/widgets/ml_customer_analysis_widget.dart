import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ricitosdebb/services/advanced_ml_service.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/config/app_theme.dart';

class MLCustomerAnalysisWidget extends StatefulWidget {
  const MLCustomerAnalysisWidget({super.key});

  @override
  State<MLCustomerAnalysisWidget> createState() => _MLCustomerAnalysisWidgetState();
}

class _MLCustomerAnalysisWidgetState extends State<MLCustomerAnalysisWidget> {
  final AdvancedMLService _mlService = AdvancedMLService();
  List<CustomerSegment> _segments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerAnalysis();
  }

  Future<void> _loadCustomerAnalysis() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final segments = await _mlService.segmentCustomers();
      if (mounted) {
        setState(() {
          _segments = segments;
          _isLoading = false;
        });
      }
    } catch (e) {
      LoggingService.error('Error cargando análisis de clientes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                FontAwesomeIcons.users,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Análisis de Clientes (ML)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          if (_isLoading)
            _buildLoadingState()
          else if (_segments.isNotEmpty)
            _buildAnalysisContent()
          else
            _buildNoDataState(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Analizando patrones de clientes...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.exclamationTriangle,
            size: 16,
            color: Colors.grey.shade500,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No hay datos suficientes para análisis de clientes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisContent() {
    if (_segments.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Resumen general
        _buildSummaryCard(),
        const SizedBox(height: 12),

        // Segmentos de clientes
        _buildSegmentsSection(),
        const SizedBox(height: 12),

        // Insights
        _buildInsightsSection(),
        const SizedBox(height: 12),

        // Recomendaciones
        _buildRecommendationsSection(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.chartPie,
            size: 20,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_segments.fold(0, (sum, segment) => sum + segment.customers.length)} Clientes Analizados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_segments.length} segmentos identificados con ML',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Segmentos de Clientes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...(_segments.map((segment) => _buildSegmentCard(segment))),
      ],
    );
  }

  Widget _buildSegmentCard(CustomerSegment segment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              Expanded(
                child: Text(
                  segment.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSegmentColor(segment.name).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${segment.customers.length} clientes',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getSegmentColor(segment.name),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                FontAwesomeIcons.dollarSign,
                size: 12,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                '${segment.customers.length} clientes',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                FontAwesomeIcons.users,
                size: 12,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                segment.characteristics.join(', '),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights Clave',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildInsightItem('Segmentación automática con K-means clustering'),
        _buildInsightItem('Análisis de comportamiento de clientes'),
        _buildInsightItem('Modelo ML entrenado con datos históricos'),
      ],
    );
  }

  Widget _buildInsightItem(String insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.lightbulb,
            size: 12,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recomendaciones',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        _buildRecommendationItem('Personalizar ofertas por segmento de cliente'),
        _buildRecommendationItem('Crear estrategias específicas para cada grupo'),
        _buildRecommendationItem('Monitorear cambios en comportamiento de clientes'),
      ],
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.checkCircle,
            size: 12,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSegmentColor(String segmentName) {
    switch (segmentName.toLowerCase()) {
      case 'clientes vip':
        return Colors.purple;
      case 'clientes regulares':
        return Colors.blue;
      case 'clientes nuevos':
        return Colors.orange;
      default:
        return AppTheme.primaryColor;
    }
  }
}
