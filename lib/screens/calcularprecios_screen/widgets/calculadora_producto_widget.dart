import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../widgets/animated_widgets.dart';
import '../services/calculadora_service.dart';
import '../models/producto_calculo.dart';

/// Widget para la información del producto
class CalculadoraProductoWidget extends StatefulWidget {
  final CalculadoraService calculadoraService;
  final VoidCallback onProductoChanged;

  const CalculadoraProductoWidget({
    super.key,
    required this.calculadoraService,
    required this.onProductoChanged,
  });

  @override
  State<CalculadoraProductoWidget> createState() => _CalculadoraProductoWidgetState();
}

class _CalculadoraProductoWidgetState extends State<CalculadoraProductoWidget> {
  late ProductoCalculo _producto;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _producto = widget.calculadoraService.currentState?.producto ?? ProductoCalculo.empty();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.calculadoraService.currentState;
    if (state == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del paso
            _buildStepHeader(),
            const SizedBox(height: 24),
            
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información básica
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    
                    // Precio (solo modo simple)
                    if (!state.config.modoAvanzado) ...[
                      _buildPriceSection(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Información adicional
                    _buildAdditionalInfo(),
                  ],
                ),
              ),
            ),
            
            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    final state = widget.calculadoraService.currentState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const FaIcon(
                FontAwesomeIcons.boxesStacked,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Información del Producto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          state?.config.modoAvanzado == true
              ? 'Completa la información básica de tu producto'
              : 'Completa la información y define el precio de venta',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return AnimatedCard(
      delay: const Duration(milliseconds: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Básica',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Nombre del Producto',
                  hint: 'Ej: Body de algodón',
                  value: _producto.nombre,
                  onChanged: (value) => _updateProducto(nombre: value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Categoría',
                  value: _producto.categoria,
                  items: ProductoCalculo.getCategoriasPorTipo(_producto.tipoNegocio),
                  onChanged: (value) => _updateProducto(categoria: value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  label: 'Talla',
                  value: _producto.talla,
                  items: ProductoCalculo.getTallasPorTipo(_producto.tipoNegocio),
                  onChanged: (value) => _updateProducto(talla: value ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  label: 'Stock',
                  hint: '1',
                  value: _producto.stock.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final stock = int.tryParse(value);
                    if (stock != null) {
                      _updateProducto(stock: stock);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'El stock es obligatorio';
                    }
                    final stock = int.tryParse(value);
                    if (stock == null || stock <= 0) {
                      return 'El stock debe ser mayor a 0';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection() {
    return AnimatedCard(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Precio de Venta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa el precio al que deseas vender este producto',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Precio de Venta',
            hint: '0.00',
            value: _producto.precioVenta?.toString() ?? '',
            keyboardType: TextInputType.number,
            prefix: const Text('\$ '),
            onChanged: (value) {
              final precio = double.tryParse(value);
              _updateProducto(precioVenta: precio);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El precio es obligatorio';
              }
              final precio = double.tryParse(value);
              if (precio == null || precio <= 0) {
                return 'El precio debe ser mayor a 0';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return AnimatedCard(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información Adicional',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Descripción (Opcional)',
            hint: 'Describe tu producto...',
            value: _producto.descripcion,
            maxLines: 3,
            onChanged: (value) => _updateProducto(descripcion: value),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? prefix,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefix: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedButton(
          text: 'Anterior',
          type: ButtonType.secondary,
          onPressed: _canGoBack() ? _goBack : null,
          icon: FontAwesomeIcons.arrowLeft,
          delay: const Duration(milliseconds: 200),
        ),
        AnimatedButton(
          text: 'Continuar',
          type: ButtonType.primary,
          onPressed: _canContinue() ? _continue : null,
          icon: FontAwesomeIcons.arrowRight,
          delay: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  bool _canGoBack() {
    return widget.calculadoraService.currentState?.canGoToPreviousStep() ?? false;
  }

  bool _canContinue() {
    final state = widget.calculadoraService.currentState;
    if (state == null) return false;
    
    if (state.config.modoAvanzado) {
      return _producto.isValid;
    } else {
      return _producto.isValidSimple;
    }
  }

  Future<void> _updateProducto({
    String? nombre,
    String? descripcion,
    String? categoria,
    String? talla,
    int? stock,
    double? precioVenta,
  }) async {
    setState(() {
      _producto = _producto.copyWith(
        nombre: nombre,
        descripcion: descripcion,
        categoria: categoria,
        talla: talla,
        stock: stock,
        precioVenta: precioVenta,
      );
    });

    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.calculadoraService.updateProducto(_producto);
      widget.onProductoChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error actualizando producto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _goBack() async {
    await widget.calculadoraService.previousStep();
    widget.onProductoChanged();
  }

  Future<void> _continue() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_canContinue()) {
        await widget.calculadoraService.nextStep();
        widget.onProductoChanged();
      }
    }
  }
}
