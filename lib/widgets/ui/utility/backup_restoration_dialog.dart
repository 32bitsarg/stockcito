import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/system/automated_backup_service.dart';
import 'package:stockcito/services/system/backup_conflict_resolver.dart';

/// Diálogo para confirmar y ejecutar la restauración de backup
class BackupRestorationDialog extends StatefulWidget {
  final String backupPath;
  final String backupFileName;

  const BackupRestorationDialog({
    super.key,
    required this.backupPath,
    required this.backupFileName,
  });

  @override
  State<BackupRestorationDialog> createState() => _BackupRestorationDialogState();
}

class _BackupRestorationDialogState extends State<BackupRestorationDialog> {
  final AutomatedBackupService _backupService = AutomatedBackupService();
  final BackupConflictResolver _conflictResolver = BackupConflictResolver();
  
  bool _isAnalyzing = false;
  bool _isRestoring = false;
  Map<String, dynamic>? _backupInfo;
  List<ConflictInfo> _conflicts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _analyzeBackup();
  }

  Future<void> _analyzeBackup() async {
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      LoggingService.info('🔍 Analizando backup: ${widget.backupPath}');
      
      // Analizar el backup
      final backupInfo = await _backupService.analyzeBackup(widget.backupPath);
      
      if (mounted) {
        setState(() {
          _backupInfo = backupInfo;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      LoggingService.error('Error analizando backup: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _performRestoration() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      LoggingService.info('🔄 Iniciando restauración desde: ${widget.backupPath}');
      
      // Realizar restauración
      await _backupService.restoreFromBackup(widget.backupPath);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Retornar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Restauración completada exitosamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      LoggingService.error('Error en restauración: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isRestoring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.restore,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Restaurar Backup'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del archivo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Archivo: ${widget.backupFileName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ruta: ${widget.backupPath}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Estado de análisis
            if (_isAnalyzing) ...[
              Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Analizando backup...'),
                ],
              ),
            ],

            // Información del backup
            if (_backupInfo != null && !_isAnalyzing) ...[
              _buildBackupInfo(),
              const SizedBox(height: 16),
            ],

            // Conflictos encontrados
            if (_conflicts.isNotEmpty) ...[
              _buildConflictsSection(),
              const SizedBox(height: 16),
            ],

            // Error
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Advertencia
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción reemplazará todos los datos actuales con los datos del backup. Se creará un backup de seguridad antes de proceder.',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRestoring ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_isAnalyzing || _isRestoring || _errorMessage != null) 
              ? null 
              : _performRestoration,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isRestoring
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Restaurando...'),
                  ],
                )
              : const Text('Restaurar'),
        ),
      ],
    );
  }

  Widget _buildBackupInfo() {
    final info = _backupInfo!;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Información del Backup',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Versión', info['version'] ?? 'Desconocida'),
          _buildInfoRow('Tipo', info['type'] ?? 'Desconocido'),
          _buildInfoRow('Fecha', _formatDate(info['timestamp'])),
          _buildInfoRow('Usuario', info['user_id'] ?? 'Desconocido'),
          _buildInfoRow('Productos', '${info['productos_count'] ?? 0}'),
          _buildInfoRow('Ventas', '${info['ventas_count'] ?? 0}'),
          _buildInfoRow('Clientes', '${info['clientes_count'] ?? 0}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_outlined,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Conflictos Detectados',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _conflictResolver.generateConflictSummary(_conflicts),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? timestamp) {
    if (timestamp == null) return 'Desconocida';
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Formato inválido';
    }
  }
}
