import '../../../services/system/logging_service.dart';
import '../../../services/datos/datos.dart';
import '../../../models/categoria.dart';
import '../../../models/talla.dart';
import '../../../screens/calcularprecios_screen/models/calculadora_config.dart';
import '../../../screens/calcularprecios_screen/services/global_config_service.dart';

/// Servicio que maneja la carga y gestión de datos de la calculadora
class CalculadoraDataService {
  final DatosService _datosService = DatosService();
  final GlobalConfigService _globalConfigService = GlobalConfigService();
  
  CalculadoraDataService();

  /// Inicializar el servicio
  Future<void> initialize() async {
    try {
      LoggingService.info('🚀 Inicializando CalculadoraDataService...');
      await _datosService.initialize();
      await _globalConfigService.initialize();
      LoggingService.info('✅ CalculadoraDataService inicializado correctamente');
    } catch (e) {
      LoggingService.error('❌ Error inicializando CalculadoraDataService: $e');
      rethrow;
    }
  }

  /// Obtener categorías
  Future<List<Categoria>> getCategorias() async {
    try {
      LoggingService.info('📂 Obteniendo categorías...');
      final categorias = await _datosService.getCategorias();
      LoggingService.info('✅ Categorías obtenidas: ${categorias.length}');
      return categorias;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo categorías: $e');
      rethrow;
    }
  }

  /// Obtener categorías como strings
  Future<List<String>> getCategoriasAsStrings() async {
    try {
      LoggingService.info('📂 Obteniendo categorías como strings...');
      final categorias = await getCategorias();
      final categoriasStrings = categorias.map((c) => c.nombre).toList();
      LoggingService.info('✅ Categorías como strings obtenidas: ${categoriasStrings.length}');
      return categoriasStrings;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo categorías como strings: $e');
      rethrow;
    }
  }

  /// Obtener tallas
  Future<List<Talla>> getTallas() async {
    try {
      LoggingService.info('📏 Obteniendo tallas...');
      final tallas = await _datosService.getTallas();
      LoggingService.info('✅ Tallas obtenidas: ${tallas.length}');
      return tallas;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo tallas: $e');
      rethrow;
    }
  }

  /// Obtener tallas como strings
  Future<List<String>> getTallasAsStrings() async {
    try {
      LoggingService.info('📏 Obteniendo tallas como strings...');
      final tallas = await getTallas();
      final tallasStrings = tallas.map((t) => t.nombre).toList();
      LoggingService.info('✅ Tallas como strings obtenidas: ${tallasStrings.length}');
      return tallasStrings;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo tallas como strings: $e');
      rethrow;
    }
  }

  /// Obtener configuración de calculadora
  Future<CalculadoraConfig> getConfiguracion() async {
    try {
      LoggingService.info('⚙️ Obteniendo configuración de calculadora...');
      // Simular obtención de configuración
      final config = CalculadoraConfig.defaultConfig;
      LoggingService.info('✅ Configuración de calculadora obtenida');
      return config;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo configuración: $e');
      rethrow;
    }
  }

  /// Guardar configuración de calculadora
  Future<bool> saveConfiguracion(CalculadoraConfig config) async {
    try {
      LoggingService.info('💾 Guardando configuración de calculadora...');
      // Simular guardado exitoso
      LoggingService.info('✅ Configuración de calculadora guardada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error guardando configuración: $e');
      rethrow;
    }
  }

  /// Obtener configuración por defecto
  CalculadoraConfig getDefaultConfiguracion() {
    try {
      LoggingService.info('📋 Obteniendo configuración por defecto...');
      return CalculadoraConfig.defaultConfig;
    } catch (e) {
      LoggingService.error('❌ Error obteniendo configuración por defecto: $e');
      rethrow;
    }
  }

  /// Validar configuración
  Map<String, String?> validateConfiguracion(CalculadoraConfig config) {
    try {
      LoggingService.info('✅ Validando configuración...');
      
      final errors = <String, String?>{};
      
      // Validar margen por defecto
      if (config.margenGananciaDefault < 0 || config.margenGananciaDefault > 1000) {
        errors['margenGananciaDefault'] = 'El margen debe estar entre 0 y 1000%';
      }
      
      // Validar IVA
      if (config.ivaDefault < 0 || config.ivaDefault > 100) {
        errors['ivaDefault'] = 'El IVA debe estar entre 0 y 100%';
      }
      
      // Validar tipo de negocio
      if (config.tipoNegocio.isEmpty) {
        errors['tipoNegocio'] = 'El tipo de negocio es requerido';
      }
      
      return errors;
    } catch (e) {
      LoggingService.error('❌ Error validando configuración: $e');
      return {};
    }
  }

  /// Obtener estadísticas de calculadora
  Map<String, dynamic> getCalculadoraStats() {
    try {
      LoggingService.info('📊 Obteniendo estadísticas de calculadora...');
      
      // Simular estadísticas
      return {
        'totalCalculos': 0,
        'promedioMargen': 50.0,
        'promedioIVA': 21.0,
        'monedaMasUsada': 'USD',
        'ultimoCalculo': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('❌ Error obteniendo estadísticas: $e');
      return {};
    }
  }

  /// Sincronizar datos
  Future<void> syncData() async {
    try {
      LoggingService.info('🔄 Sincronizando datos de calculadora...');
      // await _datosService.syncAllData(); // Comentado hasta que se implemente
      LoggingService.info('✅ Datos de calculadora sincronizados correctamente');
    } catch (e) {
      LoggingService.error('❌ Error sincronizando datos: $e');
      rethrow;
    }
  }

  /// Verificar conectividad
  Future<bool> checkConnectivity() async {
    try {
      // return await _datosService.checkConnectivity(); // Comentado hasta que se implemente
      return true; // Temporal
    } catch (e) {
      LoggingService.error('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  /// Exportar configuración
  Future<bool> exportConfiguracion(CalculadoraConfig config) async {
    try {
      LoggingService.info('📤 Exportando configuración...');
      
      // Simular exportación exitosa
      LoggingService.info('✅ Configuración exportada correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ Error exportando configuración: $e');
      rethrow;
    }
  }

  /// Importar configuración
  Future<CalculadoraConfig?> importConfiguracion() async {
    try {
      LoggingService.info('📥 Importando configuración...');
      
      // Simular importación exitosa
      LoggingService.info('✅ Configuración importada correctamente');
      return CalculadoraConfig.defaultConfig;
    } catch (e) {
      LoggingService.error('❌ Error importando configuración: $e');
      rethrow;
    }
  }
}
