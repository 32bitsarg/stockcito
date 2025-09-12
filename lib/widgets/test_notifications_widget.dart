import 'package:flutter/material.dart';

/// Widget de prueba para notificaciones
class TestNotificationsWidget extends StatefulWidget {
  const TestNotificationsWidget({Key? key}) : super(key: key);

  @override
  State<TestNotificationsWidget> createState() => _TestNotificationsWidgetState();
}

class _TestNotificationsWidgetState extends State<TestNotificationsWidget> {
  bool _showDropdown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botón de notificaciones
        GestureDetector(
          onTap: () {
            print('🔔 TEST: Botón clickeado - _showDropdown: $_showDropdown');
            setState(() {
              _showDropdown = !_showDropdown;
            });
            print('🔔 TEST: Después del click - _showDropdown: $_showDropdown');
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.notifications,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        
        // Dropdown
        if (_showDropdown) ...[
          const SizedBox(height: 10),
          Container(
            width: 200,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '¡Dropdown funcionando!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
