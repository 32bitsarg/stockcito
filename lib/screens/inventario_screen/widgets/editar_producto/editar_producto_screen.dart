import 'package:flutter/material.dart';
import '../../../../config/app_theme.dart';
import '../../../../models/producto.dart';
import '../../../../services/datos/datos.dart';

// Importar widgets refactorizados
import 'editar_producto_header.dart';
import 'editar_producto_formulario.dart';
import 'editar_producto_panel_resultados.dart';

// Importar funciones
import '../../functions/editar_producto_functions.dart';

class EditarProductoScreen extends StatefulWidget {
  final Producto producto;
  final bool showCloseButton;
  
  const EditarProductoScreen({
    super.key,
    required this.producto,
    this.showCloseButton = false,
  });

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatosService _datosService = DatosService();
  
  // Controladores para los campos
  final _nombreController = TextEditingController();
  final _costoMaterialesController = TextEditingController();
  final _costoManoObraController = TextEditingController();
  final _gastosGeneralesController = TextEditingController();
  final _margenGananciaController = TextEditingController();
  final _stockController = TextEditingController();

  String _categoriaSeleccionada = 'Bodies';
  String _tallaSeleccionada = '0-3 meses';
  double _iva = 21.0;

  @override
  void initState() {
    super.initState();
    _cargarDatosProducto();
  }

  void _cargarDatosProducto() {
    EditarProductoFunctions.cargarDatosProducto(
      producto: widget.producto,
      nombreController: _nombreController,
      costoMaterialesController: _costoMaterialesController,
      costoManoObraController: _costoManoObraController,
      gastosGeneralesController: _gastosGeneralesController,
      margenGananciaController: _margenGananciaController,
      stockController: _stockController,
      onCategoriaChanged: (categoria) => setState(() => _categoriaSeleccionada = categoria),
      onTallaChanged: (talla) => setState(() => _tallaSeleccionada = talla),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _costoMaterialesController.dispose();
    _costoManoObraController.dispose();
    _gastosGeneralesController.dispose();
    _margenGananciaController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  double get _costoTotal {
    final materiales = double.tryParse(_costoMaterialesController.text) ?? 0;
    final manoObra = double.tryParse(_costoManoObraController.text) ?? 0;
    final gastosGenerales = double.tryParse(_gastosGeneralesController.text) ?? 0;
    return EditarProductoFunctions.calcularCostoTotal(
      materiales: materiales,
      manoObra: manoObra,
      gastosGenerales: gastosGenerales,
    );
  }

  double get _precioVenta {
    final margen = double.tryParse(_margenGananciaController.text) ?? 0;
    return EditarProductoFunctions.calcularPrecioVenta(
      costoTotal: _costoTotal,
      margenGanancia: margen,
    );
  }

  double get _precioConIVA {
    return EditarProductoFunctions.calcularPrecioConIVA(
      precioVenta: _precioVenta,
      iva: _iva,
    );
  }

  double get _gananciaNeta {
    return EditarProductoFunctions.calcularGananciaNeta(
      precioVenta: _precioVenta,
      costoTotal: _costoTotal,
    );
  }

  double get _porcentajeMargen {
    return EditarProductoFunctions.calcularPorcentajeMargen(
      gananciaNeta: _gananciaNeta,
      costoTotal: _costoTotal,
    );
  }

  void _calcularPrecios() {
    setState(() {});
  }

  Future<void> _actualizarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final productoActualizado = EditarProductoFunctions.crearProductoActualizado(
        productoOriginal: widget.producto,
        nombre: _nombreController.text,
        categoria: _categoriaSeleccionada,
        talla: _tallaSeleccionada,
        costoMateriales: double.parse(_costoMaterialesController.text),
        costoManoObra: double.parse(_costoManoObraController.text),
        gastosGenerales: double.parse(_gastosGeneralesController.text),
        margenGanancia: double.parse(_margenGananciaController.text),
        stock: int.parse(_stockController.text),
      );

      await _datosService.updateProducto(productoActualizado);

      if (mounted) {
        EditarProductoFunctions.showSuccessSnackBar(
          context, 
          EditarProductoFunctions.getActualizacionSuccessText()
        );
        
        // Si se muestra como modal, cerrar después de actualizar
        if (widget.showCloseButton) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        EditarProductoFunctions.showErrorSnackBar(
          context, 
          EditarProductoFunctions.getActualizacionErrorText(e.toString())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header con botón cerrar si es modal
          if (widget.showCloseButton) 
            EditarProductoHeader(onCerrar: () => Navigator.of(context).pop()),
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formulario principal
                    Expanded(
                      flex: 2,
                      child: EditarProductoFormulario(
                        nombreController: _nombreController,
                        costoMaterialesController: _costoMaterialesController,
                        costoManoObraController: _costoManoObraController,
                        gastosGeneralesController: _gastosGeneralesController,
                        margenGananciaController: _margenGananciaController,
                        stockController: _stockController,
                        categoriaSeleccionada: _categoriaSeleccionada,
                        tallaSeleccionada: _tallaSeleccionada,
                        iva: _iva,
                        onCategoriaChanged: (categoria) => setState(() => _categoriaSeleccionada = categoria),
                        onTallaChanged: (talla) => setState(() => _tallaSeleccionada = talla),
                        onIVAChanged: (iva) => setState(() => _iva = iva),
                        onCalcularPrecios: _calcularPrecios,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Panel de resultados
                    Expanded(
                      flex: 1,
                      child: EditarProductoPanelResultados(
                        costoTotal: _costoTotal,
                        precioVenta: _precioVenta,
                        precioConIVA: _precioConIVA,
                        gananciaNeta: _gananciaNeta,
                        porcentajeMargen: _porcentajeMargen,
                        onActualizarProducto: _actualizarProducto,
                        onRecalcular: _calcularPrecios,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
