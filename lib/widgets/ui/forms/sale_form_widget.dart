import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/venta.dart';
import '../../../models/cliente.dart';
import '../../../models/producto.dart';

/// Widget de formulario para ventas
class SaleFormWidget extends StatefulWidget {
  final Venta? sale;
  final List<Cliente> clients;
  final List<Producto> products;
  final Function(Venta) onSave;

  const SaleFormWidget({
    super.key,
    this.sale,
    required this.clients,
    required this.products,
    required this.onSave,
  });

  @override
  State<SaleFormWidget> createState() => _SaleFormWidgetState();
}

class _SaleFormWidgetState extends State<SaleFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _clienteController = TextEditingController();
  final _metodoPagoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedEstado = 'Pendiente';
  String _selectedMetodoPago = 'Efectivo';
  List<VentaItem> _items = [];
  double _total = 0.0;
  String _searchQuery = '';

  final List<String> _estados = ['Pendiente', 'Completada', 'Cancelada'];
  final List<String> _metodosPago = ['Efectivo', 'Tarjeta', 'Transferencia'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeForm() {
    if (widget.sale != null) {
      final sale = widget.sale!;
      _clienteController.text = sale.cliente;
      _selectedEstado = sale.estado;
      _selectedMetodoPago = sale.metodoPago;
      _observacionesController.text = sale.notas;
      _items = List.from(sale.items);
      _total = sale.total;
    } else {
      // Default values for new sale
      _selectedEstado = 'Pendiente';
      _selectedMetodoPago = 'Efectivo';
      _items = [];
      _total = 0.0;
    }
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _metodoPagoController.dispose();
    _observacionesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lado izquierdo: Productos disponibles
            Expanded(
              flex: 1,
              child: _buildLeftSide(),
            ),
            const SizedBox(width: 20),
            // Lado derecho: Formulario y productos seleccionados
            Expanded(
              flex: 1,
              child: _buildRightSide(context),
            ),
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

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _calculateTotal();
    });
  }

  void _increaseQuantity(int index) {
    final item = _items[index];
    final product = widget.products.firstWhere((p) => p.id == item.productoId);
    
    // Verificar si se puede aumentar la cantidad sin exceder el stock
    if (item.cantidad >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede agregar más cantidad. Stock disponible: ${product.stock}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _items[index] = VentaItem(
        ventaId: item.ventaId,
        productoId: item.productoId,
        nombreProducto: item.nombreProducto,
        categoria: item.categoria,
        talla: item.talla,
        cantidad: item.cantidad + 1,
        precioUnitario: item.precioUnitario,
        subtotal: (item.cantidad + 1) * item.precioUnitario,
      );
      _calculateTotal();
    });
  }

  void _decreaseQuantity(int index) {
    if (_items[index].cantidad > 1) {
      setState(() {
        _items[index] = VentaItem(
          ventaId: _items[index].ventaId,
          productoId: _items[index].productoId,
          nombreProducto: _items[index].nombreProducto,
          categoria: _items[index].categoria,
          talla: _items[index].talla,
          cantidad: _items[index].cantidad - 1,
          precioUnitario: _items[index].precioUnitario,
          subtotal: (_items[index].cantidad - 1) * _items[index].precioUnitario,
        );
        _calculateTotal();
      });
    }
  }

  void _calculateTotal() {
    _total = _items.fold(0.0, (sum, item) => sum + (item.cantidad * item.precioUnitario));
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<Producto> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return widget.products;
    }
    return widget.products.where((product) {
      return product.nombre.toLowerCase().contains(_searchQuery) ||
             product.categoria.toLowerCase().contains(_searchQuery) ||
             product.talla.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  bool _isProductSelected(Producto product) {
    return _items.any((item) => item.productoId == product.id);
  }

  void _addProduct(Producto product) {
    // Verificar si el producto ya está seleccionado
    if (_isProductSelected(product)) {
      return;
    }
    
    // Verificar si el producto tiene stock disponible
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nombre} no tiene stock disponible'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _items.add(VentaItem(
        ventaId: 0, // Se asignará cuando se cree la venta
        productoId: product.id!,
        nombreProducto: product.nombre,
        categoria: product.categoria,
        talla: product.talla,
        cantidad: 1,
        precioUnitario: product.precioVenta,
        subtotal: product.precioVenta,
      ));
      _calculateTotal();
    });
  }

  void _removeProduct(Producto product) {
    setState(() {
      _items.removeWhere((item) => item.productoId == product.id);
      _calculateTotal();
    });
  }

  void _toggleProductSelection(Producto product) {
    if (_isProductSelected(product)) {
      _removeProduct(product);
    } else {
      _addProduct(product);
    }
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor agrega al menos un producto a la venta.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final sale = Venta(
        id: widget.sale?.id,
        cliente: _clienteController.text.trim(),
        telefono: '', // Campo requerido
        email: '', // Campo requerido
        fecha: widget.sale?.fecha ?? DateTime.now(),
        total: _total,
        metodoPago: _selectedMetodoPago,
        estado: _selectedEstado,
        notas: _observacionesController.text.trim(),
        items: _items,
      );

      widget.onSave(sale);
    }
  }

  Widget _buildActionButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _handleSave,
      icon: Icon(widget.sale == null ? Icons.add : Icons.save),
      label: Text(widget.sale == null ? 'Crear Venta' : 'Guardar Cambios'),
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

  Widget _buildProductSearch() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        labelText: 'Buscar Productos',
        prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }

  Widget _buildAvailableProducts() {
    final filteredProducts = _filteredProducts;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _searchQuery.isEmpty 
                        ? 'No hay productos disponibles'
                        : 'No se encontraron productos',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                final isSelected = _isProductSelected(product);
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: isSelected ? 4 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check : Icons.add,
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      product.nombre,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.primaryColor : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${product.categoria} - ${product.talla}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '\$${product.precioVenta.round()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: product.stock <= 0
                                    ? Colors.red.shade100
                                    : product.stock > 10 
                                        ? Colors.green.shade100 
                                        : product.stock > 5 
                                            ? Colors.orange.shade100 
                                            : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                product.stock <= 0 
                                    ? 'Sin Stock'
                                    : 'Stock: ${product.stock}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: product.stock <= 0
                                      ? Colors.red.shade700
                                      : product.stock > 10 
                                          ? Colors.green.shade700 
                                          : product.stock > 5 
                                              ? Colors.orange.shade700 
                                              : Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: product.stock <= 0
                        ? Icon(
                            Icons.block,
                            color: Colors.grey.shade400,
                            size: 24,
                          )
                        : IconButton(
                            icon: Icon(
                              isSelected ? Icons.remove_circle : Icons.add_circle_outline,
                              color: isSelected ? Colors.red.shade600 : AppTheme.primaryColor,
                              size: 24,
                            ),
                            onPressed: () => _toggleProductSelection(product),
                          ),
                    onTap: product.stock <= 0 ? null : () => _toggleProductSelection(product),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSelectedProducts() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay productos seleccionados',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona productos del lado izquierdo',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: _items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    dense: true,
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: AppTheme.primaryColor,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      item.nombreProducto,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          '${item.categoria} - ${item.talla}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${item.precioUnitario.round()} c/u',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón de cantidad con + y -
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Botón -
                              IconButton(
                                onPressed: () => _decreaseQuantity(index),
                                icon: Icon(
                                  Icons.remove,
                                  color: item.cantidad > 1 ? Colors.red.shade600 : Colors.grey.shade400,
                                  size: 16,
                                ),
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                              // Cantidad
                              Container(
                                width: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  item.cantidad.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Botón +
                              IconButton(
                                onPressed: () {
                                  final product = widget.products.firstWhere((p) => p.id == item.productoId);
                                  if (item.cantidad < product.stock) {
                                    _increaseQuantity(index);
                                  }
                                },
                                icon: Icon(
                                  Icons.add,
                                  color: item.cantidad < widget.products.firstWhere((p) => p.id == item.productoId).stock 
                                      ? AppTheme.primaryColor 
                                      : Colors.grey.shade400,
                                  size: 16,
                                ),
                                padding: const EdgeInsets.all(2),
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Precio total
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '\$${(item.cantidad * item.precioUnitario).round()}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Botón eliminar
                        IconButton(
                          onPressed: () => _removeItem(index),
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade600,
                            size: 18,
                          ),
                          padding: const EdgeInsets.all(2),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        ),
                      ],
                    ),
                  ),
                );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildLeftSide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(FontAwesomeIcons.boxesStacked, 'Productos Disponibles'),
        const SizedBox(height: 12),
        
        // Búsqueda de productos
        _buildProductSearch(),
        const SizedBox(height: 12),
        
        // Lista de productos disponibles
        Expanded(
          child: _buildAvailableProducts(),
        ),
      ],
    );
  }

  Widget _buildRightSide(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección de detalles de la venta
        _buildSectionTitle(Icons.info, 'Detalles de la Venta'),
        const SizedBox(height: 8),
        
        // Campos principales
        TextFormField(
          controller: _clienteController,
          decoration: _inputDecoration('Nombre del Cliente', FontAwesomeIcons.user),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre del cliente no puede estar vacío';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedEstado,
                decoration: _inputDecoration('Estado', FontAwesomeIcons.solidCircleCheck),
                items: _estados.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEstado = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedMetodoPago,
                decoration: _inputDecoration('Método de Pago', FontAwesomeIcons.moneyBillTransfer),
                items: _metodosPago.map((metodo) {
                  return DropdownMenuItem(
                    value: metodo,
                    child: Text(metodo),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMetodoPago = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Productos seleccionados
        _buildSectionTitle(FontAwesomeIcons.shoppingCart, 'Productos Seleccionados'),
        const SizedBox(height: 12),
        
        // Lista de productos seleccionados
        Expanded(
          flex: 2,
          child: _buildSelectedProducts(),
        ),
        const SizedBox(height: 16),
        
        // Total y botones
        _buildTotalAndActions(context),
      ],
    );
  }

  Widget _buildTotalAndActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total: \$${_total.round()}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        _buildActionButton(context),
      ],
    );
  }
}
