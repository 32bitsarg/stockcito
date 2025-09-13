import 'package:flutter/material.dart';
import 'package:ricitosdebb/services/ml/ml_training_service.dart';
import 'package:ricitosdebb/services/ml/ml_consent_service.dart';
import 'package:ricitosdebb/services/system/logging_service.dart';

/// Widget para mostrar consentimiento de datos ML y configurar entrenamiento
class MLConsentWidget extends StatefulWidget {
  final VoidCallback? onConsentChanged;
  final bool showAsModal;
  
  const MLConsentWidget({
    Key? key,
    this.onConsentChanged,
    this.showAsModal = false,
  }) : super(key: key);

  @override
  State<MLConsentWidget> createState() => _MLConsentWidgetState();

  /// Muestra el modal de consentimiento
  static Future<void> showConsentModal(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: const MLConsentWidget(showAsModal: true),
          ),
        );
      },
    );
  }
}

class _MLConsentWidgetState extends State<MLConsentWidget> {
  final MLTrainingService _mlTrainingService = MLTrainingService();
  final MLConsentService _consentService = MLConsentService();
  bool _hasConsent = false;
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
    _loadStats();
  }

  Future<void> _loadConsentStatus() async {
    try {
      final hasConsent = await _consentService.hasUserGivenConsent();
      final stats = await _mlTrainingService.getTrainingStats();
      setState(() {
        _hasConsent = hasConsent;
        _stats = stats;
      });
    } catch (e) {
      LoggingService.error('Error cargando estado de consentimiento: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _mlTrainingService.getTrainingStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      LoggingService.error('Error cargando estadísticas: $e');
    }
  }

  Future<void> _toggleConsent(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el nuevo servicio de consentimiento
      await _consentService.processUserConsent(value);
      
      setState(() {
        _hasConsent = value;
      });
      
      await _loadStats();
      
      if (widget.onConsentChanged != null) {
        widget.onConsentChanged!();
      }
      
      if (widget.showAsModal) {
        // Si es modal, cerrar después de procesar
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value 
                ? 'Consentimiento otorgado. La IA se entrenará con todos los datos disponibles.'
                : 'Consentimiento revocado. La IA solo usará datos locales.',
          ),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      LoggingService.error('Error actualizando consentimiento: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error actualizando consentimiento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retrainML() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _mlTrainingService.trainWithNewData();
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IA reentrenada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      LoggingService.warning('Error reentrenando IA (RLS): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IA entrenada localmente (error de conexión)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configuración de IA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Estado actual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _hasConsent ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _hasConsent ? Colors.green.shade200 : Colors.orange.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _hasConsent ? Icons.check_circle : Icons.info,
                    color: _hasConsent ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _hasConsent 
                          ? 'La IA se entrena con todos los datos disponibles (local + remoto)'
                          : 'La IA solo usa datos locales para proteger tu privacidad',
                      style: TextStyle(
                        color: _hasConsent ? Colors.green.shade800 : Colors.orange.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Estadísticas
            if (_stats.isNotEmpty) ...[
              Text(
                'Estadísticas de Entrenamiento',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Registros Locales',
                      '${_stats['local_records'] ?? 0}',
                      Icons.storage,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Último Entrenamiento',
                      _stats['last_training'] != null 
                          ? _formatDate(_stats['last_training'])
                          : 'Nunca',
                      Icons.schedule,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Tipo de Usuario',
                      _stats['is_anonymous'] == true ? 'Anónimo' : 'Autenticado',
                      Icons.person,
                      _stats['is_anonymous'] == true ? Colors.orange : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Estado',
                      _stats['is_signed_in'] == true ? 'Conectado' : 'Desconectado',
                      Icons.wifi,
                      _stats['is_signed_in'] == true ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            
            // Controles
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: Text(
                      _hasConsent 
                          ? 'Compartir datos para mejorar IA'
                          : 'Solo usar datos locales',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      _hasConsent 
                          ? 'Los datos se envían de forma anónima'
                          : 'Máxima privacidad, datos solo locales',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _hasConsent,
                    onChanged: _isLoading ? null : _toggleConsent,
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Botón de reentrenamiento
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _retrainML,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(_isLoading ? 'Reentrenando...' : 'Reentrenar IA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Información',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Los datos se procesan de forma segura y anónima\n'
                    '• Mejorar la IA ayuda a todos los usuarios\n'
                    '• Puedes cambiar esta configuración en cualquier momento',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Nunca';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return 'Hace ${difference.inDays} días';
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours} horas';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes} minutos';
      } else {
        return 'Hace un momento';
      }
    } catch (e) {
      return 'Error';
    }
  }
}
