import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/datos/datos.dart';
import '../config/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/action_button.dart';
import '../widgets/windows_app_bar.dart';
import '../widgets/windows_button.dart';
import 'calcularprecios_screen/modern_calculadora_precios_screen.dart';
import 'inventario_screen/modern_inventario_screen.dart';
import 'reportes_screen/modern_reportes_screen.dart';
import 'configuracion_screen/modern_configuracion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatosService _datosService = DatosService();
  List<Producto> _productos = [];

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    final productos = await _datosService.getAllProductos();
    setState(() {
      _productos = productos;
    });
  }

  double get _valorTotalInventario {
    return _productos.fold(0, (sum, producto) => sum + (producto.precioVenta * producto.stock));
  }

  int get _productosSinStock {
    return _productos.where((p) => p.stock == 0).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WindowsAppBar(
        title: '📦 Stockcito',
        showBackButton: false,
        actions: [
          WindowsButton(
            text: 'Configuración',
            icon: Icons.settings,
            type: ButtonType.secondary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ModernConfiguracionScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con saludo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.gradientDecoration.copyWith(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¡Bienvenido!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestiona tu inventario y ventas de manera eficiente',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.child_care,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Métricas principales
            Text(
              'Resumen del Negocio',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                MetricCard(
                  title: 'Total Productos',
                  value: '${_productos.length}',
                  icon: Icons.inventory_2,
                  color: AppTheme.primaryColor,
                  subtitle: 'En catálogo',
                ),
                MetricCard(
                  title: 'En Stock',
                  value: '${_productos.where((p) => p.stock > 0).length}',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                  subtitle: 'Disponibles',
                ),
                MetricCard(
                  title: 'Sin Stock',
                  value: '$_productosSinStock',
                  icon: Icons.warning,
                  color: _productosSinStock > 0 ? AppTheme.warningColor : AppTheme.successColor,
                  subtitle: 'Agotados',
                ),
                MetricCard(
                  title: 'Valor Total',
                  value: '\$${_valorTotalInventario.toStringAsFixed(0)}',
                  icon: Icons.attach_money,
                  color: AppTheme.accentColor,
                  subtitle: 'Inventario',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Acciones principales
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                ActionButton(
                  title: 'Calcular Precio',
                  subtitle: 'Nuevo producto',
                  icon: Icons.calculate,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModernCalculadoraPreciosScreen()),
                    ).then((_) => _loadProductos());
                  },
                ),
                ActionButton(
                  title: 'Inventario',
                  subtitle: 'Gestionar stock',
                  icon: Icons.inventory,
                  color: AppTheme.secondaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModernInventarioScreen()),
                    ).then((_) => _loadProductos());
                  },
                ),
                ActionButton(
                  title: 'Reportes',
                  subtitle: 'Análisis y ventas',
                  icon: Icons.analytics,
                  color: AppTheme.accentColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModernReportesScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Productos recientes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos Recientes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModernInventarioScreen()),
                    );
                  },
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _productos.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay productos aún',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Crea tu primer producto para comenzar!',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ModernCalculadoraPreciosScreen()),
                              ).then((_) => _loadProductos());
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear Producto'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _productos.take(5).length,
                    itemBuilder: (context, index) {
                      final producto = _productos[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getIconForCategory(producto.categoria),
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${producto.categoria} - ${producto.talla}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${producto.precioVenta.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: producto.stock > 0 ? AppTheme.successColor : AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Stock: ${producto.stock}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String categoria) {
    switch (categoria) {
      case 'Bodies':
        return Icons.child_care;
      case 'Conjuntos':
        return Icons.checkroom;
      case 'Vestidos':
        return Icons.woman;
      case 'Pijamas':
        return Icons.nightlight;
      case 'Gorros':
        return Icons.ac_unit;
      case 'Accesorios':
        return Icons.star;
      default:
        return Icons.inventory_2;
    }
  }
}
