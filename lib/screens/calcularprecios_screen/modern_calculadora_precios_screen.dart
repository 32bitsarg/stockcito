import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../../../services/datos/datos.dart';
import '../../../services/datos/dashboard_service.dart';
import '../../../models/producto.dart';
import 'services/calculadora_service.dart';
import 'widgets/calculadora_header.dart';
import 'widgets/calculadora_stepper.dart';
import 'widgets/calculadora_config_widget.dart';
import 'widgets/calculadora_producto_widget.dart';
import 'widgets/calculadora_costos_directos_widget.dart';
import 'widgets/calculadora_costos_indirectos_widget.dart';
import 'widgets/calculadora_resultado_widget.dart';

/// Pantalla principal de la nueva calculadora de precios
class ModernCalculadoraPreciosScreen extends StatefulWidget {
  final bool showCloseButton;
  
  const ModernCalculadoraPreciosScreen({
    super.key,
    this.showCloseButton = false,
  });

  @override
  State<ModernCalculadoraPreciosScreen> createState() => _ModernCalculadoraPreciosScreenState();
}

class _ModernCalculadoraPreciosScreenState extends State<ModernCalculadoraPreciosScreen> {
  final CalculadoraService _calculadoraService = CalculadoraService();
  final DatosService _datosService = DatosService();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _calculadoraService.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header con configuración
          CalculadoraHeader(
            onClose: widget.showCloseButton ? () => Navigator.pop(context) : null,
          ),
          
          // Contenido principal
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Stepper vertical
                  CalculadoraStepper(
                    calculadoraService: _calculadoraService,
                    onStepChanged: (step) {
                      _calculadoraService.goToStep(step);
                      setState(() {});
                    },
                  ),
                  
                  // Contenido del paso actual
                  Expanded(
                    child: _buildStepContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    final state = _calculadoraService.currentState;
    if (state == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (state.pasoActual) {
      case 0:
        return CalculadoraConfigWidget(
          calculadoraService: _calculadoraService,
          onConfigChanged: () => setState(() {}),
        );
      case 1:
        return CalculadoraProductoWidget(
          calculadoraService: _calculadoraService,
          onProductoChanged: () => setState(() {}),
        );
      case 2:
        if (state.config.modoAvanzado) {
          return CalculadoraCostosDirectosWidget(
            calculadoraService: _calculadoraService,
            onCostosChanged: () => setState(() {}),
          );
        } else {
          return CalculadoraResultadoWidget(
            calculadoraService: _calculadoraService,
            onGuardar: _guardarProducto,
            onNuevo: _nuevoCalculo,
          );
        }
      case 3:
        if (state.config.modoAvanzado) {
          return CalculadoraCostosIndirectosWidget(
            calculadoraService: _calculadoraService,
            onCostosChanged: () => setState(() {}),
          );
        } else {
          return CalculadoraResultadoWidget(
            calculadoraService: _calculadoraService,
            onGuardar: _guardarProducto,
            onNuevo: _nuevoCalculo,
          );
        }
      case 4:
        return CalculadoraResultadoWidget(
          calculadoraService: _calculadoraService,
          onGuardar: _guardarProducto,
          onNuevo: _nuevoCalculo,
        );
      default:
        return const Center(child: Text('Paso no válido'));
    }
  }

  Future<void> _guardarProducto() async {
    try {
      final state = _calculadoraService.currentState;
      if (state == null || !state.isComplete) return;

      // Crear el producto para guardar
      final producto = Producto(
        nombre: state.producto.nombre,
        categoria: state.producto.categoria,
        talla: state.producto.talla,
        costoMateriales: state.totalCostosDirectos,
        costoManoObra: 0.0, // Se calcula en costos directos
        gastosGenerales: state.totalCostosIndirectos,
        margenGanancia: state.config.margenGananciaDefault,
        stock: state.producto.stock,
        fechaCreacion: DateTime.now(),
      );

      // Guardar producto
      final guardadoExitoso = await _datosService.saveProducto(producto);
      
      if (guardadoExitoso) {
        // Actualizar dashboard
        if (mounted) {
          context.read<DashboardService>().cargarDatos();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Producto guardado exitosamente'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Limpiar calculadora
          await _nuevoCalculo();
        }
      } else {
        throw Exception('Error guardando el producto');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  Future<void> _nuevoCalculo() async {
    await _calculadoraService.clearState();
    setState(() {});
  }
}
