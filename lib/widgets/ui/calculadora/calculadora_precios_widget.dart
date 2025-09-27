import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../services/ui/calculadora/calculadora_persistence_service.dart';
import '../../../services/ui/calculadora/modo_simple_service.dart';
import '../../../services/ui/calculadora/modo_avanzado_service.dart';
import 'calculadora_modo_selector_widget.dart';
import 'calculadora_modo_simple_form_widget.dart';
import 'calculadora_modo_avanzado_form_widget.dart';

/// Widget principal de la calculadora de precios
class CalculadoraPreciosWidget extends StatefulWidget {
  final bool showCloseButton;
  final VoidCallback? onClose;

  const CalculadoraPreciosWidget({
    Key? key,
    this.showCloseButton = false,
    this.onClose,
  }) : super(key: key);

  @override
  State<CalculadoraPreciosWidget> createState() => _CalculadoraPreciosWidgetState();
}

class _CalculadoraPreciosWidgetState extends State<CalculadoraPreciosWidget> {
  final CalculadoraPersistenceService _persistenceService = CalculadoraPersistenceService();

  CalculadoraConfig _config = CalculadoraConfig.defaultConfig;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón de cerrar si es necesario (sin título)
              if (widget.showCloseButton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: widget.onClose,
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 10),
              
              // Selector de modo (sin contenedor)
              CalculadoraModoSelectorWidget(
                config: _config,
                onConfigChanged: _actualizarConfiguracion,
                onModoChanged: () {
                  setState(() {
                    // Forzar rebuild cuando cambia el modo
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Formulario según el modo seleccionado (sin contenedor)
              _config.modoAvanzado
                  ? CalculadoraModoAvanzadoFormWidget(
                      config: _config,
                      onResultado: _manejarResultadoAvanzado,
                    )
                  : CalculadoraModoSimpleFormWidget(
                      config: _config,
                      onResultado: _manejarResultadoSimple,
                    ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              Text(
                'Cargando calculadora...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: 20),
                Text(
                  'Error cargando calculadora',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Error desconocido',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _cargarConfiguracion,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _persistenceService.cargarConfiguracion();
      setState(() {
        _config = config ?? CalculadoraConfig.defaultConfig;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _actualizarConfiguracion(CalculadoraConfig nuevaConfig) async {
    try {
      await _persistenceService.guardarConfiguracion(nuevaConfig);
      setState(() {
        _config = nuevaConfig;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando configuración: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _manejarResultadoSimple(ResultadoModoSimple resultado) {
    if (resultado.exito) {
      _mostrarDialogoExito(
        titulo: 'Producto Guardado',
        mensaje: resultado.mensaje ?? 'Producto guardado exitosamente',
        detalles: resultado.analisisBasico,
      );
    } else {
      _mostrarDialogoError(
        titulo: 'Error Guardando Producto',
        mensaje: resultado.mensaje ?? 'Error desconocido',
      );
    }
  }

  void _manejarResultadoAvanzado(ResultadoModoAvanzado resultado) {
    if (resultado.exito) {
      _mostrarDialogoExito(
        titulo: 'Producto Guardado',
        mensaje: resultado.mensaje ?? 'Producto guardado exitosamente',
        detalles: resultado.analisisDetallado,
      );
    } else {
      _mostrarDialogoError(
        titulo: 'Error Guardando Producto',
        mensaje: resultado.mensaje ?? 'Error desconocido',
      );
    }
  }

  void _mostrarDialogoExito({
    required String titulo,
    required String mensaje,
    Map<String, dynamic>? detalles,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppTheme.successColor),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensaje),
              if (detalles != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Detalles:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._buildDetalles(detalles),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _verHistorial();
            },
            child: const Text('Ver Historial'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoError({
    required String titulo,
    required String mensaje,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text(titulo),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetalles(Map<String, dynamic> detalles) {
    final widgets = <Widget>[];
    
    detalles.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text('$key: ${value.toString()}'),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text('$key: $value'),
          ),
        );
      }
    });
    
    return widgets;
  }

  Future<void> _verHistorial() async {
    try {
      final historial = await _persistenceService.cargarHistorial(limite: 20);
      
      if (historial.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay historial de cálculos'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Historial de Cálculos'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: historial.length,
              itemBuilder: (context, index) {
                final calculo = historial[index];
                return ListTile(
                  leading: Icon(
                    calculo.modo == 'simple' ? Icons.speed : Icons.analytics,
                    color: calculo.modo == 'simple' ? AppTheme.successColor : AppTheme.infoColor,
                  ),
                  title: Text(calculo.producto.nombre),
                  subtitle: Text(
                    '${calculo.modo.toUpperCase()} - \$${calculo.precioCalculado.precioSugerido.toStringAsFixed(2)}',
                  ),
                  trailing: Text(
                    '${calculo.fechaCalculo.day}/${calculo.fechaCalculo.month}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _mostrarDetallesCalculo(calculo);
                  },
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando historial: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _mostrarDetallesCalculo(CalculoHistorico calculo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles: ${calculo.producto.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetalleItem('Modo', calculo.modo.toUpperCase()),
              _buildDetalleItem('Categoría', calculo.producto.categoria),
              _buildDetalleItem('Talla', calculo.producto.talla),
              _buildDetalleItem('Stock', calculo.producto.stock.toString()),
              _buildDetalleItem('Precio Sugerido', '\$${calculo.precioCalculado.precioSugerido.toStringAsFixed(2)}'),
              _buildDetalleItem('Costo Total', '\$${calculo.precioCalculado.costoTotal.toStringAsFixed(2)}'),
              _buildDetalleItem('Margen', '${calculo.precioCalculado.margenGanancia.toStringAsFixed(1)}%'),
              _buildDetalleItem('Ganancia Neta', '\$${calculo.precioCalculado.gananciaNeta.toStringAsFixed(2)}'),
              _buildDetalleItem('Confianza IA', '${(calculo.precioCalculado.confianzaIA * 100).toStringAsFixed(0)}%'),
              _buildDetalleItem('Fecha', '${calculo.fechaCalculo.day}/${calculo.fechaCalculo.month}/${calculo.fechaCalculo.year}'),
              _buildDetalleItem('Guardado', calculo.fueGuardado ? 'Sí' : 'No'),
            ],
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

  Widget _buildDetalleItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
