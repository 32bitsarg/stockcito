import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../system/logging_service.dart';

/// Servicio para exportar datos a diferentes formatos
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Exportar insights a PDF
  Future<void> exportInsightsToPDF({
    required Map<String, dynamic> insightsData,
    required String fileName,
  }) async {
    try {
      LoggingService.info('📄 [EXPORT] Iniciando exportación a PDF: $fileName');
      
      // Simular generación de PDF (en una implementación real usarías pdf package)
      await Future.delayed(const Duration(seconds: 2));
      
      // Crear contenido del PDF simulado
      final pdfContent = _generatePDFContent(insightsData);
      
      // Guardar archivo temporal
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsString(pdfContent);
      
      // Simular compartir archivo (en una implementación real usarías share_plus)
      LoggingService.info('📤 [EXPORT] Archivo PDF listo para compartir: ${file.path}');
      
      LoggingService.info('✅ [EXPORT] PDF exportado exitosamente: ${file.path}');
      
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error exportando a PDF: $e');
      rethrow;
    }
  }

  /// Exportar insights a Excel
  Future<void> exportInsightsToExcel({
    required Map<String, dynamic> insightsData,
    required String fileName,
  }) async {
    try {
      LoggingService.info('📊 [EXPORT] Iniciando exportación a Excel: $fileName');
      
      // Simular generación de Excel (en una implementación real usarías excel package)
      await Future.delayed(const Duration(seconds: 2));
      
      // Crear contenido del Excel simulado
      final excelContent = _generateExcelContent(insightsData);
      
      // Guardar archivo temporal
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.xlsx');
      await file.writeAsString(excelContent);
      
      // Simular compartir archivo (en una implementación real usarías share_plus)
      LoggingService.info('📤 [EXPORT] Archivo Excel listo para compartir: ${file.path}');
      
      LoggingService.info('✅ [EXPORT] Excel exportado exitosamente: ${file.path}');
      
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error exportando a Excel: $e');
      rethrow;
    }
  }

  /// Exportar recomendaciones a PDF
  Future<void> exportRecommendationsToPDF({
    required List<Map<String, dynamic>> recommendations,
    required String fileName,
  }) async {
    try {
      LoggingService.info('📄 [EXPORT] Iniciando exportación de recomendaciones a PDF: $fileName');
      
      await Future.delayed(const Duration(seconds: 1));
      
      final pdfContent = _generateRecommendationsPDFContent(recommendations);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      await file.writeAsString(pdfContent);
      
      // Simular compartir archivo (en una implementación real usarías share_plus)
      LoggingService.info('📤 [EXPORT] Archivo PDF de recomendaciones listo para compartir: ${file.path}');
      
      LoggingService.info('✅ [EXPORT] Recomendaciones PDF exportadas exitosamente');
      
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error exportando recomendaciones a PDF: $e');
      rethrow;
    }
  }

  /// Generar contenido PDF para insights
  String _generatePDFContent(Map<String, dynamic> insightsData) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RICITOS DE BB - REPORTE DE INSIGHTS ===');
    buffer.writeln('Generado el: ${DateTime.now().toString()}');
    buffer.writeln('');
    
    // Tendencia de ventas
    if (insightsData.containsKey('salesTrend')) {
      final salesTrend = insightsData['salesTrend'];
      buffer.writeln('TENDENCIA DE VENTAS');
      buffer.writeln('Crecimiento: ${salesTrend['growthPercentage']}%');
      buffer.writeln('Tendencia: ${salesTrend['trend']}');
      buffer.writeln('Mejor día: ${salesTrend['bestDay']}');
      buffer.writeln('');
    }
    
    // Productos populares
    if (insightsData.containsKey('popularProducts')) {
      final popularProducts = insightsData['popularProducts'];
      buffer.writeln('PRODUCTOS POPULARES');
      buffer.writeln('Producto top: ${popularProducts['topProduct']}');
      buffer.writeln('Ventas: ${popularProducts['salesCount']}');
      buffer.writeln('');
    }
    
    // Recomendaciones de stock
    if (insightsData.containsKey('stockRecommendations')) {
      final recommendations = insightsData['stockRecommendations'] as List;
      buffer.writeln('RECOMENDACIONES DE STOCK');
      for (int i = 0; i < recommendations.length; i++) {
        final rec = recommendations[i];
        buffer.writeln('${i + 1}. ${rec['productName']}');
        buffer.writeln('   Acción: ${rec['action']}');
        buffer.writeln('   Detalles: ${rec['details']}');
        buffer.writeln('   Urgencia: ${rec['urgency']}');
        buffer.writeln('');
      }
    }
    
    buffer.writeln('=== FIN DEL REPORTE ===');
    
    return buffer.toString();
  }

  /// Generar contenido Excel para insights
  String _generateExcelContent(Map<String, dynamic> insightsData) {
    final buffer = StringBuffer();
    
    // Simular formato CSV (simplificado para Excel)
    buffer.writeln('RICITOS DE BB - REPORTE DE INSIGHTS');
    buffer.writeln('Generado el,${DateTime.now().toString()}');
    buffer.writeln('');
    
    // Tendencia de ventas
    if (insightsData.containsKey('salesTrend')) {
      final salesTrend = insightsData['salesTrend'];
      buffer.writeln('TENDENCIA DE VENTAS');
      buffer.writeln('Crecimiento (%),Tendencia,Mejor día');
      buffer.writeln('${salesTrend['growthPercentage']},${salesTrend['trend']},${salesTrend['bestDay']}');
      buffer.writeln('');
    }
    
    // Productos populares
    if (insightsData.containsKey('popularProducts')) {
      final popularProducts = insightsData['popularProducts'];
      buffer.writeln('PRODUCTOS POPULARES');
      buffer.writeln('Producto,Ventas,Categoría');
      buffer.writeln('${popularProducts['topProduct']},${popularProducts['salesCount']},${popularProducts['category']}');
      buffer.writeln('');
    }
    
    // Recomendaciones de stock
    if (insightsData.containsKey('stockRecommendations')) {
      final recommendations = insightsData['stockRecommendations'] as List;
      buffer.writeln('RECOMENDACIONES DE STOCK');
      buffer.writeln('Producto,Acción,Detalles,Urgencia');
      for (final rec in recommendations) {
        buffer.writeln('${rec['productName']},${rec['action']},${rec['details']},${rec['urgency']}');
      }
    }
    
    return buffer.toString();
  }

  /// Generar contenido PDF para recomendaciones
  String _generateRecommendationsPDFContent(List<Map<String, dynamic>> recommendations) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== RICITOS DE BB - RECOMENDACIONES DE IA ===');
    buffer.writeln('Generado el: ${DateTime.now().toString()}');
    buffer.writeln('Total de recomendaciones: ${recommendations.length}');
    buffer.writeln('');
    
    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      buffer.writeln('RECOMENDACIÓN ${i + 1}');
      buffer.writeln('Título: ${rec['title']}');
      buffer.writeln('Mensaje: ${rec['message']}');
      buffer.writeln('Acción: ${rec['action']}');
      buffer.writeln('Prioridad: ${rec['priority']}');
      buffer.writeln('Estado: ${rec['status']}');
      buffer.writeln('Creado: ${rec['createdAt']}');
      buffer.writeln('');
    }
    
    buffer.writeln('=== FIN DEL REPORTE ===');
    
    return buffer.toString();
  }

  /// Obtener nombre de archivo con timestamp
  String generateFileName(String baseName, String extension) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${baseName}_$timestamp.$extension';
  }

  /// Mostrar diálogo de exportación
  Future<void> showExportDialog(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> data,
    String? recommendationsData,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exportar a PDF'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final fileName = generateFileName('insights', 'pdf');
                  await exportInsightsToPDF(
                    insightsData: data,
                    fileName: fileName,
                  );
                  _showSuccessMessage(context, 'PDF exportado exitosamente');
                } catch (e) {
                  _showErrorMessage(context, 'Error exportando PDF: $e');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exportar a Excel'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final fileName = generateFileName('insights', 'xlsx');
                  await exportInsightsToExcel(
                    insightsData: data,
                    fileName: fileName,
                  );
                  _showSuccessMessage(context, 'Excel exportado exitosamente');
                } catch (e) {
                  _showErrorMessage(context, 'Error exportando Excel: $e');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
