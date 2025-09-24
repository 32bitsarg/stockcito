import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/producto.dart';
import 'package:stockcito/models/venta.dart';
import 'package:stockcito/models/cliente.dart';

/// Servicio de exportación de datos a diferentes formatos
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Exporta productos a CSV
  Future<String> exportProductosToCSV(List<Producto> productos) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'productos_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      final csvContent = StringBuffer();
      
      // Encabezados
      csvContent.writeln('ID,Nombre,Categoria,Talla,Stock,Precio Venta,Costo Total,Margen,Fecha Creacion');
      
      // Datos
      for (final producto in productos) {
        csvContent.writeln([
          producto.id,
          _escapeCsvField(producto.nombre),
          _escapeCsvField(producto.categoria),
          _escapeCsvField(producto.talla),
          producto.stock,
          producto.precioVenta.toStringAsFixed(2),
          producto.costoTotal.toStringAsFixed(2),
          producto.margenGanancia.toStringAsFixed(2),
          producto.fechaCreacion.toIso8601String(),
        ].join(','));
      }

      await file.writeAsString(csvContent.toString());
      LoggingService.info('Productos exportados a CSV: $fileName');
      return file.path;
    } catch (e) {
      LoggingService.error('Error exportando productos a CSV: $e');
      rethrow;
    }
  }

  /// Exporta ventas a CSV
  Future<String> exportVentasToCSV(List<Venta> ventas) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'ventas_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      final csvContent = StringBuffer();
      
      // Encabezados
      csvContent.writeln('ID,Cliente,Fecha,Estado,Metodo Pago,Total,Productos');
      
      // Datos
      for (final venta in ventas) {
        final productosStr = venta.items.map((p) => '${p.nombreProducto}(${p.cantidad})').join('; ');
        csvContent.writeln([
          venta.id,
          _escapeCsvField(venta.cliente),
          venta.fecha.toIso8601String(),
          _escapeCsvField(venta.estado),
          _escapeCsvField(venta.metodoPago),
          venta.total.toStringAsFixed(2),
          _escapeCsvField(productosStr),
        ].join(','));
      }

      await file.writeAsString(csvContent.toString());
      LoggingService.info('Ventas exportadas a CSV: $fileName');
      return file.path;
    } catch (e) {
      LoggingService.error('Error exportando ventas a CSV: $e');
      rethrow;
    }
  }

  /// Exporta clientes a CSV
  Future<String> exportClientesToCSV(List<Cliente> clientes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'clientes_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      final csvContent = StringBuffer();
      
      // Encabezados
      csvContent.writeln('ID,Nombre,Email,Telefono,Direccion,Fecha Registro,Total Compras');
      
      // Datos
      for (final cliente in clientes) {
        csvContent.writeln([
          cliente.id,
          _escapeCsvField(cliente.nombre),
          _escapeCsvField(cliente.email),
          _escapeCsvField(cliente.telefono),
          _escapeCsvField(cliente.direccion),
          cliente.fechaRegistro.toIso8601String(),
          cliente.totalCompras.toStringAsFixed(2),
        ].join(','));
      }

      await file.writeAsString(csvContent.toString());
      LoggingService.info('Clientes exportados a CSV: $fileName');
      return file.path;
    } catch (e) {
      LoggingService.error('Error exportando clientes a CSV: $e');
      rethrow;
    }
  }

  /// Exporta configuración a JSON
  Future<String> exportConfiguracionToJSON(Map<String, dynamic> configuracion) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'configuracion_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      final configData = {
        'version': '1.1.0-alpha.1',
        'fecha_exportacion': DateTime.now().toIso8601String(),
        'configuracion': configuracion,
      };

      await file.writeAsString(jsonEncode(configData));
      LoggingService.info('Configuración exportada a JSON: $fileName');
      return file.path;
    } catch (e) {
      LoggingService.error('Error exportando configuración a JSON: $e');
      rethrow;
    }
  }

  /// Exporta reporte completo a JSON
  Future<String> exportReporteCompletoToJSON({
    required List<Producto> productos,
    required List<Venta> ventas,
    required List<Cliente> clientes,
    required Map<String, dynamic> metricas,
  }) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'reporte_completo_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');

      final reporteData = {
        'version': '1.1.0-alpha.1',
        'fecha_exportacion': DateTime.now().toIso8601String(),
        'metricas': metricas,
        'productos': productos.map((p) => p.toMap()).toList(),
        'ventas': ventas.map((v) => v.toMap()).toList(),
        'clientes': clientes.map((c) => c.toMap()).toList(),
      };

      await file.writeAsString(jsonEncode(reporteData));
      LoggingService.info('Reporte completo exportado a JSON: $fileName');
      return file.path;
    } catch (e) {
      LoggingService.error('Error exportando reporte completo a JSON: $e');
      rethrow;
    }
  }

  /// Importa configuración desde JSON
  Future<Map<String, dynamic>> importConfiguracionFromJSON(String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      if (data['version'] == null || data['configuracion'] == null) {
        throw Exception('Formato de archivo inválido');
      }

      LoggingService.info('Configuración importada desde JSON: $filePath');
      return data['configuracion'] as Map<String, dynamic>;
    } catch (e) {
      LoggingService.error('Error importando configuración desde JSON: $e');
      rethrow;
    }
  }

  /// Escapa campos CSV
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Obtiene la ruta del directorio de documentos
  Future<String> getDocumentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Lista archivos de exportación disponibles
  Future<List<FileSystemEntity>> listExportFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();
      return files.where((file) => 
        file.path.endsWith('.csv') || 
        file.path.endsWith('.json')
      ).toList();
    } catch (e) {
      LoggingService.error('Error listando archivos de exportación: $e');
      return [];
    }
  }

  /// Elimina archivo de exportación
  Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        LoggingService.info('Archivo de exportación eliminado: $filePath');
      }
    } catch (e) {
      LoggingService.error('Error eliminando archivo de exportación: $e');
      rethrow;
    }
  }
}
