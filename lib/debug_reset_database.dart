import 'package:stockcito/services/datos/database/local_database_service.dart';
import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/system/logging_service.dart';

class DebugResetDatabase {
  static Future<void> resetAndReloadDefaults() async {
    try {
      LoggingService.info('🔄 Iniciando reset de base de datos...');
      
      final localDb = LocalDatabaseService();
      
      // Limpiar tablas de categorías y tallas
      LoggingService.info('🗑️ Limpiando tablas...');
      await localDb.deleteAllCategorias();
      await localDb.deleteAllTallas();
      
      LoggingService.info('✅ Tablas limpiadas');
      
      // Recargar datos por defecto
      LoggingService.info('📥 Cargando datos por defecto...');
      final datosService = DatosService();
      
      final categorias = await datosService.getCategorias();
      final tallas = await datosService.getTallas();
      
      LoggingService.info('📊 Categorías cargadas: ${categorias.length}');
      LoggingService.info('📊 Tallas cargadas: ${tallas.length}');
      
      for (var cat in categorias) {
        LoggingService.info('  - Categoría: ${cat.nombre} (Default: ${cat.isDefault})');
      }
      
      for (var talla in tallas) {
        LoggingService.info('  - Talla: ${talla.nombre} (Default: ${talla.isDefault})');
      }
      
      LoggingService.info('✅ Reset completado exitosamente');
      
    } catch (e) {
      LoggingService.error('❌ Error en reset de base de datos: $e');
    }
  }

  /// Resetea solo las tallas
  static Future<void> resetTallas() async {
    try {
      LoggingService.info('🔄 Iniciando reset de tallas...');
      
      final localDb = LocalDatabaseService();
      
      // Limpiar tabla de tallas
      LoggingService.info('🗑️ Limpiando tabla de tallas...');
      await localDb.deleteAllTallas();
      
      LoggingService.info('✅ Tabla de tallas limpiada');
      
      // Recargar tallas por defecto
      LoggingService.info('📥 Cargando tallas por defecto...');
      final datosService = DatosService();
      
      final tallas = await datosService.getTallas();
      
      LoggingService.info('📊 Tallas cargadas: ${tallas.length}');
      
      for (var talla in tallas) {
        LoggingService.info('  - Talla: ${talla.nombre} (ID: ${talla.id}, Default: ${talla.isDefault})');
      }
      
      LoggingService.info('✅ Reset de tallas completado exitosamente');
      
    } catch (e) {
      LoggingService.error('❌ Error en reset de tallas: $e');
    }
  }
}

