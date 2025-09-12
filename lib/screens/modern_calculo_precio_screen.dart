import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/producto.dart';
import '../services/datos/datos.dart';
import '../services/datos/dashboard_service.dart';
import '../services/ml_persistence_service.dart';
import '../services/ai_cache_service.dart';
import '../config/app_theme.dart';
import '../widgets/animated_widgets.dart';

class ModernCalculoPrecioScreen extends StatefulWidget {
  final bool showCloseButton;
  
  const ModernCalculoPrecioScreen({
    super.key,
    this.showCloseButton = false,
  });

  @override
  State<ModernCalculoPrecioScreen> createState() => _ModernCalculoPrecioScreenState();
}

class _ModernCalculoPrecioScreenState extends State<ModernCalculoPrecioScreen> with TickerProviderStateMixin {
  final DatosService _datosService = DatosService();
  late TabController _tabController;

  // Controladores para información del producto
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _stockController = TextEditingController(text: '1');

  // Controladores para costos de materiales
  final List<MaterialItem> _materiales = [];
  final _nuevoMaterialController = TextEditingController();
  final _cantidadMaterialController = TextEditingController();
  final _precioMaterialController = TextEditingController();
  
  // Controladores temporales para edición
  final _editarMaterialController = TextEditingController();
  final _editarCantidadController = TextEditingController();
  final _editarPrecioController = TextEditingController();

  // Controladores para costos de producción
  final _tiempoConfeccionController = TextEditingController();
  final _tarifaHoraController = TextEditingController(text: '15.0');
  final _costoEquiposController = TextEditingController(text: '0');

  // Controladores para costos fijos
  final _alquilerMensualController = TextEditingController();
  final _serviciosController = TextEditingController();
  final _gastosAdminController = TextEditingController();
  final _productosEstimadosController = TextEditingController(text: '50');

  // Controladores para margen y resultado
  final _margenGananciaController = TextEditingController(text: '50');
  final _ivaController = TextEditingController(text: '21');

  String _categoriaSeleccionada = 'Bodies';
  String _tallaSeleccionada = '0-3 meses';

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
    _tabController = TabController(length: 5, vsync: this);
    _materiales.add(MaterialItem(nombre: 'Tela principal', cantidad: 1, precio: 0));
    
    // Agregar listeners para actualizar precios automáticamente
    _tiempoConfeccionController.addListener(_actualizarPrecios);
    _tarifaHoraController.addListener(_actualizarPrecios);
    _costoEquiposController.addListener(_actualizarPrecios);
    _alquilerMensualController.addListener(_actualizarPrecios);
    _serviciosController.addListener(_actualizarPrecios);
    _gastosAdminController.addListener(_actualizarPrecios);
    _productosEstimadosController.addListener(_actualizarPrecios);
    _margenGananciaController.addListener(_actualizarPrecios);
    _ivaController.addListener(_actualizarPrecios);
    
    // Cargar datos del usuario si está autenticado
    _cargarDatosUsuario();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _stockController.dispose();
    _nuevoMaterialController.dispose();
    _cantidadMaterialController.dispose();
    _precioMaterialController.dispose();
    _editarMaterialController.dispose();
    _editarCantidadController.dispose();
    _editarPrecioController.dispose();
    _tiempoConfeccionController.dispose();
    _tarifaHoraController.dispose();
    _costoEquiposController.dispose();
    _alquilerMensualController.dispose();
    _serviciosController.dispose();
    _gastosAdminController.dispose();
    _productosEstimadosController.dispose();
    _margenGananciaController.dispose();
    _ivaController.dispose();
    super.dispose();
  }

  // Función para actualizar precios automáticamente
  void _actualizarPrecios() {
    if (mounted) {
      setState(() {});
    }
  }

  // Función para formatear números sin decimales innecesarios
  String _formatearPrecio(double precio) {
    if (precio == precio.roundToDouble()) {
      return precio.round().toString();
    } else {
      return precio.toStringAsFixed(2);
    }
  }

  // Función para actualizar el dashboard de forma segura
  void _actualizarDashboard() {
    try {
      // Usar un Future.delayed para asegurar que la navegación termine primero
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          context.read<DashboardService>().cargarDatos();
        } catch (e) {
          print('Error actualizando dashboard: $e');
        }
      });
    } catch (e) {
      print('Error programando actualización del dashboard: $e');
    }
  }

  /// Carga datos del usuario desde Supabase si está autenticado
  Future<void> _cargarDatosUsuario() async {
    try {
      // DatosService maneja automáticamente la sincronización
      await _datosService.initialize();
    } catch (e) {
      print('Error cargando datos del usuario: $e');
    }
  }

  void _generarDatosEntrenamientoML(Producto producto) {
    try {
      // Importar el servicio de ML
      final mlPersistenceService = MLPersistenceService();
      
      // Generar datos de entrenamiento basados en el producto
      final features = [
        producto.costoMateriales,
        producto.costoManoObra,
        producto.gastosGenerales,
        producto.margenGanancia,
        producto.stock.toDouble(),
      ];
      
      final target = producto.precioVenta;
      
      // Crear datos de entrenamiento como Map<String, dynamic>
      final trainingData = {
        'features': features,
        'target': target,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Guardar datos en Supabase
      mlPersistenceService.saveTrainingData(trainingData);
      
      // Invalidar caché para que se actualicen las estadísticas
      final cacheService = AICacheService();
      cacheService.invalidateCache();
      
      print('Datos de entrenamiento ML generados para producto: ${producto.nombre}');
    } catch (e) {
      print('Error generando datos de entrenamiento ML: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductoInfo(),
                        _buildMateriales(),
                        _buildProduccion(),
                        _buildCostosFijos(),
                        _buildResultado(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final stepInfo = _getStepInfo(_tabController.index);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                stepInfo['icon'],
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stepInfo['title'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stepInfo['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Paso ${_tabController.index + 1} de 5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getStepInfo(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return {
          'title': 'Información del Producto',
          'description': 'Completa los datos básicos de tu producto. Esta información te ayudará a organizar mejor tu inventario y calcular costos precisos.',
          'icon': FontAwesomeIcons.circleInfo,
        };
      case 1:
        return {
          'title': 'Costos de Materiales',
          'description': 'Agrega todos los materiales necesarios para confeccionar tu producto. Incluye tela, hilos, botones, cierres, etiquetas y cualquier otro insumo.',
          'icon': FontAwesomeIcons.boxesStacked,
        };
      case 2:
        return {
          'title': 'Costos de Producción',
          'description': 'Calcula el costo de mano de obra y equipos necesarios para confeccionar tu producto. Considera el tiempo de trabajo y la depreciación de máquinas.',
          'icon': FontAwesomeIcons.hammer,
        };
      case 3:
        return {
          'title': 'Costos Fijos',
          'description': 'Incluye los gastos mensuales de tu negocio que se distribuyen entre todos los productos. Alquiler, servicios, gastos administrativos y otros costos operativos.',
          'icon': FontAwesomeIcons.house,
        };
      case 4:
        return {
          'title': 'Resultado Final',
          'description': 'Revisa el desglose completo de costos y el precio de venta sugerido. Analiza la rentabilidad y ajusta el margen de ganancia según tus objetivos de negocio.',
          'icon': FontAwesomeIcons.chartLine,
        };
      default:
        return {
          'title': 'Calculadora de Costos Completa',
          'description': 'Calcula el precio de venta de tus productos',
          'icon': Icons.calculate,
        };
    }
  }


  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primaryColor,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: FaIcon(FontAwesomeIcons.circleInfo, size: 20),
            text: 'Producto',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.boxesStacked, size: 20),
            text: 'Materiales',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.hammer, size: 20),
            text: 'Producción',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.house, size: 20),
            text: 'Costos Fijos',
          ),
          Tab(
            icon: FaIcon(FontAwesomeIcons.chartLine, size: 20),
            text: 'Resultado',
          ),
        ],
      ),
    );
  }

  Widget _buildProductoInfo() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputFieldMinimalista(
                  controller: _nombreController,
                  label: 'Nombre del Producto',
                  hint: 'Ej: Body de algodón',
                  icon: FontAwesomeIcons.boxesStacked,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownMinimalista(
                  value: _categoriaSeleccionada,
                  items: _categorias,
                  label: 'Categoría',
                  onChanged: (value) => setState(() => _categoriaSeleccionada = value!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdownMinimalista(
                  value: _tallaSeleccionada,
                  items: _tallas,
                  label: 'Talla',
                  onChanged: (value) => setState(() => _tallaSeleccionada = value!),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputFieldMinimalista(
                  controller: _stockController,
                  label: 'Stock Inicial',
                  hint: '1',
                  icon: FontAwesomeIcons.tag,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _descripcionController,
            label: 'Descripción',
            hint: 'Descripción detallada del producto...',
            icon: FontAwesomeIcons.fileText,
            maxLines: 3,
          ),
          const Spacer(),
          _buildNavigationButtons(0),
        ],
      ),
    );
  }

  Widget _buildMateriales() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedButton(
                text: 'Agregar Material',
                type: ButtonType.primary,
                onPressed: _agregarMaterial,
                icon: FontAwesomeIcons.plus,
                delay: const Duration(milliseconds: 100),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _materiales.isEmpty
                ? const Center(
                    child: Text(
                      'No hay materiales agregados',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _materiales.length,
                    itemBuilder: (context, index) {
                      final material = _materiales[index];
                      return AnimatedCard(
                        delay: Duration(milliseconds: 100 * (index + 1)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  FontAwesomeIcons.boxesStacked,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      material.nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          'Cantidad: ${material.cantidad}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Precio: \$${_formatearPrecio(material.precio)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${_formatearPrecio(material.cantidad * material.precio)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _editarMaterial(index),
                                          icon: const FaIcon(FontAwesomeIcons.penToSquare, color: AppTheme.primaryColor, size: 18),
                                          tooltip: 'Editar material',
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _eliminarMaterial(index),
                                          icon: const FaIcon(FontAwesomeIcons.trash, color: AppTheme.errorColor, size: 18),
                                          tooltip: 'Eliminar material',
                                          padding: const EdgeInsets.all(8),
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ));
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _buildNavigationButtons(1),
        ],
      ),
    );
  }

  Widget _buildProduccion() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _tiempoConfeccionController,
                  label: 'Tiempo de Confección (horas)',
                  hint: '2.5',
                  icon: FontAwesomeIcons.clock,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _tarifaHoraController,
                  label: 'Tarifa por Hora (\$)',
                  hint: '15.0',
                  icon: FontAwesomeIcons.dollarSign,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _costoEquiposController,
            label: 'Costos de Equipos/Máquinas (\$)',
            hint: '0',
            icon: FontAwesomeIcons.hammer,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          _buildResumenCostos(),
          const Spacer(),
          _buildNavigationButtons(2),
        ],
      ),
    );
  }

  Widget _buildCostosFijos() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila de inputs
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _alquilerMensualController,
                  label: 'Alquiler Mensual (\$)',
                  hint: '500',
                  icon: FontAwesomeIcons.house,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _serviciosController,
                  label: 'Servicios (\$)',
                  hint: '150',
                  icon: FontAwesomeIcons.bolt,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Segunda fila de inputs
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _gastosAdminController,
                  label: 'Gastos Admin (\$)',
                  hint: '100',
                  icon: FontAwesomeIcons.building,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _productosEstimadosController,
                  label: 'Productos/Mes',
                  hint: '50',
                  icon: FontAwesomeIcons.boxesStacked,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Resumen compacto
          _buildResumenCostosFijosCompacto(),
          const Spacer(),
          _buildNavigationButtons(3),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    final costos = _calcularCostos();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Layout horizontal para aprovechar mejor el espacio
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda - Desglose de costos
                Expanded(
                  flex: 3,
                  child: _buildDesgloseCostosCompacto(costos),
                ),
                const SizedBox(width: 12),
                // Columna derecha - Precio y análisis
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPrecioFinalCompacto(costos),
                      const SizedBox(height: 12),
                      _buildAnalisisRentabilidadCompacto(costos),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Botones en la parte inferior
          _buildBotonesFinalesCompactos(),
        ],
      ),
    );
  }

  Widget _buildInputFieldMinimalista({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 18),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownMinimalista({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            )).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
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
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          AnimatedButton(
            text: 'Anterior',
            type: ButtonType.secondary,
            onPressed: () => _tabController.animateTo(_tabController.index - 1),
            icon: FontAwesomeIcons.arrowLeft,
            delay: const Duration(milliseconds: 100),
          ),
        const Spacer(),
        if (currentIndex < 4)
          AnimatedButton(
            text: 'Siguiente',
            type: ButtonType.primary,
            onPressed: () => _tabController.animateTo(_tabController.index + 1),
            icon: FontAwesomeIcons.arrowRight,
            delay: const Duration(milliseconds: 200),
          ),
      ],
    );
  }

  Widget _buildResumenCostos() {
    final tiempoConfeccion = double.tryParse(_tiempoConfeccionController.text) ?? 0;
    final tarifaHora = double.tryParse(_tarifaHoraController.text) ?? 0;
    final costoEquipos = double.tryParse(_costoEquiposController.text) ?? 0;
    final costoManoObra = tiempoConfeccion * tarifaHora;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de Costos de Producción',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mano de Obra:'),
                Text('\$${_formatearPrecio(costoManoObra)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Equipos/Máquinas:'),
                Text('\$${_formatearPrecio(costoEquipos)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Producción:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '\$${_formatearPrecio(costoManoObra + costoEquipos)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCostosFijosCompacto() {
    final alquiler = double.tryParse(_alquilerMensualController.text) ?? 0;
    final servicios = double.tryParse(_serviciosController.text) ?? 0;
    final gastosAdmin = double.tryParse(_gastosAdminController.text) ?? 0;
    final productosEstimados = double.tryParse(_productosEstimadosController.text) ?? 1;
    final costoFijoPorProducto = (alquiler + servicios + gastosAdmin) / productosEstimados;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Costos Fijos:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                '\$${(alquiler + servicios + gastosAdmin).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Por Producto:',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\$${costoFijoPorProducto.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseCostosCompacto(Map<String, double> costos) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.chartLine,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Desglose de Costos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid 2x2 más compacto
          Row(
            children: [
              Expanded(
                child: _buildCostoItemCompacto('Materiales', costos['materiales'] ?? 0, AppTheme.primaryColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostoItemCompacto('Mano Obra', costos['manoObra'] ?? 0, AppTheme.secondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCostoItemCompacto('Equipos', costos['equipos'] ?? 0, AppTheme.accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCostoItemCompacto('Fijos', costos['costosFijos'] ?? 0, AppTheme.warningColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total más compacto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.successColor.withOpacity(0.1),
                  AppTheme.successColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.successColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total de Costos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '\$${_formatearPrecio(costos['costoTotal'] ?? 0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoItemCompacto(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostoItemMinimalista(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPrecioFinalCompacto(Map<String, double> costos) {
    final margen = double.tryParse(_margenGananciaController.text) ?? 50;
    final iva = double.tryParse(_ivaController.text) ?? 21;
    final costoTotal = costos['costoTotal'] ?? 0;
    final precioSinIva = costoTotal * (1 + margen / 100);
    final precioConIva = precioSinIva * (1 + iva / 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.dollarSign,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Precio Sugerido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '\$${_formatearPrecio(precioConIva)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'IVA ${iva}% incluido',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Margen',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${margen}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: AppTheme.borderColor,
                ),
                Column(
                  children: [
                    const Text(
                      'Ganancia',
                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${(precioSinIva - costoTotal).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecioFinalMinimalista(Map<String, double> costos) {
    final margen = double.tryParse(_margenGananciaController.text) ?? 50;
    final iva = double.tryParse(_ivaController.text) ?? 21;
    final costoTotal = costos['costoTotal'] ?? 0;
    final precioSinIva = costoTotal * (1 + margen / 100);
    final precioConIva = precioSinIva * (1 + iva / 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.secondaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.dollarSign,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Precio Sugerido',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '\$${_formatearPrecio(precioConIva)}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'IVA ${iva}% incluido',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text(
                      'Margen',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${margen}%',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  height: 30,
                  width: 1,
                  color: AppTheme.borderColor,
                ),
                Column(
                  children: [
                    const Text(
                      'Ganancia',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(precioSinIva - costoTotal).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.successColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisRentabilidadCompacto(Map<String, double> costos) {
    final margen = double.tryParse(_margenGananciaController.text) ?? 50;
    final costoTotal = costos['costoTotal'] ?? 0;
    final precioSinIva = costoTotal * (1 + margen / 100);
    final ganancia = precioSinIva - costoTotal;
    final porcentajeGanancia = costoTotal > 0 ? (ganancia / costoTotal) * 100 : margen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  FontAwesomeIcons.arrowTrendUp,
                  color: AppTheme.successColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Rentabilidad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ganancia Neta',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '\$${ganancia.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Margen de Ganancia',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${porcentajeGanancia.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalisisRentabilidadMinimalista(Map<String, double> costos) {
    final margen = double.tryParse(_margenGananciaController.text) ?? 50;
    final costoTotal = costos['costoTotal'] ?? 0;
    final precioSinIva = costoTotal * (1 + margen / 100);
    final ganancia = precioSinIva - costoTotal;
    final porcentajeGanancia = costoTotal > 0 ? (ganancia / costoTotal) * 100 : margen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.successColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  FontAwesomeIcons.arrowTrendUp,
                  color: AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Rentabilidad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ganancia Neta',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '\$${ganancia.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Margen de Ganancia',
                      style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    Text(
                      '${porcentajeGanancia.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonesFinalesCompactos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextButton(
            onPressed: () => _tabController.animateTo(_tabController.index - 1),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: AppTheme.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _guardarProducto,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.floppyDisk, size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Guardar',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: _nuevoCalculo,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16, color: AppTheme.successColor),
                    SizedBox(width: 6),
                    Text(
                      'Nuevo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonesFinalesMinimalistas() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.textSecondary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextButton(
            onPressed: () => _tabController.animateTo(_tabController.index - 1),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(FontAwesomeIcons.arrowLeft, size: 18, color: AppTheme.textSecondary),
                SizedBox(width: 8),
                Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _guardarProducto,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.floppyDisk, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Guardar Producto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: _nuevoCalculo,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(FontAwesomeIcons.arrowRotateRight, size: 18, color: AppTheme.successColor),
                    SizedBox(width: 8),
                    Text(
                      'Nuevo Cálculo',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _agregarMaterial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nuevoMaterialController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Material',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cantidadMaterialController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _precioMaterialController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () => Navigator.pop(context),
            delay: const Duration(milliseconds: 100),
          ),
          AnimatedButton(
            text: 'Agregar',
            type: ButtonType.primary,
            onPressed: () {
              if (_nuevoMaterialController.text.isNotEmpty) {
                setState(() {
                  _materiales.add(MaterialItem(
                    nombre: _nuevoMaterialController.text,
                    cantidad: double.tryParse(_cantidadMaterialController.text) ?? 1,
                    precio: double.tryParse(_precioMaterialController.text) ?? 0,
                  ));
                });
                _nuevoMaterialController.clear();
                _cantidadMaterialController.clear();
                _precioMaterialController.clear();
                Navigator.pop(context);
              }
            },
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  void _eliminarMaterial(int index) {
    setState(() {
      _materiales.removeAt(index);
    });
  }

  void _editarMaterial(int index) {
    final material = _materiales[index];
    
    // Llenar los controladores con los valores actuales
    _editarMaterialController.text = material.nombre;
    _editarCantidadController.text = material.cantidad.toString();
    _editarPrecioController.text = material.precio.toString();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Material'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _editarMaterialController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Material',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _editarCantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _editarPrecioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedButton(
            text: 'Cancelar',
            type: ButtonType.secondary,
            onPressed: () {
              _editarMaterialController.clear();
              _editarCantidadController.clear();
              _editarPrecioController.clear();
              Navigator.pop(context);
            },
            delay: const Duration(milliseconds: 100),
          ),
          AnimatedButton(
            text: 'Guardar',
            type: ButtonType.primary,
            onPressed: () {
              if (_editarMaterialController.text.isNotEmpty) {
                setState(() {
                  _materiales[index] = MaterialItem(
                    nombre: _editarMaterialController.text,
                    cantidad: double.tryParse(_editarCantidadController.text) ?? 1,
                    precio: double.tryParse(_editarPrecioController.text) ?? 0,
                  );
                });
                _editarMaterialController.clear();
                _editarCantidadController.clear();
                _editarPrecioController.clear();
                Navigator.pop(context);
              }
            },
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calcularCostos() {
    // Costos de materiales
    final costoMateriales = _materiales.fold<double>(
      0,
      (sum, material) => sum + (material.cantidad * material.precio),
    );

    // Costos de producción
    final tiempoConfeccion = double.tryParse(_tiempoConfeccionController.text) ?? 0;
    final tarifaHora = double.tryParse(_tarifaHoraController.text) ?? 0;
    final costoManoObra = tiempoConfeccion * tarifaHora;
    final costoEquipos = double.tryParse(_costoEquiposController.text) ?? 0;

    // Costos fijos
    final alquiler = double.tryParse(_alquilerMensualController.text) ?? 0;
    final servicios = double.tryParse(_serviciosController.text) ?? 0;
    final gastosAdmin = double.tryParse(_gastosAdminController.text) ?? 0;
    final productosEstimados = double.tryParse(_productosEstimadosController.text) ?? 1;
    final costoFijoPorProducto = (alquiler + servicios + gastosAdmin) / productosEstimados;

    final costoTotal = costoMateriales + costoManoObra + costoEquipos + costoFijoPorProducto;

    return {
      'materiales': costoMateriales,
      'manoObra': costoManoObra,
      'equipos': costoEquipos,
      'costosFijos': costoFijoPorProducto,
      'costoTotal': costoTotal,
    };
  }

  Future<void> _guardarProducto() async {
    // Validaciones
    if (_nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa el nombre del producto')),
      );
      return;
    }

    if (_categoriaSeleccionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una categoría')),
      );
      return;
    }

    if (_tallaSeleccionada.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una talla')),
      );
      return;
    }

    try {
      final costos = _calcularCostos();
      final margen = double.tryParse(_margenGananciaController.text) ?? 50;
      final stock = int.tryParse(_stockController.text) ?? 1;

      // Validar que los costos sean válidos
      if (costos['costoTotal']! <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El costo total debe ser mayor a 0')),
        );
        return;
      }

      final producto = Producto(
        nombre: _nombreController.text.trim(),
        categoria: _categoriaSeleccionada,
        talla: _tallaSeleccionada,
        costoMateriales: costos['materiales']!,
        costoManoObra: costos['manoObra']!,
        gastosGenerales: costos['costosFijos']! + costos['equipos']!,
        margenGanancia: margen,
        stock: stock,
        fechaCreacion: DateTime.now(),
      );

      // Guardar producto usando DatosService (maneja local + Supabase automáticamente)
      final guardadoExitoso = await _datosService.saveProducto(producto);
      
      if (!guardadoExitoso) {
        throw Exception('Error guardando el producto');
      }
      
      // Generar datos de entrenamiento para ML
      _generarDatosEntrenamientoML(producto);
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto guardado exitosamente'),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Verificar si podemos hacer pop antes de intentarlo
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          // Actualizar el dashboard después de navegar
          _actualizarDashboard();
        } else {
          // Si no podemos hacer pop, limpiar el formulario
          _nuevoCalculo();
          // Actualizar el dashboard de todas formas
          _actualizarDashboard();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  void _nuevoCalculo() {
    setState(() {
      _nombreController.clear();
      _descripcionController.clear();
      _stockController.text = '1';
      _materiales.clear();
      _materiales.add(MaterialItem(nombre: 'Tela principal', cantidad: 1, precio: 0));
      _tiempoConfeccionController.clear();
      _tarifaHoraController.text = '15.0';
      _costoEquiposController.text = '0';
      _alquilerMensualController.clear();
      _serviciosController.clear();
      _gastosAdminController.clear();
      _productosEstimadosController.text = '50';
      _margenGananciaController.text = '50';
      _ivaController.text = '21';
      _tabController.animateTo(0);
    });
  }
}

class MaterialItem {
  final String nombre;
  final double cantidad;
  final double precio;

  MaterialItem({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });
}