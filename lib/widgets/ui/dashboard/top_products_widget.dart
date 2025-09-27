import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'modern_card_widget.dart';
import '../../../services/datos/dashboard_service.dart';

/// Widget para productos más vendidos
class TopProductsWidget extends StatefulWidget {
  final VoidCallback? onVerTodos;
  
  const TopProductsWidget({
    super.key,
    this.onVerTodos,
  });

  @override
  State<TopProductsWidget> createState() => _TopProductsWidgetState();
}

class _TopProductsWidgetState extends State<TopProductsWidget> {
  final DashboardService _dashboardService = DashboardService();
  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final productos = await _dashboardService.getProductosMasVendidos(limit: 5);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título y "Ver todos"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Productos Populares',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              TextButton(
                onPressed: widget.onVerTodos,
                child: const Text(
                  'Ver Todos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00FF88),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenido
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_productos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay productos vendidos aún',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            )
          else
            // Lista de productos
            ..._productos.map((producto) => _buildProductItem(producto)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> producto) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icono del producto
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              FontAwesomeIcons.box,
              color: Color(0xFF3B82F6),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto['nombre'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                Text(
                  '${producto['cantidadVendida']} unidades vendidas',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Precio
          Text(
            '\$${(producto['precio'] as double).round()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
        ],
      ),
    );
  }
}
