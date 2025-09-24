import 'dart:io';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/system/automated_backup_service.dart';
import '../functions/configuracion_functions.dart';

class ConfiguracionBackupSection extends StatefulWidget {
  const ConfiguracionBackupSection({super.key});

  @override
  State<ConfiguracionBackupSection> createState() => _ConfiguracionBackupSectionState();
}

class _ConfiguracionBackupSectionState extends State<ConfiguracionBackupSection> {
  final AutomatedBackupService _backupService = AutomatedBackupService();
  bool _isBackingUp = false;
  Map<String, dynamic>? _backupStats;

  @override
  void initState() {
    super.initState();
    _loadBackupStats();
  }

  Future<void> _loadBackupStats() async {
    try {
      final stats = _backupService.getBackupStats();
      setState(() {
        _backupStats = stats;
      });
    } catch (e) {
      print('Error cargando estadísticas de backup: $e');
    }
  }

  Future<void> _performManualBackup() async {
    setState(() {
      _isBackingUp = true;
    });

    try {
      final backupPath = await _backupService.performBackup(BackupType.complete);
      
      if (mounted) {
        ConfiguracionFunctions.showExportSuccessDialog(context, backupPath);
        await _loadBackupStats();
      }
    } catch (e) {
      if (mounted) {
        ConfiguracionFunctions.showWarningSnackBar(
          context,
          'Error realizando backup: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _listBackups() async {
    try {
      final backups = await _backupService.listAvailableBackups();
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Backups Disponibles'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  final fileName = backup.path.split('/').last;
                  final fileSize = (backup.statSync().size / 1024 / 1024).toStringAsFixed(2);
                  
                  return ListTile(
                    leading: const Icon(Icons.backup, color: AppTheme.primaryColor),
                    title: Text(fileName),
                    subtitle: Text('${fileSize} MB'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _deleteBackup(backup.path),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ConfiguracionFunctions.showWarningSnackBar(
          context,
          'Error listando backups: $e',
        );
      }
    }
  }

  Future<void> _deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      await file.delete();
      
      if (mounted) {
        ConfiguracionFunctions.showSuccessSnackBar(
          context,
          'Backup eliminado correctamente',
        );
        _listBackups(); // Refrescar lista
      }
    } catch (e) {
      if (mounted) {
        ConfiguracionFunctions.showWarningSnackBar(
          context,
          'Error eliminando backup: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.backup,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Backup Automático',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estado del sistema de backup
          if (_backupStats != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado del Sistema',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _backupStats!['is_initialized'] == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: _backupStats!['is_initialized'] == true
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _backupStats!['is_initialized'] == true
                            ? 'Sistema activo'
                            : 'Sistema inactivo',
                        style: TextStyle(
                          color: _backupStats!['is_initialized'] == true
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (_backupStats!['last_backup_time'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Último backup: ${_formatDateTime(_backupStats!['last_backup_time'])}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Configuración de backup
          const Text(
            'Configuración',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Frecuencias de backup
          _buildBackupFrequencyItem(
            'Backup Diario',
            'Se realiza automáticamente cada día a las 02:00 AM',
            Icons.schedule,
            AppTheme.infoColor,
          ),
          const SizedBox(height: 8),
          _buildBackupFrequencyItem(
            'Backup Semanal',
            'Se realiza automáticamente los domingos a las 03:00 AM',
            Icons.calendar_today,
            AppTheme.warningColor,
          ),
          const SizedBox(height: 8),
          _buildBackupFrequencyItem(
            'Backup Mensual',
            'Se realiza automáticamente el primer día del mes a las 04:00 AM',
            Icons.event,
            AppTheme.successColor,
          ),
          const SizedBox(height: 20),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isBackingUp ? null : _performManualBackup,
                  icon: _isBackingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.backup),
                  label: Text(_isBackingUp ? 'Realizando Backup...' : 'Backup Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _listBackups,
                  icon: const Icon(Icons.list),
                  label: const Text('Ver Backups'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildBackupFrequencyItem(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
