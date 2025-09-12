import 'package:flutter/material.dart';
import '../models/smart_alert.dart';
import '../services/datos/smart_alerts_service.dart';

/// Widget de notificaciones estilo Facebook con dropdown flotante
class FacebookNotificationsWidget extends StatefulWidget {
  const FacebookNotificationsWidget({Key? key}) : super(key: key);

  @override
  State<FacebookNotificationsWidget> createState() => _FacebookNotificationsWidgetState();
}

class _FacebookNotificationsWidgetState extends State<FacebookNotificationsWidget> {
  bool _isDropdownOpen = false;
  OverlayEntry? _overlayEntry;
  final SmartAlertsService _alertsService = SmartAlertsService();
  List<SmartAlert> _alerts = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  /// Carga las alertas del servicio
  Future<void> _loadAlerts() async {
    try {
      final alerts = _alertsService.getUnreadAlerts();
      setState(() {
        _alerts = alerts;
        _unreadCount = alerts.length;
      });
    } catch (e) {
      print('Error cargando alertas: $e');
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showDropdown() {
    if (_isDropdownOpen) return;

    // Refrescar alertas antes de mostrar
    _loadAlerts();

    setState(() {
      _isDropdownOpen = true;
    });

    // Obtener la posición del botón
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Offset position = renderBox!.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlay(position, size),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideDropdown() {
    if (!_isDropdownOpen) return;

    setState(() {
      _isDropdownOpen = false;
    });

    _removeOverlay();
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  Widget _buildOverlay(Offset buttonPosition, Size buttonSize) {
    return GestureDetector(
      onTap: _hideDropdown,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Fondo semi-transparente
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
              ),
            ),
            // Dropdown posicionado justo debajo del botón
            Positioned(
              top: buttonPosition.dy + buttonSize.height + 8, // 8px de separación
              right: MediaQuery.of(context).size.width - buttonPosition.dx - buttonSize.width,
              child: GestureDetector(
                onTap: () {}, // Prevenir que se cierre al hacer clic en el dropdown
                child: _buildDropdownContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownContent() {
    return Container(
      width: 300,
      constraints: const BoxConstraints(
        maxHeight: 350,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del dropdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE4E6EA),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Notificaciones${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1E21),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _hideDropdown,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de notificaciones
          Flexible(
            child: _alerts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final alert = _alerts[index];
                      return _buildAlertItem(alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Construye el estado vacío cuando no hay alertas
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Te notificaremos cuando haya algo importante',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye un elemento de alerta
  Widget _buildAlertItem(SmartAlert alert) {
    return GestureDetector(
      onTap: () => _markAsRead(alert),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: alert.isRead ? Colors.white : const Color(0xFFF8F9FA),
          border: const Border(
            bottom: BorderSide(
              color: Color(0xFFF0F2F5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: alert.typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                alert.typeIcon,
                color: alert.typeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: alert.isRead ? FontWeight.w500 : FontWeight.w600,
                            color: const Color(0xFF1C1E21),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (!alert.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _deleteAlert(alert),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF65676B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.timeElapsedDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8D91),
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

  /// Marca una alerta como leída
  Future<void> _markAsRead(SmartAlert alert) async {
    try {
      await _alertsService.markAsRead(alert.id);
      await _loadAlerts(); // Recargar las alertas
    } catch (e) {
      print('Error marcando alerta como leída: $e');
    }
  }

  /// Elimina una alerta
  Future<void> _deleteAlert(SmartAlert alert) async {
    try {
      await _alertsService.deleteAlert(alert.id);
      await _loadAlerts(); // Recargar las alertas
    } catch (e) {
      print('Error eliminando alerta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDropdown,
      child: Stack(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isDropdownOpen ? const Color(0xFF1877F2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.notifications,
              color: _isDropdownOpen ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          // Indicador de notificaciones no leídas
          if (_unreadCount > 0)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
