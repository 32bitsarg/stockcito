import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/database_service.dart';
import '../config/app_theme.dart';
import '../widgets/windows_button.dart';

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
  final DatabaseService _databaseService = DatabaseService();
  
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

  final List<String> _categorias = [
    'Bodies',
    'Conjuntos',
    'Vestidos',
    'Pijamas',
    'Gorros',
    'Accesorios',
  ];

  final List<String> _tallas = [
    '0-3 meses',
    '3-6 meses',
    '6-12 meses',
    '12-18 meses',
    '18-24 meses',
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatosProducto();
  }

  void _cargarDatosProducto() {
    final producto = widget.producto;
    _nombreController.text = producto.nombre;
    _costoMaterialesController.text = producto.costoMateriales.toString();
    _costoManoObraController.text = producto.costoManoObra.toString();
    _gastosGeneralesController.text = producto.gastosGenerales.toString();
    _margenGananciaController.text = producto.margenGanancia.toString();
    _stockController.text = producto.stock.toString();
    _categoriaSeleccionada = producto.categoria;
    _tallaSeleccionada = producto.talla;
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
    return materiales + manoObra + gastosGenerales;
  }

  double get _precioVenta {
    final margen = double.tryParse(_margenGananciaController.text) ?? 0;
    return _costoTotal * (1 + margen / 100);
  }

  double get _precioConIVA {
    return _precioVenta * (1 + _iva / 100);
  }

  void _calcularPrecios() {
    setState(() {});
  }

  Future<void> _actualizarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final productoActualizado = Producto(
        id: widget.producto.id,
        nombre: _nombreController.text,
        categoria: _categoriaSeleccionada,
        talla: _tallaSeleccionada,
        costoMateriales: double.parse(_costoMaterialesController.text),
        costoManoObra: double.parse(_costoManoObraController.text),
        gastosGenerales: double.parse(_gastosGeneralesController.text),
        margenGanancia: double.parse(_margenGananciaController.text),
        stock: int.parse(_stockController.text),
        fechaCreacion: widget.producto.fechaCreacion, // Mantener fecha original
      );

      await _databaseService.updateProducto(productoActualizado);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Producto actualizado exitosamente'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        
        // Si se muestra como modal, cerrar después de actualizar
        if (widget.showCloseButton) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
          if (widget.showCloseButton) _buildHeaderWithClose(),
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
                      child: _buildFormulario(),
                    ),
                    const SizedBox(width: 24),
                    // Panel de resultados
                    Expanded(
                      flex: 1,
                      child: _buildPanelResultados(),
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

  Widget _buildHeaderWithClose() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Editar Producto',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Modifica la información y stock del producto',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Botón cerrar
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información del producto
        _buildSeccion(
          titulo: 'Información del Producto',
          icono: Icons.info_outline,
          color: AppTheme.primaryColor,
          children: [
            _buildTextField(
              controller: _nombreController,
              label: 'Nombre del producto',
              hint: 'Ej: Body de algodón',
              icon: Icons.shopping_bag,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el nombre del producto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    value: _categoriaSeleccionada,
                    items: _categorias,
                    label: 'Categoría',
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        _categoriaSeleccionada = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    value: _tallaSeleccionada,
                    items: _tallas,
                    label: 'Talla',
                    icon: Icons.straighten,
                    onChanged: (value) {
                      setState(() {
                        _tallaSeleccionada = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Costos
        _buildSeccion(
          titulo: 'Análisis de Costos',
          icono: Icons.attach_money,
          color: AppTheme.secondaryColor,
          children: [
            _buildTextField(
              controller: _costoMaterialesController,
              label: 'Costo de materiales',
              hint: '0.00',
              icon: Icons.inventory,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularPrecios(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el costo de materiales';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _costoManoObraController,
              label: 'Costo de mano de obra',
              hint: '0.00',
              icon: Icons.work,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularPrecios(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el costo de mano de obra';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _gastosGeneralesController,
              label: 'Gastos generales',
              hint: '0.00',
              icon: Icons.business,
              keyboardType: TextInputType.number,
              onChanged: (_) => _calcularPrecios(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa los gastos generales';
                }
                if (double.tryParse(value) == null) {
                  return 'Ingresa un número válido';
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Configuración
        _buildSeccion(
          titulo: 'Configuración de Precios y Stock',
          icono: Icons.settings,
          color: AppTheme.accentColor,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _margenGananciaController,
                    label: 'Margen de ganancia (%)',
                    hint: '50',
                    icon: Icons.trending_up,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calcularPrecios(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa el margen';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _stockController,
                    label: 'Stock disponible',
                    hint: '1',
                    icon: Icons.inventory_2,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa el stock';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Ingresa un número válido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSlider(
              value: _iva,
              min: 0,
              max: 30,
              divisions: 30,
              label: 'IVA: ${_iva.toStringAsFixed(0)}%',
              onChanged: (value) {
                setState(() {
                  _iva = value;
                });
                _calcularPrecios();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPanelResultados() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Resultados',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildResultadoItem(
            'Costo Total',
            '\$${_costoTotal.toStringAsFixed(2)}',
            AppTheme.textSecondary,
            Icons.receipt,
          ),
          const SizedBox(height: 16),
          _buildResultadoItem(
            'Precio de Venta',
            '\$${_precioVenta.toStringAsFixed(2)}',
            AppTheme.primaryColor,
            Icons.sell,
          ),
          const SizedBox(height: 16),
          _buildResultadoItem(
            'Precio con IVA',
            '\$${_precioConIVA.toStringAsFixed(2)}',
            AppTheme.successColor,
            Icons.payment,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Ganancia Neta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${(_precioVenta - _costoTotal).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((_precioVenta - _costoTotal) / _costoTotal * 100).toStringAsFixed(1)}% de margen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Botones de acción
          Column(
            children: [
              // Botón principal - Actualizar
              SizedBox(
                width: double.infinity,
                child: WindowsButton(
                  text: 'Actualizar Producto',
                  type: ButtonType.primary,
                  onPressed: _actualizarProducto,
                  icon: Icons.save,
                ),
              ),
              const SizedBox(height: 12),
              // Botones secundarios
              Row(
                children: [
                  Expanded(
                    child: WindowsButton(
                      text: 'Recalcular',
                      type: ButtonType.secondary,
                      onPressed: _calcularPrecios,
                      icon: Icons.refresh,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion({
    required String titulo,
    required IconData icono,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icono,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  Widget _buildSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.borderColor,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildResultadoItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
