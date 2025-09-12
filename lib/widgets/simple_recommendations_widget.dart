import 'package:flutter/material.dart';
import 'package:ricitosdebb/config/app_theme.dart';
import 'package:ricitosdebb/models/ai_recommendation.dart';
import 'package:ricitosdebb/services/local_recommendations_service.dart';

/// Widget simplificado para mostrar recomendaciones de IA
class SimpleRecommendationsWidget extends StatefulWidget {
  const SimpleRecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<SimpleRecommendationsWidget> createState() => _SimpleRecommendationsWidgetState();
}

class _SimpleRecommendationsWidgetState extends State<SimpleRecommendationsWidget> {
  final LocalRecommendationsService _recommendationsService = LocalRecommendationsService();
  
  List<AIRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _recommendationsService.dispose();
    super.dispose();
  }

  void _loadRecommendations() {
    if (!mounted) return;
    
    try {
      // Obtener solo recomendaciones activas (nuevas y vistas)
      final allRecommendations = _recommendationsService.getRecommendations();
      final activeRecommendations = allRecommendations
          .where((r) => r.status == RecommendationStatus.nueva || 
                       r.status == RecommendationStatus.vista)
          .toList();
      
      setState(() {
        _recommendations = activeRecommendations;
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
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_recommendations.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        return _buildRecommendationCard(_recommendations[index]);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      child: const Center(
        child: Text(
          'No hay recomendaciones disponibles',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
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
        border: Border.all(
          color: recommendation.priorityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recommendation.priorityIcon,
                color: recommendation.priorityColor,
                size: 16,
              ),
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
              _buildStatusChip(recommendation.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.action,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                recommendation.timeElapsedDescription,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  if (recommendation.status == RecommendationStatus.nueva)
                    _buildActionButton(
                      'Ver',
                      Icons.visibility,
                      () => _markAsViewed(recommendation.id),
                    ),
                  if (recommendation.status == RecommendationStatus.vista) ...[
                    _buildActionButton(
                      'Aplicar',
                      Icons.check,
                      () => _markAsApplied(recommendation.id),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      'Descartar',
                      Icons.close,
                      () => _markAsDiscarded(recommendation.id),
                    ),
                  ],
                  const SizedBox(width: 8),
                  _buildActionButton(
                    'Eliminar',
                    Icons.delete,
                    () => _deleteRecommendation(recommendation.id),
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(RecommendationStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case RecommendationStatus.nueva:
        color = Colors.blue;
        text = 'Nueva';
        break;
      case RecommendationStatus.vista:
        color = Colors.orange;
        text = 'Vista';
        break;
      case RecommendationStatus.aplicada:
        color = Colors.green;
        text = 'Aplicada';
        break;
      case RecommendationStatus.descartada:
        color = Colors.grey;
        text = 'Descartada';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : Colors.blue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              text,
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

  Future<void> _deleteRecommendation(String recommendationId) async {
    await _recommendationsService.deleteRecommendation(recommendationId);
    _loadRecommendations();
  }
}
