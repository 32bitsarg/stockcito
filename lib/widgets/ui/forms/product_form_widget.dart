import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/producto.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';

/// Widget de formulario para productos
class ProductFormWidget extends StatefulWidget {
  final Producto? product;
  final List<Categoria> categories;
  final List<Talla> sizes;
  final Function(Producto) onSave;

  const ProductFormWidget({
    super.key,
    this.product,
    required this.categories,
    required this.sizes,
    required this.onSave,
  });

  @override
  State<ProductFormWidget> createState() => _ProductFormWidgetState();
}

class _ProductFormWidgetState extends State<ProductFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _costoController = TextEditingController();
  final _stockController = TextEditingController();
  final _stockMinimoController = TextEditingController();

  String _selectedCategory = '';
  String _selectedSize = '';

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.product != null) {
      final product = widget.product!;
      _nombreController.text = product.nombre;
      _descripcionController.text = ''; // Producto no tiene descripción
      _precioController.text = product.precioVenta.toStringAsFixed(2);
      _costoController.text = product.costoTotal.toStringAsFixed(2);
      _stockController.text = product.stock.toString();
      _stockMinimoController.text = '5'; // Valor por defecto
      _selectedCategory = product.categoria;
      _selectedSize = product.talla;
    } else {
      // Default values for new product
      _stockController.text = '0';
      _stockMinimoController.text = '5';
      
      if (widget.categories.isNotEmpty) {
        _selectedCategory = widget.categories.first.nombre;
      }
      if (widget.sizes.isNotEmpty) {
        _selectedSize = widget.sizes.first.nombre;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _costoController.dispose();
    _stockController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Sección de detalles del producto
            _buildSectionTitle(Icons.info, 'Detalles del Producto'),
            const SizedBox(height: 16),
            
            // Grid de campos principales
            Expanded(
              child: Column(
                children: [
                  // Fila 1: Nombre del producto
                  TextFormField(
                    controller: _nombreController,
                    decoration: _inputDecoration('Nombre del Producto', FontAwesomeIcons.box),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El nombre del producto no puede estar vacío';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila 2: Categoría y Talla
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory.isEmpty && widget.categories.isNotEmpty
                              ? widget.categories.first.nombre
                              : _selectedCategory.isEmpty
                                  ? null
                                  : _selectedCategory,
                          decoration: _inputDecoration('Categoría', FontAwesomeIcons.tags),
                          items: widget.categories.map((categoria) {
                            return DropdownMenuItem(
                              value: categoria.nombre,
                              child: Text(categoria.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona categoría';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSize.isEmpty && widget.sizes.isNotEmpty
                              ? widget.sizes.first.nombre
                              : _selectedSize.isEmpty
                                  ? null
                                  : _selectedSize,
                          decoration: _inputDecoration('Talla', FontAwesomeIcons.ruler),
                          items: widget.sizes.map((talla) {
                            return DropdownMenuItem(
                              value: talla.nombre,
                              child: Text(talla.nombre),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSize = value!;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecciona talla';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Sección de precios y stock
                  _buildSectionTitle(FontAwesomeIcons.dollarSign, 'Precios y Stock'),
                  const SizedBox(height: 16),
                  
                  // Fila 3: Costo y Precio de Venta
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _costoController,
                          decoration: _inputDecoration('Costo', FontAwesomeIcons.moneyBill),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: (value) {
                            if (value == null || value.isEmpty || double.tryParse(value) == null) {
                              return 'Costo inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _precioController,
                          decoration: _inputDecoration('Precio de Venta', FontAwesomeIcons.handHoldingDollar),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                          validator: (value) {
                            if (value == null || value.isEmpty || double.tryParse(value) == null) {
                              return 'Precio inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Fila 4: Stock y Stock Mínimo
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          decoration: _inputDecoration('Stock', FontAwesomeIcons.warehouse),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Stock inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stockMinimoController,
                          decoration: _inputDecoration('Stock Mínimo', FontAwesomeIcons.bell),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty || int.tryParse(value) == null) {
                              return 'Stock mínimo inválido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            _buildActionButton(context),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.grey[200],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        FaIcon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _handleSave,
      icon: Icon(widget.product == null ? Icons.add : Icons.save),
      label: Text(widget.product == null ? 'Crear Producto' : 'Guardar Cambios'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final precio = double.parse(_precioController.text);
      final costoTotal = double.parse(_costoController.text);
      final margenGanancia = ((precio - costoTotal) / costoTotal) * 100;
      
      final product = Producto(
        id: widget.product?.id,
        nombre: _nombreController.text.trim(),
        categoria: _selectedCategory,
        talla: _selectedSize,
        costoMateriales: costoTotal * 0.6, // 60% del costo total
        costoManoObra: costoTotal * 0.3,   // 30% del costo total
        gastosGenerales: costoTotal * 0.1, // 10% del costo total
        margenGanancia: margenGanancia,
        stock: int.parse(_stockController.text),
        fechaCreacion: widget.product?.fechaCreacion ?? DateTime.now(),
      );

      widget.onSave(product);
    }
  }
}