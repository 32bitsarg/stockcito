import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../system/logging_service.dart';
import 'export_models.dart';

/// Servicio para generar archivos PDF reales
class PDFGeneratorService {
  static final PDFGeneratorService _instance = PDFGeneratorService._internal();
  factory PDFGeneratorService() => _instance;
  PDFGeneratorService._internal();

  /// Genera un PDF real con insights
  Future<ExportResult> generateInsightsPDF({
    required Map<String, dynamic> insightsData,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📄 [PDF] Generando PDF real para insights: $fileName');
      
      final pdf = pw.Document();
      final exportOptions = options ?? ExportOptions();
      
      // Página principal
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(exportOptions.customTitle ?? 'Reporte de Insights'),
              pw.SizedBox(height: 20),
              _buildInsightsContent(insightsData),
              if (exportOptions.includeMetadata) ...[
                pw.SizedBox(height: 20),
                _buildMetadata(),
              ],
            ];
          },
        ),
      );

      // Guardar archivo PDF real
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      LoggingService.info('✅ [PDF] PDF generado exitosamente: ${file.path}');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        format: ExportFormat.pdf,
      );
    } catch (e) {
      LoggingService.error('❌ [PDF] Error generando PDF: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error generando PDF: $e',
        format: ExportFormat.pdf,
      );
    }
  }

  /// Genera un PDF real con recomendaciones
  Future<ExportResult> generateRecommendationsPDF({
    required List<Map<String, dynamic>> recommendations,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📄 [PDF] Generando PDF real para recomendaciones: $fileName');
      
      final pdf = pw.Document();
      final exportOptions = options ?? ExportOptions();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              _buildHeader(exportOptions.customTitle ?? 'Recomendaciones de IA'),
              pw.SizedBox(height: 20),
              _buildRecommendationsContent(recommendations),
              if (exportOptions.includeMetadata) ...[
                pw.SizedBox(height: 20),
                _buildMetadata(),
              ],
            ];
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.pdf');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      LoggingService.info('✅ [PDF] PDF de recomendaciones generado exitosamente: ${file.path}');
      
      return ExportResult(
        success: true,
        filePath: file.path,
        format: ExportFormat.pdf,
      );
    } catch (e) {
      LoggingService.error('❌ [PDF] Error generando PDF de recomendaciones: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error generando PDF de recomendaciones: $e',
        format: ExportFormat.pdf,
      );
    }
  }

  /// Construye el header del PDF
  pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Stockcito',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el: ${DateTime.now().toString()}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido de insights
  pw.Widget _buildInsightsContent(Map<String, dynamic> insightsData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Tendencia de ventas
        if (insightsData.containsKey('salesTrend')) ...[
          _buildSectionTitle('TENDENCIA DE VENTAS'),
          pw.SizedBox(height: 8),
          _buildSalesTrendSection(insightsData['salesTrend']),
          pw.SizedBox(height: 16),
        ],
        
        // Productos populares
        if (insightsData.containsKey('popularProducts')) ...[
          _buildSectionTitle('PRODUCTOS POPULARES'),
          pw.SizedBox(height: 8),
          _buildPopularProductsSection(insightsData['popularProducts']),
          pw.SizedBox(height: 16),
        ],
        
        // Recomendaciones de stock
        if (insightsData.containsKey('stockRecommendations')) ...[
          _buildSectionTitle('RECOMENDACIONES DE STOCK'),
          pw.SizedBox(height: 8),
          _buildStockRecommendationsSection(insightsData['stockRecommendations']),
        ],
      ],
    );
  }

  /// Construye el contenido de recomendaciones
  pw.Widget _buildRecommendationsContent(List<Map<String, dynamic>> recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Total de recomendaciones: ${recommendations.length}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 16),
        ...recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final rec = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'RECOMENDACIÓN ${index + 1}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildRecommendationField('Título', rec['title']),
                _buildRecommendationField('Mensaje', rec['message']),
                _buildRecommendationField('Acción', rec['action']),
                _buildRecommendationField('Prioridad', rec['priority']?.toString()),
                _buildRecommendationField('Estado', rec['status']),
                _buildRecommendationField('Creado', rec['createdAt']),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Construye una sección de tendencia de ventas
  pw.Widget _buildSalesTrendSection(Map<String, dynamic> salesTrend) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Crecimiento', '${salesTrend['growthPercentage']}%'),
          _buildInfoRow('Tendencia', salesTrend['trend']),
          _buildInfoRow('Mejor día', salesTrend['bestDay']),
        ],
      ),
    );
  }

  /// Construye una sección de productos populares
  pw.Widget _buildPopularProductsSection(Map<String, dynamic> popularProducts) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Producto top', popularProducts['topProduct']),
          _buildInfoRow('Ventas', popularProducts['salesCount']?.toString()),
          _buildInfoRow('Categoría', popularProducts['category']),
        ],
      ),
    );
  }

  /// Construye una sección de recomendaciones de stock
  pw.Widget _buildStockRecommendationsSection(List<dynamic> recommendations) {
    return pw.Column(
      children: recommendations.asMap().entries.map((entry) {
        final index = entry.key;
        final rec = entry.value;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${index + 1}. ${rec['productName']}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _buildInfoRow('Acción', rec['action']),
              _buildInfoRow('Detalles', rec['details']),
              _buildInfoRow('Urgencia', rec['urgency']),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Construye un título de sección
  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 16,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue700,
      ),
    );
  }

  /// Construye una fila de información
  pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? 'N/A',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un campo de recomendación
  pw.Widget _buildRecommendationField(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? 'N/A',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la metadata del documento
  pw.Widget _buildMetadata() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL DOCUMENTO',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Generado por', 'Stockcito'),
          _buildInfoRow('Fecha de generación', DateTime.now().toString()),
          _buildInfoRow('Versión de la app', '1.1.0-alpha.1'),
        ],
      ),
    );
  }
}
