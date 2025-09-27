import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';
import '../../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import '../../../services/ui/calculadora/modo_avanzado_service.dart';
import '../../../services/ui/calculadora/calculadora_validation_service.dart';
import '../../../services/ui/calculadora/calculadora_pricing_service.dart';

/// Widget para el formulario del modo avanzado
class CalculadoraModoAvanzadoFormWidget extends StatefulWidget {
  final CalculadoraConfig config;
  final Function(ResultadoModoAvanzado) onResultado;

  const CalculadoraModoAvanzadoFormWidget({
    Key? key,
    required this.config,
    required this.onResultado,
  }) : super(key: key);

  @override
  State<CalculadoraModoAvanzadoFormWidget> createState() => _CalculadoraModoAvanzadoFormWidgetState();
}

class _CalculadoraModoAvanzadoFormWidgetState extends State<CalculadoraModoAvanzadoFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _categoriaController = TextEditingController();
  final _tallaController = TextEditingController();
  final _stockController = TextEditingController();
  final _descripcionController = TextEditingController();

  final ModoAvanzadoService _modoAvanzadoService = ModoAvanzadoService();
  final CalculadoraValidationService _validationService = CalculadoraValidationService();

  bool _isLoading = false;
  ValidacionResultado? _validacionResultado;
  
  // Datos del producto
  ProductoCalculo _producto = ProductoCalculo.empty();
  List<CostoDirecto> _costosDirectos = [];
  List<CostoIndirecto> _costosIndirectos = [];
  
  // Resultados del cálculo
  PrecioCalculado? _precioCalculado;

  @override
  void initState() {
    super.initState();
    _categoriaController.text = 'General';
    _tallaController.text = 'Única';
    _stockController.text = '1';
    _actualizarProducto();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _tallaController.dispose();
    _stockController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del formulario
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppTheme.infoColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Avanzado',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Análisis completo con IA y optimización de costos',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Información del producto
          _buildSeccionProducto(),
          const SizedBox(height: 20),
          
          // Costos directos
          _buildSeccionCostosDirectos(),
          const SizedBox(height: 20),
          
          // Costos indirectos
          _buildSeccionCostosIndirectos(),
          const SizedBox(height: 20),
          
          // Validaciones
          if (_validacionResultado != null) ...[
            _buildValidaciones(),
            const SizedBox(height: 20),
          ],
          
          // Resultados del cálculo
          if (_precioCalculado != null) ...[
            _buildResultadosCalculo(),
            const SizedBox(height: 20),
          ],
          
          // Botones
          _buildBotones(),
        ],
      ),
    );
  }

  Widget _buildSeccionProducto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información del Producto',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Camiseta de algodón',
                  prefixIcon: const Icon(Icons.inventory_2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
                onChanged: (_) => _actualizarProducto(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _categoriaController.text,
                decoration: InputDecoration(
                  labelText: 'Categoría *',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _getCategorias().map((categoria) {
                  return DropdownMenuItem(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoriaController.text = value ?? 'General';
                  });
                  _actualizarProducto();
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tallaController,
                decoration: InputDecoration(
                  labelText: 'Talla *',
                  hintText: 'Ej: M, L, XL',
                  prefixIcon: const Icon(Icons.straighten),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La talla es requerida';
                  }
                  return null;
                },
                onChanged: (_) => _actualizarProducto(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Stock *',
                  hintText: 'Ej: 10',
                  prefixIcon: const Icon(Icons.inventory),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El stock es requerido';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock <= 0) {
                    return 'El stock debe ser mayor a 0';
                  }
                  return null;
                },
                onChanged: (_) => _actualizarProducto(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _descripcionController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Descripción',
            hintText: 'Describe las características del producto...',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (_) => _actualizarProducto(),
        ),
      ],
    );
  }

  Widget _buildSeccionCostosDirectos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Costos Directos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _agregarCostoDirecto,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.successColor.withOpacity(0.1),
                foregroundColor: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_costosDirectos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Agrega al menos un costo directo (materiales, mano de obra, etc.)',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          )
        else
          ..._costosDirectos.asMap().entries.map((entry) {
            final index = entry.key;
            final costo = entry.value;
            return _buildCostoDirectoCard(index, costo);
          }),
      ],
    );
  }

  Widget _buildSeccionCostosIndirectos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Costos Indirectos (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _agregarCostoIndirecto,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.infoColor.withOpacity(0.1),
                foregroundColor: AppTheme.infoColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_costosIndirectos.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Agrega costos indirectos como alquiler, marketing, servicios, etc.',
                    style: TextStyle(color: AppTheme.infoColor),
                  ),
                ),
              ],
            ),
          )
        else
          ..._costosIndirectos.asMap().entries.map((entry) {
            final index = entry.key;
            final costo = entry.value;
            return _buildCostoIndirectoCard(index, costo);
          }),
      ],
    );
  }

  Widget _buildCostoDirectoCard(int index, CostoDirecto costo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  costo.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${costo.cantidad} ${costo.unidad} × \$${costo.precioUnitario.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Total: \$${costo.costoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _eliminarCostoDirecto(index),
            icon: const Icon(Icons.delete),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCostoIndirectoCard(int index, CostoIndirecto costo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  costo.nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${costo.costoMensual.toStringAsFixed(2)}/mes ÷ ${costo.productosEstimadosMensuales} productos',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  'Por producto: \$${costo.costoPorProducto.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.infoColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _eliminarCostoIndirecto(index),
            icon: const Icon(Icons.delete),
            color: AppTheme.errorColor,
          ),
        ],
      ),
    );
  }

  Widget _buildValidaciones() {
    if (_validacionResultado == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _validacionResultado!.esValido 
            ? AppTheme.successColor.withOpacity(0.1)
            : AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _validacionResultado!.esValido 
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.errorColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _validacionResultado!.esValido ? Icons.check_circle : Icons.error,
                color: _validacionResultado!.esValido ? AppTheme.successColor : AppTheme.errorColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _validacionResultado!.esValido ? 'Datos válidos para cálculo' : 'Revisar datos',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _validacionResultado!.esValido ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
            ],
          ),
          
          if (_validacionResultado!.errores.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.errores.values.map((error) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '• $error',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.errorColor,
                ),
              ),
            )),
          ],
          
          if (_validacionResultado!.advertencias.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.advertencias.values.map((advertencia) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '⚠ $advertencia',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.warningColor,
                ),
              ),
            )),
          ],
          
          if (_validacionResultado!.sugerencias.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._validacionResultado!.sugerencias.map((sugerencia) => Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 4),
              child: Text(
                '💡 $sugerencia',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.infoColor,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildResultadosCalculo() {
    if (_precioCalculado == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Resultado del Cálculo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildResultadoItem(
                  'Precio Sugerido',
                  '\$${_precioCalculado!.precioSugerido.toStringAsFixed(2)}',
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildResultadoItem(
                  'Costo Total',
                  '\$${_precioCalculado!.costoTotal.toStringAsFixed(2)}',
                  AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildResultadoItem(
                  'Margen',
                  '${_precioCalculado!.margenGanancia.toStringAsFixed(1)}%',
                  AppTheme.successColor,
                ),
              ),
              Expanded(
                child: _buildResultadoItem(
                  'Ganancia Neta',
                  '\$${_precioCalculado!.gananciaNeta.toStringAsFixed(2)}',
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildResultadoItem(
                  'Confianza IA',
                  '${(_precioCalculado!.confianzaIA * 100).toStringAsFixed(0)}%',
                  AppTheme.infoColor,
                ),
              ),
              Expanded(
                child: _buildResultadoItem(
                  'IVA',
                  '${_precioCalculado!.iva.toStringAsFixed(1)}%',
                  AppTheme.warningColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBotones() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _calcularPrecio,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.calculate),
            label: Text(_isLoading ? 'Calculando...' : 'Calcular Precio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: (_isLoading || _precioCalculado == null) ? null : _guardarProducto,
            icon: const Icon(Icons.save),
            label: const Text('Guardar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<String> _getCategorias() {
    return [
      'General',
      'Camiseta',
      'Pantalón',
      'Vestido',
      'Chaqueta',
      'Zapatos',
      'Accesorios',
      'Ropa Interior',
      'Deportiva',
    ];
  }

  void _actualizarProducto() {
    setState(() {
      _producto = ProductoCalculo(
        nombre: _nombreController.text,
        categoria: _categoriaController.text,
        talla: _tallaController.text,
        stock: int.tryParse(_stockController.text) ?? 1,
        descripcion: _descripcionController.text,
        tipoNegocio: widget.config.tipoNegocio,
        fechaCreacion: DateTime.now(),
      );
    });
    _validarDatos();
  }

  void _validarDatos() {
    if (_producto.nombre.isNotEmpty && _costosDirectos.isNotEmpty) {
      setState(() {
        _validacionResultado = _validationService.validarModoAvanzado(
          producto: _producto,
          costosDirectos: _costosDirectos,
          costosIndirectos: _costosIndirectos,
          config: widget.config,
        );
      });
    }
  }

  void _agregarCostoDirecto() {
    showDialog(
      context: context,
      builder: (context) => _CostoDirectoDialog(
        onCostoAgregado: (costo) {
          setState(() {
            _costosDirectos.add(costo);
          });
          _validarDatos();
        },
      ),
    );
  }

  void _agregarCostoIndirecto() {
    showDialog(
      context: context,
      builder: (context) => _CostoIndirectoDialog(
        onCostoAgregado: (costo) {
          setState(() {
            _costosIndirectos.add(costo);
          });
          _validarDatos();
        },
      ),
    );
  }

  void _eliminarCostoDirecto(int index) {
    setState(() {
      _costosDirectos.removeAt(index);
    });
    _validarDatos();
  }

  void _eliminarCostoIndirecto(int index) {
    setState(() {
      _costosIndirectos.removeAt(index);
    });
    _validarDatos();
  }

  Future<void> _calcularPrecio() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _modoAvanzadoService.calcularPrecioAvanzado(
        producto: _producto,
        costosDirectos: _costosDirectos,
        costosIndirectos: _costosIndirectos,
        config: widget.config,
      );

      if (resultado.exito) {
        setState(() {
          _precioCalculado = resultado.precioCalculado;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Precio calculado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Error calculando precio'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarProducto() async {
    if (_precioCalculado == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await _modoAvanzadoService.guardarProductoAvanzado(
        producto: _producto,
        precioCalculado: _precioCalculado!,
        costosDirectos: _costosDirectos,
        costosIndirectos: _costosIndirectos,
      );

      widget.onResultado(resultado);

      if (resultado.exito) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Producto guardado exitosamente'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado.mensaje ?? 'Error guardando producto'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Dialog para agregar costo directo
class _CostoDirectoDialog extends StatefulWidget {
  final Function(CostoDirecto) onCostoAgregado;

  const _CostoDirectoDialog({required this.onCostoAgregado});

  @override
  State<_CostoDirectoDialog> createState() => _CostoDirectoDialogState();
}

class _CostoDirectoDialogState extends State<_CostoDirectoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _desperdicioController = TextEditingController();
  
  String _tipoSeleccionado = 'material';
  String _unidadSeleccionada = 'unidad';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Costo Directo'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Tela de algodón',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                items: CostoDirecto.getTiposDisponibles().map<DropdownMenuItem<String>>((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['id'] as String,
                    child: Text('${tipo['icono']} ${tipo['nombre']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value ?? 'material';
                    _unidadSeleccionada = CostoDirecto.getUnidadesPorTipo(_tipoSeleccionado).first;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad *',
                        hintText: '1',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Cantidad requerida';
                        }
                        final cantidad = double.tryParse(value);
                        if (cantidad == null || cantidad <= 0) {
                          return 'Cantidad inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidadSeleccionada,
                      decoration: const InputDecoration(labelText: 'Unidad'),
                      items: CostoDirecto.getUnidadesPorTipo(_tipoSeleccionado).map((unidad) {
                        return DropdownMenuItem(
                          value: unidad,
                          child: Text(unidad),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _unidadSeleccionada = value ?? 'unidad';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio Unitario *',
                  hintText: '10.50',
                  prefixText: '\$',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Precio requerido';
                  }
                  final precio = double.tryParse(value);
                  if (precio == null || precio <= 0) {
                    return 'Precio inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _desperdicioController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Desperdicio (%)',
                  hintText: '5',
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final desperdicio = double.tryParse(value);
                    if (desperdicio == null || desperdicio < 0) {
                      return 'Desperdicio inválido';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _agregarCosto,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _agregarCosto() {
    if (!_formKey.currentState!.validate()) return;

    final costo = CostoDirecto.nuevo(
      nombre: _nombreController.text,
      tipo: _tipoSeleccionado,
      cantidad: double.parse(_cantidadController.text),
      unidad: _unidadSeleccionada,
      precioUnitario: double.parse(_precioController.text),
      desperdicio: double.tryParse(_desperdicioController.text) ?? 0.0,
    );

    widget.onCostoAgregado(costo);
    Navigator.of(context).pop();
  }
}

/// Dialog para agregar costo indirecto
class _CostoIndirectoDialog extends StatefulWidget {
  final Function(CostoIndirecto) onCostoAgregado;

  const _CostoIndirectoDialog({required this.onCostoAgregado});

  @override
  State<_CostoIndirectoDialog> createState() => _CostoIndirectoDialogState();
}

class _CostoIndirectoDialogState extends State<_CostoIndirectoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _costoController = TextEditingController();
  final _productosController = TextEditingController();
  
  String _tipoSeleccionado = 'alquiler';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Costo Indirecto'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Alquiler del local',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _tipoSeleccionado,
                decoration: const InputDecoration(labelText: 'Tipo *'),
                items: CostoIndirecto.getTiposDisponibles().map<DropdownMenuItem<String>>((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo['id'] as String,
                    child: Text('${tipo['icono']} ${tipo['nombre']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSeleccionado = value ?? 'alquiler';
                  });
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _costoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Costo Mensual *',
                  hintText: '500',
                  prefixText: '\$',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Costo requerido';
                  }
                  final costo = double.tryParse(value);
                  if (costo == null || costo <= 0) {
                    return 'Costo inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _productosController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Productos Estimados/Mes *',
                  hintText: '100',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cantidad requerida';
                  }
                  final cantidad = int.tryParse(value);
                  if (cantidad == null || cantidad <= 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _agregarCosto,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _agregarCosto() {
    if (!_formKey.currentState!.validate()) return;

    final costo = CostoIndirecto.nuevo(
      nombre: _nombreController.text,
      tipo: _tipoSeleccionado,
      costoMensual: double.parse(_costoController.text),
      productosEstimadosMensuales: int.parse(_productosController.text),
    );

    widget.onCostoAgregado(costo);
    Navigator.of(context).pop();
  }
}
