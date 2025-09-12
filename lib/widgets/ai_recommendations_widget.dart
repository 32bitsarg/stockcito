import 'package:flutter/material.dart';
import 'package:ricitosdebb/config/app_theme.dart';
import 'package:ricitosdebb/models/ai_recommendation.dart';
import 'package:ricitosdebb/services/local_recommendations_service.dart';
import 'package:ricitosdebb/widgets/animated_widgets.dart';

/// Widget que muestra recomendaciones automáticas de la IA con estados y acciones
class AIRecommendationsWidget extends StatefulWidget {
  const AIRecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<AIRecommendationsWidget> createState() => _AIRecommendationsWidgetState();
}

class _AIRecommendationsWidgetState extends State<AIRecommendationsWidget> {
  final LocalRecommendationsService _recommendationsService = LocalRecommendationsService();
  List<AIRecommendation> _recommendations = [];
  bool _isLoading = true;
  String _selectedFilter = 'todas'; // todas, nuevas, vistas, aplicadas, descartadas

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  @override
  void dispose() {
    _recommendationsService.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    try {
      await _recommendationsService.initialize();
      _loadRecommendations();
    } catch (e) {
      print('Error inicializando servicio de recomendaciones: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  List<AIRecommendation> get _filteredRecommendations {
    switch (_selectedFilter) {
      case 'nuevas':
        return _recommendations.where((r) => r.status == RecommendationStatus.nueva).toList();
      case 'vistas':
        return _recommendations.where((r) => r.status == RecommendationStatus.vista).toList();
      case 'aplicadas':
        return _recommendations.where((r) => r.status == RecommendationStatus.aplicada).toList();
      case 'descartadas':
        return _recommendations.where((r) => r.status == RecommendationStatus.descartada).toList();
      default:
        return _recommendations;
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
          else if (_filteredRecommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.accentColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recomendaciones IA',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredRecommendations.length}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
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
                _buildFilterChip('nuevas', 'Nuevas'),
                const SizedBox(width: 8),
                _buildFilterChip('vistas', 'Vistas'),
                const SizedBox(width: 8),
                _buildFilterChip('aplicadas', 'Aplicadas'),
                const SizedBox(width: 8),
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
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
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
            Icons.psychology_outlined,
            color: AppTheme.textSecondary,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay recomendaciones',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'La IA generará recomendaciones basadas en tus datos',
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

  Widget _buildRecommendationsList() {
    return Column(
      children: _filteredRecommendations
          .map((recommendation) => _buildRecommendationCard(recommendation))
          .toList(),
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
          // Header de la recomendación
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
              // Estado
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
          
          // Mensaje
          Text(
            recommendation.message,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          
          // Acción sugerida
          Text(
            '💡 ${recommendation.action}',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          
          // Botones de acción
          _buildActionButtons(recommendation),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AIRecommendation recommendation) {
    return Row(
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
          const SizedBox(width: 8),
        ],
        if (recommendation.canBeDeleted) ...[
          _buildActionButton(
            'Eliminar',
            Icons.delete,
            AppTheme.textSecondary,
            () => _deleteRecommendation(recommendation.id),
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
