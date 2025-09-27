import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../system/logging_service.dart';
import 'export_models.dart';

/// Servicio para generar archivos Excel reales
class ExcelGeneratorService {
  static final ExcelGeneratorService _instance = ExcelGeneratorService._internal();
  factory ExcelGeneratorService() => _instance;
  ExcelGeneratorService._internal();

  /// Genera un Excel real con insights
  Future<ExportResult> generateInsightsExcel({
    required Map<String, dynamic> insightsData,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📊 [EXCEL] Generando Excel real para insights: $fileName');
      
      final excel = Excel.createExcel();
      final exportOptions = options ?? ExportOptions();
      
      // Eliminar hoja por defecto
      excel.delete('Sheet1');
      
      // Hoja principal de insights
      final insightsSheet = excel['Insights'];
      _buildInsightsSheet(insightsSheet, insightsData, exportOptions);
      
      // Hoja de resumen
      final summarySheet = excel['Resumen'];
      _buildSummarySheet(summarySheet, insightsData);
      
      // Hoja de metadata
      if (exportOptions.includeMetadata) {
        final metadataSheet = excel['Metadata'];
        _buildMetadataSheet(metadataSheet);
      }

      // Guardar archivo Excel real
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.xlsx');
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        
        LoggingService.info('✅ [EXCEL] Excel generado exitosamente: ${file.path}');
        
        return ExportResult(
          success: true,
          filePath: file.path,
          format: ExportFormat.excel,
        );
      } else {
        throw Exception('Error al generar bytes del Excel');
      }
    } catch (e) {
      LoggingService.error('❌ [EXCEL] Error generando Excel: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error generando Excel: $e',
        format: ExportFormat.excel,
      );
    }
  }

  /// Genera un Excel real con recomendaciones
  Future<ExportResult> generateRecommendationsExcel({
    required List<Map<String, dynamic>> recommendations,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📊 [EXCEL] Generando Excel real para recomendaciones: $fileName');
      
      final excel = Excel.createExcel();
      final exportOptions = options ?? ExportOptions();
      
      // Eliminar hoja por defecto
      excel.delete('Sheet1');
      
      // Hoja principal de recomendaciones
      final recommendationsSheet = excel['Recomendaciones'];
      _buildRecommendationsSheet(recommendationsSheet, recommendations);
      
      // Hoja de resumen
      final summarySheet = excel['Resumen'];
      _buildRecommendationsSummarySheet(summarySheet, recommendations);
      
      // Hoja de metadata
      if (exportOptions.includeMetadata) {
        final metadataSheet = excel['Metadata'];
        _buildMetadataSheet(metadataSheet);
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.xlsx');
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        
        LoggingService.info('✅ [EXCEL] Excel de recomendaciones generado exitosamente: ${file.path}');
        
        return ExportResult(
          success: true,
          filePath: file.path,
          format: ExportFormat.excel,
        );
      } else {
        throw Exception('Error al generar bytes del Excel');
      }
    } catch (e) {
      LoggingService.error('❌ [EXCEL] Error generando Excel de recomendaciones: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error generando Excel de recomendaciones: $e',
        format: ExportFormat.excel,
      );
    }
  }

  /// Construye la hoja de insights
  void _buildInsightsSheet(Sheet sheet, Map<String, dynamic> insightsData, ExportOptions options) {
    int row = 0;
    
    // Header
    _setCellValue(sheet, row, 0, 'Stockcito - REPORTE DE INSIGHTS', bold: true, fontSize: 16);
    _mergeCells(sheet, row, 0, row, 4);
    row += 2;
    
    _setCellValue(sheet, row, 0, 'Generado el:', bold: true);
    _setCellValue(sheet, row, 1, DateTime.now().toString());
    row += 2;
    
    // Tendencia de ventas
    if (insightsData.containsKey('salesTrend')) {
      _setCellValue(sheet, row, 0, 'TENDENCIA DE VENTAS', bold: true, fontSize: 14);
      _mergeCells(sheet, row, 0, row, 4);
      row += 1;
      
      final salesTrend = insightsData['salesTrend'];
      _setCellValue(sheet, row, 0, 'Crecimiento (%):', bold: true);
      _setCellValue(sheet, row, 1, '${salesTrend['growthPercentage']}%');
      row += 1;
      
      _setCellValue(sheet, row, 0, 'Tendencia:', bold: true);
      _setCellValue(sheet, row, 1, salesTrend['trend']);
      row += 1;
      
      _setCellValue(sheet, row, 0, 'Mejor día:', bold: true);
      _setCellValue(sheet, row, 1, salesTrend['bestDay']);
      row += 2;
    }
    
    // Productos populares
    if (insightsData.containsKey('popularProducts')) {
      _setCellValue(sheet, row, 0, 'PRODUCTOS POPULARES', bold: true, fontSize: 14);
      _mergeCells(sheet, row, 0, row, 4);
      row += 1;
      
      final popularProducts = insightsData['popularProducts'];
      _setCellValue(sheet, row, 0, 'Producto top:', bold: true);
      _setCellValue(sheet, row, 1, popularProducts['topProduct'] ?? 'N/A');
      row += 1;
      
      _setCellValue(sheet, row, 0, 'Ventas:', bold: true);
      _setCellValue(sheet, row, 1, popularProducts['salesCount']?.toString() ?? 'N/A');
      row += 1;
      
      _setCellValue(sheet, row, 0, 'Categoría:', bold: true);
      _setCellValue(sheet, row, 1, popularProducts['category'] ?? 'N/A');
      row += 2;
    }
    
    // Recomendaciones de stock
    if (insightsData.containsKey('stockRecommendations')) {
      _setCellValue(sheet, row, 0, 'RECOMENDACIONES DE STOCK', bold: true, fontSize: 14);
      _mergeCells(sheet, row, 0, row, 4);
      row += 1;
      
      // Headers de tabla
      _setCellValue(sheet, row, 0, 'Producto', bold: true);
      _setCellValue(sheet, row, 1, 'Acción', bold: true);
      _setCellValue(sheet, row, 2, 'Detalles', bold: true);
      _setCellValue(sheet, row, 3, 'Urgencia', bold: true);
      row += 1;
      
      final recommendations = insightsData['stockRecommendations'] as List;
      for (final rec in recommendations) {
        _setCellValue(sheet, row, 0, rec['productName']);
        _setCellValue(sheet, row, 1, rec['action']);
        _setCellValue(sheet, row, 2, rec['details']);
        _setCellValue(sheet, row, 3, rec['urgency']);
        row += 1;
      }
    }
  }

  /// Construye la hoja de recomendaciones
  void _buildRecommendationsSheet(Sheet sheet, List<Map<String, dynamic>> recommendations) {
    int row = 0;
    
    // Header
    _setCellValue(sheet, row, 0, 'Stockcito - RECOMENDACIONES DE IA', bold: true, fontSize: 16);
    _mergeCells(sheet, row, 0, row, 5);
    row += 2;
    
    _setCellValue(sheet, row, 0, 'Total de recomendaciones:', bold: true);
    _setCellValue(sheet, row, 1, recommendations.length.toString());
    row += 2;
    
    // Headers de tabla
    _setCellValue(sheet, row, 0, 'ID', bold: true);
    _setCellValue(sheet, row, 1, 'Título', bold: true);
    _setCellValue(sheet, row, 2, 'Mensaje', bold: true);
    _setCellValue(sheet, row, 3, 'Acción', bold: true);
    _setCellValue(sheet, row, 4, 'Prioridad', bold: true);
    _setCellValue(sheet, row, 5, 'Estado', bold: true);
    _setCellValue(sheet, row, 6, 'Creado', bold: true);
    row += 1;
    
    // Datos de recomendaciones
    for (int i = 0; i < recommendations.length; i++) {
      final rec = recommendations[i];
      _setCellValue(sheet, row, 0, (i + 1).toString());
      _setCellValue(sheet, row, 1, rec['title']);
      _setCellValue(sheet, row, 2, rec['message']);
      _setCellValue(sheet, row, 3, rec['action']);
      _setCellValue(sheet, row, 4, rec['priority']?.toString() ?? 'N/A');
      _setCellValue(sheet, row, 5, rec['status']);
      _setCellValue(sheet, row, 6, rec['createdAt']);
      row += 1;
    }
  }

  /// Construye la hoja de resumen
  void _buildSummarySheet(Sheet sheet, Map<String, dynamic> insightsData) {
    int row = 0;
    
    _setCellValue(sheet, row, 0, 'RESUMEN EJECUTIVO', bold: true, fontSize: 16);
    _mergeCells(sheet, row, 0, row, 2);
    row += 2;
    
    _setCellValue(sheet, row, 0, 'Fecha de generación:', bold: true);
    _setCellValue(sheet, row, 1, DateTime.now().toString());
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Tipo de reporte:', bold: true);
    _setCellValue(sheet, row, 1, 'Insights de IA');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Aplicación:', bold: true);
    _setCellValue(sheet, row, 1, 'Stockcito');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Versión:', bold: true);
    _setCellValue(sheet, row, 1, '1.1.0-alpha.1');
  }

  /// Construye la hoja de resumen de recomendaciones
  void _buildRecommendationsSummarySheet(Sheet sheet, List<Map<String, dynamic>> recommendations) {
    int row = 0;
    
    _setCellValue(sheet, row, 0, 'RESUMEN DE RECOMENDACIONES', bold: true, fontSize: 16);
    _mergeCells(sheet, row, 0, row, 2);
    row += 2;
    
    _setCellValue(sheet, row, 0, 'Total de recomendaciones:', bold: true);
    _setCellValue(sheet, row, 1, recommendations.length.toString());
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Fecha de generación:', bold: true);
    _setCellValue(sheet, row, 1, DateTime.now().toString());
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Tipo de reporte:', bold: true);
    _setCellValue(sheet, row, 1, 'Recomendaciones de IA');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Aplicación:', bold: true);
    _setCellValue(sheet, row, 1, 'Stockcito');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Versión:', bold: true);
    _setCellValue(sheet, row, 1, '1.1.0-alpha.1');
  }

  /// Construye la hoja de metadata
  void _buildMetadataSheet(Sheet sheet) {
    int row = 0;
    
    _setCellValue(sheet, row, 0, 'INFORMACIÓN DEL DOCUMENTO', bold: true, fontSize: 16);
    _mergeCells(sheet, row, 0, row, 2);
    row += 2;
    
    _setCellValue(sheet, row, 0, 'Generado por:', bold: true);
    _setCellValue(sheet, row, 1, 'Stockcito');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Fecha de generación:', bold: true);
    _setCellValue(sheet, row, 1, DateTime.now().toString());
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Versión de la app:', bold: true);
    _setCellValue(sheet, row, 1, '1.1.0-alpha.1');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Formato:', bold: true);
    _setCellValue(sheet, row, 1, 'Excel (.xlsx)');
    row += 1;
    
    _setCellValue(sheet, row, 0, 'Codificación:', bold: true);
    _setCellValue(sheet, row, 1, 'UTF-8');
  }

  /// Establece el valor de una celda con formato
  void _setCellValue(Sheet sheet, int row, int col, String value, {bool bold = false, int fontSize = 10}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    
    if (bold || fontSize != 10) {
      cell.cellStyle = CellStyle(
        bold: bold,
        fontSize: fontSize,
      );
    }
  }

  /// Fusiona celdas
  void _mergeCells(Sheet sheet, int startRow, int startCol, int endRow, int endCol) {
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: startRow),
                CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow));
  }
}
