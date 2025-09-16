import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/models/ai_recommendation.dart';
import 'package:stockcito/services/ml/local_recommendations_service.dart';
import 'package:stockcito/services/ai/ai_insights_service.dart';
import 'package:stockcito/widgets/animated_widgets.dart';

/// Widget unificado que combina recomendaciones de IA y análisis avanzado
class UnifiedAIWidget extends StatefulWidget {
  const UnifiedAIWidget({Key? key}) : super(key: key);

  @override
  State<UnifiedAIWidget> createState() => _UnifiedAIWidgetState();
}

class _UnifiedAIWidgetState extends State<UnifiedAIWidget> {
  final LocalRecommendationsService _recommendationsService = LocalRecommendationsService();
  final AIInsightsService _insightsService = AIInsightsService();
  
  List<AIRecommendation> _recommendations = [];
  AIInsights? _aiInsights;
  bool _isLoading = true;
  String _selectedTab = 'recomendaciones'; // recomendaciones, analisis

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  @override
  void dispose() {
    _recommendationsService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      await _recommendationsService.initialize();
      await _loadInsights();
      _loadRecommendations();
    } catch (e) {
      print('Error inicializando servicios de IA: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadInsights() async {
    try {
      final insights = await _insightsService.generateInsights();
      if (mounted) {
        setState(() {
          _aiInsights = insights;
        });
      }
    } catch (e) {
      print('Error cargando insights: $e');
    }
  }

  void _loadRecommendations() {
    if (!mounted) return;
    
    try {
      setState(() {
        _recommendations = _recommendationsService.getRecommendations();
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando recomendaciones: $e');
      if (mounted) {
        setState(() {
          _recommendations = [];
          _isLoading = false;
        });
      }
    }
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
    final activeRecommendations = _recommendations
        .where((r) => r.status == RecommendationStatus.nueva || 
                     r.status == RecommendationStatus.vista)
        .length;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.accentColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.primaryColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'IA y Análisis Avanzado',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${_getTotalCount()}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Pestañas
          Row(
            children: [
              _buildTab('recomendaciones', 'Recomendaciones', activeRecommendations > 0 ? '($activeRecommendations)' : ''),
              const SizedBox(width: 6),
              _buildTab('analisis', 'Análisis', ''),
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
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
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
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
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
    if (_selectedTab == 'recomendaciones') {
      return _buildRecommendationsContent();
    } else {
      return _buildAnalysisContent();
    }
  }

  Widget _buildRecommendationsContent() {
    final activeRecommendations = _recommendations
        .where((r) => r.status == RecommendationStatus.nueva || 
                     r.status == RecommendationStatus.vista)
        .toList();
    
    if (activeRecommendations.isEmpty) {
      return _buildEmptyState('No hay recomendaciones activas', Icons.psychology_outlined);
    }

    return Column(
      children: activeRecommendations
          .map((recommendation) => _buildRecommendationCard(recommendation))
          .toList(),
    );
  }

  Widget _buildAnalysisContent() {
    if (_aiInsights == null) {
      return _buildEmptyState('No hay análisis disponibles', Icons.analytics);
    }

    return Column(
      children: [
        _buildInsightCard(
          'Tendencia de Ventas',
          '${_aiInsights!.salesTrend.growthPercentage.toStringAsFixed(1)}% ${_aiInsights!.salesTrend.trend.toLowerCase()}',
          'Mejor día: ${_aiInsights!.salesTrend.bestDay}',
          Icons.trending_up,
          _getColorFromString(_aiInsights!.salesTrend.color),
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          'Productos Populares',
          '${_aiInsights!.popularProducts.salesCount} ventas del top producto',
          'Top: ${_aiInsights!.popularProducts.topProduct}',
          Icons.star,
          AppTheme.successColor,
        ),
        const SizedBox(height: 8),
        _buildInsightCard(
          'Recomendaciones de Stock',
          '${_aiInsights!.stockRecommendations.length} recomendaciones activas',
          'Revisa las recomendaciones para optimizar tu inventario',
          Icons.inventory_2,
          AppTheme.warningColor,
        ),
      ],
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

  Widget _buildRecommendationCard(AIRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommendation.priorityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: recommendation.priorityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(recommendation.priorityIcon, color: recommendation.priorityColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    color: recommendation.priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: recommendation.statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(recommendation.statusIcon, color: recommendation.statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _getStatusText(recommendation.status),
                      style: TextStyle(
                        color: recommendation.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '💡 ${recommendation.action}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (recommendation.status == RecommendationStatus.nueva) ...[
                _buildActionButton(
                  'Ver',
                  Icons.visibility,
                  AppTheme.primaryColor,
                  () => _markAsViewed(recommendation.id),
                ),
                const SizedBox(width: 8),
              ],
              if (recommendation.status == RecommendationStatus.vista) ...[
                _buildActionButton(
                  'Aplicar',
                  Icons.check_circle,
                  AppTheme.successColor,
                  () => _markAsApplied(recommendation.id),
                ),
                const SizedBox(width: 8),
              ],
              if (recommendation.status != RecommendationStatus.aplicada) ...[
                _buildActionButton(
                  'Descartar',
                  Icons.cancel,
                  AppTheme.errorColor,
                  () => _markAsDiscarded(recommendation.id),
                ),
              ],
              const Spacer(),
              Text(
                _formatDate(recommendation.createdAt),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color) {
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
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
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

  int _getTotalCount() {
    if (_selectedTab == 'recomendaciones') {
      return _recommendations
          .where((r) => r.status == RecommendationStatus.nueva || 
                       r.status == RecommendationStatus.vista)
          .length;
    } else {
      return _aiInsights != null ? 3 : 0; // 3 insights principales
    }
  }

  String _getStatusText(RecommendationStatus status) {
    switch (status) {
      case RecommendationStatus.nueva:
        return 'Nueva';
      case RecommendationStatus.vista:
        return 'Vista';
      case RecommendationStatus.aplicada:
        return 'Aplicada';
      case RecommendationStatus.descartada:
        return 'Descartada';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora';
    }
  }

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

  Future<void> _markAsViewed(String recommendationId) async {
    await _recommendationsService.markAsViewed(recommendationId);
    _loadRecommendations();
  }

  Future<void> _markAsApplied(String recommendationId) async {
    await _recommendationsService.markAsApplied(recommendationId);
    _loadRecommendations();
  }

  Future<void> _markAsDiscarded(String recommendationId) async {
    await _recommendationsService.markAsDiscarded(recommendationId);
    _loadRecommendations();
  }
}
