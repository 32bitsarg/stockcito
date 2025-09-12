import 'package:flutter/material.dart';

/// Widget simple de notificaciones para testing
class SimpleNotificationsWidget extends StatefulWidget {
  const SimpleNotificationsWidget({Key? key}) : super(key: key);

  @override
  State<SimpleNotificationsWidget> createState() => _SimpleNotificationsWidgetState();
}

class _SimpleNotificationsWidgetState extends State<SimpleNotificationsWidget> {
  bool _isDropdownOpen = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Cerrar dropdown si está abierto
        if (_isDropdownOpen) {
          print('🔔 DEBUG: Clic fuera del dropdown - cerrando');
          setState(() {
            _isDropdownOpen = false;
          });
        }
      },
      child: Stack(
        children: [
          // Botón de notificaciones
          GestureDetector(
            onTap: () {
              print('🔔 DEBUG: Botón de notificaciones clickeado - _isDropdownOpen: $_isDropdownOpen');
              setState(() {
                _isDropdownOpen = !_isDropdownOpen;
              });
              print('🔔 DEBUG: Después del click - _isDropdownOpen: $_isDropdownOpen');
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          '2',
                          style: TextStyle(
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
            ),
          ),

          // Dropdown de notificaciones
          if (_isDropdownOpen) ...[
            () {
              print('🔔 DEBUG: Renderizando dropdown - _isDropdownOpen: $_isDropdownOpen');
              return SizedBox.shrink();
            }(),
            Positioned(
              top: 50,
              right: 0,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.notifications, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Notificaciones (2)',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Lista de notificaciones
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(8),
                          children: [
                            _buildNotificationItem(
                              'Stock Bajo',
                              'Body tiene solo 0 unidades en stock',
                              Colors.red,
                            ),
                            _buildNotificationItem(
                              'Precio Bajo',
                              'Body tiene un precio muy bajo',
                              Colors.orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String title, String message, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
