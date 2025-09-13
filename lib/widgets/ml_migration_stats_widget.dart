import 'package:flutter/material.dart';
import 'package:ricitosdebb/services/system/data_migration_service.dart';
import 'package:ricitosdebb/config/app_theme.dart';

class MLMigrationStatsWidget extends StatefulWidget {
  const MLMigrationStatsWidget({super.key});

  @override
  State<MLMigrationStatsWidget> createState() => _MLMigrationStatsWidgetState();
}

class _MLMigrationStatsWidgetState extends State<MLMigrationStatsWidget> {
  final DataMigrationService _migrationService = DataMigrationService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  // Método público para forzar actualización
  void refreshStats() {
    _loadStats();
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Recargar stats cada 30 segundos para optimizar peticiones a Firebase
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _loadStats();
        _startPeriodicRefresh(); // Continuar el ciclo
      }
    });
  }

  Future<void> _loadStats() async {
    try {
      print('🔍 DEBUG: Cargando estadísticas de migración...');
      final stats = await _migrationService.getMigrationStats();
      print('🔍 DEBUG: Estadísticas obtenidas: $stats');
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
        print('✅ DEBUG: Estadísticas actualizadas en el widget');
      }
    } catch (e) {
      print('❌ DEBUG: Error cargando estadísticas de migración: $e');
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
      return Container(
        height: 60,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final trainingDataCount = _stats['training_data_count'] ?? 0;
    final modelsCount = _stats['models_count'] ?? 0;
    final predictionsCount = _stats['predictions_count'] ?? 0;
    final migrationCompleted = _stats['migration_completed'] ?? false;
    
    // Determinar si está conectado basado en si hay datos o modelos
    final isConnected = trainingDataCount > 0 || modelsCount > 0 || migrationCompleted;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_sync,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'IA Colaborativa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected 
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isConnected ? 'Conectado' : 'Conectando...',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isConnected 
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tus datos se usan para entrenar la IA global de forma anónima y segura.',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Datos de Entrenamiento',
                  trainingDataCount.toString(),
                  Icons.data_usage,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Modelos IA',
                  modelsCount.toString(),
                  Icons.psychology,
                  AppTheme.secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Predicciones',
                  predictionsCount.toString(),
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Privacidad',
                  '100%',
                  Icons.lock,
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.accentColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los datos están encriptados y solo se usan para mejorar las recomendaciones.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
