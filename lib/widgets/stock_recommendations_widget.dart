import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ricitosdebb/services/demand_prediction_service.dart';
import 'package:ricitosdebb/services/smart_notification_service.dart';
import 'package:ricitosdebb/config/app_theme.dart';

class StockRecommendationsWidget extends StatefulWidget {
  const StockRecommendationsWidget({Key? key}) : super(key: key);

  @override
  State<StockRecommendationsWidget> createState() => _StockRecommendationsWidgetState();
}

class _StockRecommendationsWidgetState extends State<StockRecommendationsWidget> {
  final DemandPredictionService _demandService = DemandPredictionService();
  final SmartNotificationService _notificationService = SmartNotificationService();
  
  List<StockRecommendation> _recommendations = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final recommendations = await _demandService.getStockRecommendations();
      
      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error cargando recomendaciones: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendNotification(StockRecommendation recommendation) async {
    try {
      await _notificationService.sendImmediateRecommendation(recommendation);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notificación enviada para ${recommendation.producto.nombre}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enviando notificación: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Altura aumentada para mejor visualización
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.lightbulb,
                color: AppTheme.warningColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recomendaciones IA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
                strokeWidth: 2,
              ),
            )
          else if (_error.isNotEmpty)
            _buildErrorState()
          else if (_recommendations.isEmpty)
            _buildEmptyState()
          else
            _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.triangleExclamation,
            color: AppTheme.errorColor,
            size: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Error cargando datos',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            FontAwesomeIcons.checkCircle,
            color: AppTheme.successColor,
            size: 12,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Stock adecuado',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    final recommendation = _recommendations.first;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.producto.nombre,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Stock: ${recommendation.currentStock} → ${recommendation.recommendedStock}',
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: () => _sendNotification(recommendation),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 24),
            ),
            child: const Text('Notificar', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(StockRecommendation recommendation) {
    final urgencyColor = _getUrgencyColor(recommendation.urgency);
    final urgencyIcon = _getUrgencyIcon(recommendation.urgency);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: urgencyColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: urgencyColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre y urgencia
          Row(
            children: [
              Icon(urgencyIcon, color: urgencyColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.producto.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: urgencyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getUrgencyText(recommendation.urgency),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: urgencyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Información de stock
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStockInfo('Actual', '${recommendation.currentStock}', AppTheme.textSecondary),
              _buildStockInfo('Recomendado', '${recommendation.recommendedStock}', urgencyColor),
              _buildStockInfo('Demanda', '${recommendation.predictedDemand}', AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 8),
          
          // Razón
          Text(
            recommendation.reason,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          
          // Botones
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendNotification(recommendation),
                  icon: const Icon(FontAwesomeIcons.bell, size: 12),
                  label: const Text('Notificar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRecommendationDetails(recommendation),
                  icon: const Icon(FontAwesomeIcons.eye, size: 12),
                  label: const Text('Detalles', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getUrgencyColor(DemandUrgency urgency) {
    switch (urgency) {
      case DemandUrgency.high:
        return AppTheme.errorColor;
      case DemandUrgency.medium:
        return AppTheme.warningColor;
      case DemandUrgency.low:
        return AppTheme.successColor;
    }
  }

  IconData _getUrgencyIcon(DemandUrgency urgency) {
    switch (urgency) {
      case DemandUrgency.high:
        return FontAwesomeIcons.triangleExclamation;
      case DemandUrgency.medium:
        return FontAwesomeIcons.exclamation;
      case DemandUrgency.low:
        return FontAwesomeIcons.info;
    }
  }

  String _getUrgencyText(DemandUrgency urgency) {
    switch (urgency) {
      case DemandUrgency.high:
        return 'ALTA';
      case DemandUrgency.medium:
        return 'MEDIA';
      case DemandUrgency.low:
        return 'BAJA';
    }
  }

  void _showRecommendationDetails(StockRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de Recomendación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Producto: ${recommendation.producto.nombre}'),
            const SizedBox(height: 6),
            Text('Stock actual: ${recommendation.currentStock} unidades'),
            Text('Stock recomendado: ${recommendation.recommendedStock} unidades'),
            Text('Diferencia: +${recommendation.stockDifference} unidades'),
            Text('Demanda esperada: ${recommendation.predictedDemand} unidades'),
            Text('Confianza: ${(recommendation.confidence * 100).toStringAsFixed(1)}%'),
            const SizedBox(height: 6),
            Text('Razón: ${recommendation.reason}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
