import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';

/// Widget para seleccionar el modo de operación de la calculadora
class CalculadoraModoSelectorWidget extends StatefulWidget {
  final CalculadoraConfig config;
  final Function(CalculadoraConfig) onConfigChanged;
  final VoidCallback? onModoChanged;

  const CalculadoraModoSelectorWidget({
    Key? key,
    required this.config,
    required this.onConfigChanged,
    this.onModoChanged,
  }) : super(key: key);

  @override
  State<CalculadoraModoSelectorWidget> createState() => _CalculadoraModoSelectorWidgetState();
}

class _CalculadoraModoSelectorWidgetState extends State<CalculadoraModoSelectorWidget> {
  late bool _modoAvanzado;

  @override
  void initState() {
    super.initState();
    _modoAvanzado = widget.config.modoAvanzado;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            Icon(
              Icons.settings,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Modo de Operación',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Selector de modo
        Row(
          children: [
            Expanded(
              child: _buildModoCard(
                titulo: 'Modo Simple',
                descripcion: 'Perfecto para guardar productos rápidamente',
                icono: Icons.speed,
                esSeleccionado: !_modoAvanzado,
                onTap: () => _cambiarModo(false),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModoCard(
                titulo: 'Modo Avanzado',
                descripcion: 'Análisis detallado con IA y optimización',
                icono: Icons.analytics,
                esSeleccionado: _modoAvanzado,
                onTap: () => _cambiarModo(true),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Información del modo seleccionado
        _buildModoInfo(),
      ],
    );
  }

  Widget _buildModoCard({
    required String titulo,
    required String descripcion,
    required IconData icono,
    required bool esSeleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esSeleccionado 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: esSeleccionado 
                ? AppTheme.primaryColor
                : Colors.grey.withOpacity(0.3),
            width: esSeleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 32,
              color: esSeleccionado 
                  ? AppTheme.primaryColor
                  : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: esSeleccionado 
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              style: TextStyle(
                fontSize: 12,
                color: esSeleccionado 
                    ? AppTheme.primaryColor.withOpacity(0.8)
                    : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (esSeleccionado)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTIVO',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _modoAvanzado 
            ? AppTheme.infoColor.withOpacity(0.1)
            : AppTheme.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _modoAvanzado 
              ? AppTheme.infoColor.withOpacity(0.3)
              : AppTheme.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _modoAvanzado ? Icons.analytics : Icons.speed,
            color: _modoAvanzado ? AppTheme.infoColor : AppTheme.successColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modoAvanzado ? 'Modo Avanzado Activado' : 'Modo Simple Activado',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _modoAvanzado ? AppTheme.infoColor : AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _modoAvanzado 
                      ? 'Análisis completo con IA, optimización de costos y recomendaciones inteligentes'
                      : 'Guardado rápido de productos con análisis básico y sugerencias',
                  style: TextStyle(
                    fontSize: 12,
                    color: _modoAvanzado ? AppTheme.infoColor.withOpacity(0.8) : AppTheme.successColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _cambiarModo(bool modoAvanzado) {
    setState(() {
      _modoAvanzado = modoAvanzado;
    });

    // Actualizar configuración
    final nuevaConfig = widget.config.copyWith(modoAvanzado: modoAvanzado);
    widget.onConfigChanged(nuevaConfig);

    // Notificar cambio
    widget.onModoChanged?.call();

    // Mostrar snackbar informativo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          modoAvanzado 
              ? 'Modo Avanzado activado - Análisis completo disponible'
              : 'Modo Simple activado - Guardado rápido disponible',
        ),
        backgroundColor: modoAvanzado ? AppTheme.infoColor : AppTheme.successColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
