import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/sidebar/sidebar_state_service.dart';

/// Widget que muestra la sección de estado de actualizaciones en el sidebar
class SidebarUpdateSection extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onUpdateTap;

  const SidebarUpdateSection({
    super.key,
    this.isExpanded = false,
    this.onUpdateTap,
  });

  @override
  State<SidebarUpdateSection> createState() => _SidebarUpdateSectionState();
}

class _SidebarUpdateSectionState extends State<SidebarUpdateSection> {
  final SidebarStateService _stateService = SidebarStateService();
  
  @override
  void initState() {
    super.initState();
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _stateService.updateStream.listen((updateInfo) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUpdate = _stateService.pendingUpdate != null;
    final isLoading = _stateService.isCheckingUpdates;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3C096C), // Púrpura oscuro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasUpdate 
              ? AppTheme.warningColor.withOpacity(0.1)
              : AppTheme.successColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono y título
          Row(
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                )
              else
                Icon(
                  hasUpdate ? Icons.system_update : Icons.check_circle,
                  size: 20,
                  color: hasUpdate ? AppTheme.warningColor : AppTheme.successColor,
                ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasUpdate ? 'Actualización disponible' : 'App actualizada',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          if (widget.isExpanded) ...[
            const SizedBox(height: 8),
            // Subtítulo
            Text(
              hasUpdate 
                  ? 'Nueva versión ${_stateService.pendingUpdate?.version} disponible'
                  : 'Tu aplicación está actualizada',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            if (hasUpdate) ...[
              const SizedBox(height: 12),
              // Botón de actualización
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onUpdateTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Actualizar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Solo icono si está colapsado
            const SizedBox(height: 8),
            Center(
              child: Icon(
                hasUpdate ? Icons.system_update : Icons.check_circle,
                size: 16,
                color: hasUpdate ? AppTheme.warningColor : AppTheme.successColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
