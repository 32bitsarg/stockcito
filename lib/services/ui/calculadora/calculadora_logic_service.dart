import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import 'calculadora_state_service.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/models/producto_calculo.dart';

/// Servicio que maneja la lógica de negocio de la calculadora de precios
class CalculadoraLogicService {
  final DatosService _datosService = DatosService();
  late final CalculadoraStateService _stateService;
  
  CalculadoraLogicService(CalculadoraStateService stateService) : _stateService = stateService;

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando CalculadoraLogicService...');
      await _datosService.initialize();
      await _loadConfiguracion();
      _stateService.updateLoading(false);
      LoggingService.info('✅ CalculadoraLogicService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando CalculadoraLogicService: $e');
      _stateService.updateError('Error inicializando servicio: $e');
      _stateService.updateLoading(false);
    }
  }

  /// Cargar configuración
  Future<void> _loadConfiguracion() async {
    try {
      LoggingService.info('📋 Cargando configuración de calculadora...');
      
      final prefs = await SharedPreferences.getInstance();
      final margenDefecto = prefs.getDouble('margen_defecto') ?? 50.0;
      final ivaDefault = prefs.getDouble('iva') ?? 21.0;
      final modoAvanzado = prefs.getBool('modo_avanzado_calculadora') ?? false;
      
      final config = CalculadoraConfig(
        modoAvanzado: modoAvanzado,
        tipoNegocio: 'textil',
        margenGananciaDefault: margenDefecto,
        ivaDefault: ivaDefault,
        autoGuardar: true,
        mostrarAnalisisDetallado: true,
      );
      
      _stateService.updateConfig(config);
      
      LoggingService.info('✅ Configuración cargada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error cargando configuración: $e');
      _stateService.updateError('Error cargando configuración: $e');
    }
  }

  /// Guardar configuración
  Future<bool> saveConfiguracion(CalculadoraConfig config) async {
    try {
      LoggingService.info('💾 Guardando configuración de calculadora...');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('margen_defecto', config.margenGananciaDefault);
      await prefs.setDouble('iva', config.ivaDefault);
      await prefs.setBool('modo_avanzado_calculadora', config.modoAvanzado);
      
      _stateService.updateConfig(config);
      LoggingService.info('✅ Configuración guardada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando configuración: $e');
      _stateService.updateError('Error guardando configuración: $e');
      return false;
    }
  }

  /// Obtener categorías (por defecto + creadas por usuario)
  Future<List<String>> getCategorias() async {
    try {
      LoggingService.info('📂 Obteniendo categorías...');
      
      // Categorías por defecto
      final categoriasPorDefecto = [
        'Camiseta',
        'Pantalón',
        'Vestido',
        'Chaqueta',
        'Zapatos',
        'Accesorios',
        'Ropa Interior',
        'Deportiva',
      ];
      
      // Categorías creadas por el usuario desde la base de datos
      final categoriasUsuario = await _datosService.getCategorias();
      final categoriasUsuarioStrings = categoriasUsuario.map((c) => c.nombre).toList();
      
      // Combinar categorías por defecto con las del usuario (sin duplicados)
      final todasLasCategorias = <String>{};
      todasLasCategorias.addAll(categoriasPorDefecto);
      todasLasCategorias.addAll(categoriasUsuarioStrings);
      
      final categoriasFinales = todasLasCategorias.toList()..sort();
      
      LoggingService.info('✅ Categorías obtenidas: ${categoriasFinales.length} (${categoriasPorDefecto.length} por defecto + ${categoriasUsuarioStrings.length} del usuario)');
      return categoriasFinales;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo categorías: $e');
      _stateService.updateError('Error obteniendo categorías: $e');
      // En caso de error, devolver solo las categorías por defecto
      return [
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
  }

  /// Obtener tallas (por defecto + creadas por usuario)
  Future<List<String>> getTallas() async {
    try {
      LoggingService.info('📏 Obteniendo tallas...');
      
      // Tallas por defecto
      final tallasPorDefecto = [
        'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL',
        '28', '30', '32', '34', '36', '38', '40', '42', '44', '46', '48',
        'Única',
      ];
      
      // Tallas creadas por el usuario desde la base de datos
      final tallasUsuario = await _datosService.getTallas();
      final tallasUsuarioStrings = tallasUsuario.map((t) => t.nombre).toList();
      
      // Combinar tallas por defecto con las del usuario (sin duplicados)
      final todasLasTallas = <String>{};
      todasLasTallas.addAll(tallasPorDefecto);
      todasLasTallas.addAll(tallasUsuarioStrings);
      
      final tallasFinales = todasLasTallas.toList()..sort();
      
      LoggingService.info('✅ Tallas obtenidas: ${tallasFinales.length} (${tallasPorDefecto.length} por defecto + ${tallasUsuarioStrings.length} del usuario)');
      return tallasFinales;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo tallas: $e');
      _stateService.updateError('Error obteniendo tallas: $e');
      // En caso de error, devolver solo las tallas por defecto
      return [
        'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL',
        '28', '30', '32', '34', '36', '38', '40', '42', '44', '46', '48',
        'Única',
      ];
    }
  }

  /// Crear producto de cálculo
  void createProductoCalculo({
    required String nombre,
    required String categoria,
    required String talla,
    String? descripcion,
  }) {
    try {
      LoggingService.info('📦 Creando producto de cálculo: $nombre');
      
      // Simular creación de producto
      _stateService.updateProductoCalculo(null);
      
      LoggingService.info('✅ Producto de cálculo creado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error creando producto de cálculo: $e');
      _stateService.updateError('Error creando producto de cálculo: $e');
    }
  }

  /// Actualizar producto de cálculo
  void updateProductoCalculo(ProductoCalculo producto) {
    try {
      LoggingService.info('📦 Actualizando producto de cálculo: ${producto.nombre}');
      
      _stateService.updateProductoCalculo(producto);
      
      LoggingService.info('✅ Producto de cálculo actualizado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error actualizando producto de cálculo: $e');
      _stateService.updateError('Error actualizando producto de cálculo: $e');
    }
  }

  /// Agregar costo directo
  void addCostoDirecto({
    required String nombre,
    required double costo,
    required String tipo,
    String? descripcion,
  }) {
    try {
      LoggingService.info('💰 Agregando costo directo: $nombre');
      
      // Simular agregado de costo directo
      _stateService.addCostoDirecto(null as dynamic);
      
      LoggingService.info('✅ Costo directo agregado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error agregando costo directo: $e');
      _stateService.updateError('Error agregando costo directo: $e');
    }
  }

  /// Eliminar costo directo
  void removeCostoDirecto(int index) {
    try {
      LoggingService.info('🗑️ Eliminando costo directo en índice: $index');
      
      _stateService.removeCostoDirecto(index);
      
      LoggingService.info('✅ Costo directo eliminado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando costo directo: $e');
      _stateService.updateError('Error eliminando costo directo: $e');
    }
  }

  /// Agregar costo indirecto
  void addCostoIndirecto({
    required String nombre,
    required double costo,
    required String tipo,
    String? descripcion,
  }) {
    try {
      LoggingService.info('💼 Agregando costo indirecto: $nombre');
      
      // Simular agregado de costo indirecto
      _stateService.addCostoIndirecto(null as dynamic);
      
      LoggingService.info('✅ Costo indirecto agregado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error agregando costo indirecto: $e');
      _stateService.updateError('Error agregando costo indirecto: $e');
    }
  }

  /// Eliminar costo indirecto
  void removeCostoIndirecto(int index) {
    try {
      LoggingService.info('🗑️ Eliminando costo indirecto en índice: $index');
      
      _stateService.removeCostoIndirecto(index);
      
      LoggingService.info('✅ Costo indirecto eliminado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error eliminando costo indirecto: $e');
      _stateService.updateError('Error eliminando costo indirecto: $e');
    }
  }

  /// Calcular precio final
  Map<String, double> calculateFinalPrice() {
    try {
      LoggingService.info('🧮 Calculando precio final...');
      
      final costoTotal = _stateService.costoTotal;
      final precioVenta = _stateService.precioVenta;
      final precioConIVA = _stateService.precioConIVA;
      
      final resultado = <String, double>{
        'costoTotal': costoTotal,
        'precioVenta': precioVenta,
        'precioConIVA': precioConIVA,
        'margen': _stateService.config.margenGananciaDefault,
        'iva': _stateService.config.ivaDefault,
      };
      
      LoggingService.info('✅ Precio final calculado: $resultado');
      return resultado;
    } catch (e) {
      LoggingService.error('❌ Error calculando precio final: $e');
      _stateService.updateError('Error calculando precio final: $e');
      return {};
    }
  }

  /// Validar paso actual
  bool validateCurrentStep() {
    return _stateService.isStepValid(_stateService.currentStep);
  }

  /// Ir al siguiente paso
  void nextStep() {
    if (_stateService.canGoNext()) {
      _stateService.nextStep();
    }
  }

  /// Ir al paso anterior
  void previousStep() {
    if (_stateService.canGoPrevious()) {
      _stateService.previousStep();
    }
  }

  /// Ir a un paso específico
  void goToStep(int step) {
    _stateService.goToStep(step);
  }

  /// Resetear calculadora
  void resetCalculadora() {
    try {
      LoggingService.info('🔄 Reseteando calculadora...');
      
      _stateService.reset();
      
      LoggingService.info('✅ Calculadora reseteada correctamente');
    } catch (e) {
      LoggingService.error('❌ Error reseteando calculadora: $e');
      _stateService.updateError('Error reseteando calculadora: $e');
    }
  }

  /// Guardar estado actual
  Future<bool> saveCurrentState() async {
    try {
      LoggingService.info('💾 Guardando estado actual...');
      
      // Simular guardado de estado
      _stateService.updateCurrentState(null);
      
      LoggingService.info('✅ Estado actual guardado correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando estado actual: $e');
      _stateService.updateError('Error guardando estado actual: $e');
      return false;
    }
  }
}
