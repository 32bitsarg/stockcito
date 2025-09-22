import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';

/// Header de la calculadora de precios
class CalculadoraHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const CalculadoraHeader({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Icono y título
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.calculator,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Título y descripción
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calculadora de Precios Inteligente',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Calcula el precio perfecto para tus productos',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Botón de cerrar (si es necesario)
          if (onClose != null)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: onClose,
                icon: const FaIcon(
                  FontAwesomeIcons.xmark,
                  color: Colors.white,
                  size: 18,
                ),
                tooltip: 'Cerrar calculadora',
              ),
            ),
        ],
      ),
    );
  }
}
