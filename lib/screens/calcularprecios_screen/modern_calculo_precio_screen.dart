import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/producto.dart';
import '../../../services/datos/datos.dart';
import '../../../services/datos/dashboard_service.dart';
import '../../../services/ml/ml_persistence_service.dart';
import '../../../services/ai/ai_cache_service.dart';
import '../../../config/app_theme.dart';

// Importar widgets refactorizados
import 'widgets/calculo_precio_header.dart';
import 'widgets/calculo_precio_tab_bar.dart';
import 'widgets/calculo_precio_producto_info_tab.dart';
import 'widgets/calculo_precio_materiales_tab.dart';
import 'widgets/calculo_precio_produccion_tab.dart';
import 'widgets/calculo_precio_costos_fijos_tab.dart';
import 'widgets/calculo_precio_resultado_tab.dart';
import 'widgets/calculo_precio_material_dialogs.dart';

// Importar funciones y modelos
import 'functions/calculo_precio_functions.dart';
import 'models/material_item.dart';

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
          CalculoPrecioHeader(tabController: _tabController),
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
                  CalculoPrecioTabBar(tabController: _tabController),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        CalculoPrecioProductoInfoTab(
                          nombreController: _nombreController,
                          descripcionController: _descripcionController,
                          stockController: _stockController,
                          categoriaSeleccionada: _categoriaSeleccionada,
                          tallaSeleccionada: _tallaSeleccionada,
                          onCategoriaChanged: (categoria) => setState(() => _categoriaSeleccionada = categoria),
                          onTallaChanged: (talla) => setState(() => _tallaSeleccionada = talla),
                          tabController: _tabController,
                        ),
                        CalculoPrecioMaterialesTab(
                          materiales: _materiales,
                          onAgregarMaterial: _agregarMaterial,
                          onEditarMaterial: _editarMaterial,
                          onEliminarMaterial: _eliminarMaterial,
                          tabController: _tabController,
                        ),
                        CalculoPrecioProduccionTab(
                          tiempoConfeccionController: _tiempoConfeccionController,
                          tarifaHoraController: _tarifaHoraController,
                          costoEquiposController: _costoEquiposController,
                          tabController: _tabController,
                        ),
                        CalculoPrecioCostosFijosTab(
                          alquilerMensualController: _alquilerMensualController,
                          serviciosController: _serviciosController,
                          gastosAdminController: _gastosAdminController,
                          productosEstimadosController: _productosEstimadosController,
                          tabController: _tabController,
                        ),
                        CalculoPrecioResultadoTab(
                          costos: _calcularCostos(),
                          margenGanancia: double.tryParse(_margenGananciaController.text) ?? 50,
                          iva: double.tryParse(_ivaController.text) ?? 21,
                          onGuardarProducto: _guardarProducto,
                          onNuevoCalculo: _nuevoCalculo,
                          tabController: _tabController,
                        ),
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

  void _agregarMaterial() {
    CalculoPrecioMaterialDialogs.showAgregarMaterialDialog(
      context: context,
      nombreController: _nuevoMaterialController,
      cantidadController: _cantidadMaterialController,
      precioController: _precioMaterialController,
      onAgregar: (material) {
        setState(() {
          _materiales.add(material);
        });
      },
    );
  }

  void _eliminarMaterial(int index) {
    setState(() {
      _materiales.removeAt(index);
    });
  }

  void _editarMaterial(int index) {
    final material = _materiales[index];
    
    CalculoPrecioMaterialDialogs.showEditarMaterialDialog(
      context: context,
      material: material,
      nombreController: _editarMaterialController,
      cantidadController: _editarCantidadController,
      precioController: _editarPrecioController,
      onEditar: (materialEditado) {
        setState(() {
          _materiales[index] = materialEditado;
        });
      },
    );
  }

  Map<String, double> _calcularCostos() {
    return CalculoPrecioFunctions.calcularCostos(
      materiales: _materiales,
      tiempoConfeccion: double.tryParse(_tiempoConfeccionController.text) ?? 0,
      tarifaHora: double.tryParse(_tarifaHoraController.text) ?? 0,
      costoEquipos: double.tryParse(_costoEquiposController.text) ?? 0,
      alquiler: double.tryParse(_alquilerMensualController.text) ?? 0,
      servicios: double.tryParse(_serviciosController.text) ?? 0,
      gastosAdmin: double.tryParse(_gastosAdminController.text) ?? 0,
      productosEstimados: double.tryParse(_productosEstimadosController.text) ?? 1,
    );
  }

  Future<void> _guardarProducto() async {
    final costos = _calcularCostos();
    
    // Validaciones
    final error = CalculoPrecioFunctions.validarProducto(
      nombre: _nombreController.text,
      categoria: _categoriaSeleccionada,
      talla: _tallaSeleccionada,
      costos: costos,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    try {
      final margen = double.tryParse(_margenGananciaController.text) ?? 50;
      final stock = int.tryParse(_stockController.text) ?? 1;

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
      CalculoPrecioFunctions.limpiarControladores(
        nombreController: _nombreController,
        descripcionController: _descripcionController,
        stockController: _stockController,
        tiempoConfeccionController: _tiempoConfeccionController,
        tarifaHoraController: _tarifaHoraController,
        costoEquiposController: _costoEquiposController,
        alquilerMensualController: _alquilerMensualController,
        serviciosController: _serviciosController,
        gastosAdminController: _gastosAdminController,
        productosEstimadosController: _productosEstimadosController,
        margenGananciaController: _margenGananciaController,
        ivaController: _ivaController,
        materiales: _materiales,
      );
      _tabController.animateTo(0);
    });
  }
}
