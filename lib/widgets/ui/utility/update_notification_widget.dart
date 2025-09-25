import 'package:flutter/material.dart';
import '../../../services/system/update_service.dart';
import '../../../services/system/logging_service.dart';

/// Widget para mostrar notificaciones de actualización
class UpdateNotificationWidget extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onDismiss;
  final bool isMandatory;

  const UpdateNotificationWidget({
    super.key,
    required this.updateInfo,
    this.onDismiss,
    this.isMandatory = false,
  });

  @override
  State<UpdateNotificationWidget> createState() => _UpdateNotificationWidgetState();
}

class _UpdateNotificationWidgetState extends State<UpdateNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Estados para descarga
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimation();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimation() {
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMandatory) {
      return _buildMandatoryUpdateDialog();
    } else {
      return _buildOptionalUpdateTooltip();
    }
  }

  /// Construye el diálogo para actualizaciones obligatorias
  Widget _buildMandatoryUpdateDialog() {
    return Material(
      color: Colors.black54,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono de actualización
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.system_update,
                      size: 48,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Título
                  Text(
                    'Actualización Obligatoria',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Versión
                  Text(
                    'Versión ${widget.updateInfo.version}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción
                  Text(
                    'Esta actualización contiene cambios importantes que requieren que actualices la aplicación para continuar usándola.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón de actualizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _handleUpdate,
                      icon: const Icon(Icons.download),
                      label: const Text('Actualizar Ahora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construye el tooltip para actualizaciones opcionales
  Widget _buildOptionalUpdateTooltip() {
    return Positioned(
      bottom: 60,
      left: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.system_update,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nueva Versión Disponible',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _handleDismiss,
                        icon: const Icon(Icons.close, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Versión
                  Text(
                    'Versión ${widget.updateInfo.version}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _handleDismiss,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text('Más Tarde'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isDownloading ? null : _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: _isDownloading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        value: _downloadProgress,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${(_downloadProgress * 100).toInt()}%'),
                                  ],
                                )
                              : const Text('Actualizar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Maneja la acción de actualizar
  void _handleUpdate() async {
    try {
      LoggingService.info('Usuario inició actualización a versión ${widget.updateInfo.version}');
      
      // Mostrar diálogo de confirmación
      final confirmed = await _showUpdateConfirmationDialog();
      if (!confirmed) return;
      
      // Iniciar descarga
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });
      
      // Descargar archivo
      final filePath = await UpdateService().downloadUpdateFile(
        widget.updateInfo,
        (progress) {
          setState(() {
            _downloadProgress = progress;
          });
        },
      );
      
      // Instalar actualización
      await UpdateService().installUpdate(filePath);
      
    } catch (e) {
      LoggingService.error('Error iniciando actualización: $e');
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error iniciando actualización: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra el diálogo de confirmación de actualización
  Future<bool> _showUpdateConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Actualización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Deseas actualizar a la versión ${widget.updateInfo.version}?'),
            const SizedBox(height: 12),
            const Text(
              'La aplicación se cerrará automáticamente para instalar la actualización.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Actualizar'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// Maneja la acción de descartar
  void _handleDismiss() {
    LoggingService.info('Usuario descartó actualización a versión ${widget.updateInfo.version}');
    _animationController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }
}
