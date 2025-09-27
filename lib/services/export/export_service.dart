import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../system/logging_service.dart';
import 'export_models.dart';
import 'pdf_generator_service.dart';
import 'excel_generator_service.dart';
import 'share_service.dart';

/// Servicio principal de exportación completamente funcional
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final PDFGeneratorService _pdfGenerator = PDFGeneratorService();
  final ExcelGeneratorService _excelGenerator = ExcelGeneratorService();
  final ShareService _shareService = ShareService();

  /// Exporta insights a PDF real
  Future<ExportResult> exportInsightsToPDF({
    required Map<String, dynamic> insightsData,
    required String fileName,
    ExportOptions? options,
    bool showSaveDialog = true,
  }) async {
    try {
      LoggingService.info('📄 [EXPORT] Iniciando exportación real a PDF: $fileName');
      
      final result = await _pdfGenerator.generateInsightsPDF(
        insightsData: insightsData,
        fileName: fileName,
        options: options,
      );

      if (result.success && result.filePath != null) {
        LoggingService.info('✅ [EXPORT] PDF exportado exitosamente: ${result.filePath}');
        
        // Si se solicita el diálogo de guardado, mostrar opción al usuario
        if (showSaveDialog) {
          final saveLocation = await selectSaveLocation(
            fileName: fileName,
            extension: 'pdf',
          );
          
          if (saveLocation != null) {
            final saveSuccess = await saveFileToLocation(
              filePath: result.filePath!,
              targetPath: saveLocation,
            );
            
            if (saveSuccess) {
              // Actualizar el resultado con la nueva ubicación
              return ExportResult(
                success: true,
                filePath: saveLocation,
                format: ExportFormat.pdf,
              );
            }
          }
        }
      } else {
        LoggingService.error('❌ [EXPORT] Error en exportación PDF: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico exportando PDF: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error crítico exportando PDF: $e',
        format: ExportFormat.pdf,
      );
    }
  }

  /// Exporta insights a Excel real
  Future<ExportResult> exportInsightsToExcel({
    required Map<String, dynamic> insightsData,
    required String fileName,
    ExportOptions? options,
    bool showSaveDialog = true,
  }) async {
    try {
      LoggingService.info('📊 [EXPORT] Iniciando exportación real a Excel: $fileName');
      
      final result = await _excelGenerator.generateInsightsExcel(
        insightsData: insightsData,
        fileName: fileName,
        options: options,
      );

      if (result.success && result.filePath != null) {
        LoggingService.info('✅ [EXPORT] Excel exportado exitosamente: ${result.filePath}');
        
        // Si se solicita el diálogo de guardado, mostrar opción al usuario
        if (showSaveDialog) {
          final saveLocation = await selectSaveLocation(
            fileName: fileName,
            extension: 'xlsx',
          );
          
          if (saveLocation != null) {
            final saveSuccess = await saveFileToLocation(
              filePath: result.filePath!,
              targetPath: saveLocation,
            );
            
            if (saveSuccess) {
              // Actualizar el resultado con la nueva ubicación
              return ExportResult(
                success: true,
                filePath: saveLocation,
                format: ExportFormat.excel,
              );
            }
          }
        }
      } else {
        LoggingService.error('❌ [EXPORT] Error en exportación Excel: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico exportando Excel: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error crítico exportando Excel: $e',
        format: ExportFormat.excel,
      );
    }
  }

  /// Exporta recomendaciones a PDF real
  Future<ExportResult> exportRecommendationsToPDF({
    required List<Map<String, dynamic>> recommendations,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📄 [EXPORT] Iniciando exportación real de recomendaciones a PDF: $fileName');
      
      final result = await _pdfGenerator.generateRecommendationsPDF(
        recommendations: recommendations,
        fileName: fileName,
        options: options,
      );

      if (result.success && result.filePath != null) {
        LoggingService.info('✅ [EXPORT] PDF de recomendaciones exportado exitosamente: ${result.filePath}');
      } else {
        LoggingService.error('❌ [EXPORT] Error en exportación PDF de recomendaciones: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico exportando PDF de recomendaciones: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error crítico exportando PDF de recomendaciones: $e',
        format: ExportFormat.pdf,
      );
    }
  }

  /// Exporta recomendaciones a Excel real
  Future<ExportResult> exportRecommendationsToExcel({
    required List<Map<String, dynamic>> recommendations,
    required String fileName,
    ExportOptions? options,
  }) async {
    try {
      LoggingService.info('📊 [EXPORT] Iniciando exportación real de recomendaciones a Excel: $fileName');
      
      final result = await _excelGenerator.generateRecommendationsExcel(
        recommendations: recommendations,
        fileName: fileName,
        options: options,
      );

      if (result.success && result.filePath != null) {
        LoggingService.info('✅ [EXPORT] Excel de recomendaciones exportado exitosamente: ${result.filePath}');
      } else {
        LoggingService.error('❌ [EXPORT] Error en exportación Excel de recomendaciones: ${result.errorMessage}');
      }

      return result;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico exportando Excel de recomendaciones: $e');
      return ExportResult(
        success: false,
        errorMessage: 'Error crítico exportando Excel de recomendaciones: $e',
        format: ExportFormat.excel,
      );
    }
  }

  /// Comparte un archivo exportado
  Future<bool> shareExportedFile({
    required String filePath,
    required String fileName,
    ShareOptions? shareOptions,
  }) async {
    try {
      LoggingService.info('📤 [EXPORT] Compartiendo archivo exportado: $fileName');
      
      final success = await _shareService.shareFile(
        filePath: filePath,
        fileName: fileName,
        options: shareOptions,
      );

      if (success) {
        LoggingService.info('✅ [EXPORT] Archivo compartido exitosamente: $fileName');
      } else {
        LoggingService.error('❌ [EXPORT] Error compartiendo archivo: $fileName');
      }

      return success;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico compartiendo archivo: $e');
      return false;
    }
  }

  /// Exporta y comparte en un solo paso
  Future<bool> exportAndShare({
    required Map<String, dynamic> data,
    required String fileName,
    required ExportFormat format,
    ExportOptions? exportOptions,
    ShareOptions? shareOptions,
  }) async {
    try {
      LoggingService.info('🚀 [EXPORT] Exportando y compartiendo: $fileName ($format)');
      
      ExportResult result;
      
      switch (format) {
        case ExportFormat.pdf:
          result = await exportInsightsToPDF(
            insightsData: data,
            fileName: fileName,
            options: exportOptions,
          );
          break;
        case ExportFormat.excel:
          result = await exportInsightsToExcel(
            insightsData: data,
            fileName: fileName,
            options: exportOptions,
          );
          break;
        default:
          LoggingService.error('❌ [EXPORT] Formato no soportado: $format');
          return false;
      }

      if (result.success && result.filePath != null) {
        final shareSuccess = await shareExportedFile(
          filePath: result.filePath!,
          fileName: fileName,
          shareOptions: shareOptions,
        );
        
        return shareSuccess;
      } else {
        LoggingService.error('❌ [EXPORT] Error en exportación: ${result.errorMessage}');
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error crítico en exportar y compartir: $e');
      return false;
    }
  }

  /// Selecciona la ubicación donde guardar el archivo
  Future<String?> selectSaveLocation({
    required String fileName,
    required String extension,
    String? suggestedPath,
  }) async {
    try {
      LoggingService.info('📁 [EXPORT] Seleccionando ubicación para guardar: $fileName.$extension');
      
      // Obtener directorio de documentos como ubicación por defecto
      final defaultPath = suggestedPath ?? (await getApplicationDocumentsDirectory()).path;
      
      // Usar file_picker para seleccionar ubicación
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo',
        fileName: '$fileName.$extension',
        type: extension == 'pdf' ? FileType.custom : FileType.custom,
        allowedExtensions: extension == 'pdf' ? ['pdf'] : ['xlsx'],
        initialDirectory: defaultPath,
      );
      
      if (result != null) {
        LoggingService.info('✅ [EXPORT] Ubicación seleccionada: $result');
        return result;
      } else {
        LoggingService.info('❌ [EXPORT] Usuario canceló la selección de ubicación');
        return null;
      }
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error seleccionando ubicación: $e');
      return null;
    }
  }

  /// Guarda el archivo en la ubicación seleccionada
  Future<bool> saveFileToLocation({
    required String filePath,
    required String targetPath,
  }) async {
    try {
      LoggingService.info('💾 [EXPORT] Guardando archivo en: $targetPath');
      
      final sourceFile = File(filePath);
      
      if (await sourceFile.exists()) {
        await sourceFile.copy(targetPath);
        LoggingService.info('✅ [EXPORT] Archivo guardado exitosamente');
        return true;
      } else {
        LoggingService.error('❌ [EXPORT] Archivo fuente no existe: $filePath');
        return false;
      }
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error guardando archivo: $e');
      return false;
    }
  }

  /// Genera nombre de archivo con timestamp
  String generateFileName(String baseName, String extension) {
    final now = DateTime.now();
    final timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return '${baseName}_$timestamp.$extension';
  }

  /// Valida datos antes de exportar
  bool validateExportData(Map<String, dynamic> data) {
    try {
      if (data.isEmpty) {
        LoggingService.warning('⚠️ [EXPORT] Datos vacíos para exportar');
        return false;
      }

      // Validaciones específicas según el tipo de datos
      if (data.containsKey('salesTrend')) {
        final salesTrend = data['salesTrend'];
        if (salesTrend == null || salesTrend is! Map<String, dynamic>) {
          LoggingService.warning('⚠️ [EXPORT] Datos de tendencia de ventas inválidos');
          return false;
        }
      }

      if (data.containsKey('popularProducts')) {
        final popularProducts = data['popularProducts'];
        if (popularProducts == null || popularProducts is! Map<String, dynamic>) {
          LoggingService.warning('⚠️ [EXPORT] Datos de productos populares inválidos');
          return false;
        }
      }

      LoggingService.info('✅ [EXPORT] Datos validados correctamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error validando datos: $e');
      return false;
    }
  }

  /// Obtiene estadísticas de archivos exportados
  Future<Map<String, dynamic>> getExportStats() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = await directory.list().toList();
      
      int pdfCount = 0;
      int excelCount = 0;
      int totalSize = 0;
      
      for (final file in files) {
        if (file is File) {
          final fileName = file.path.toLowerCase();
          if (fileName.endsWith('.pdf')) {
            pdfCount++;
          } else if (fileName.endsWith('.xlsx')) {
            excelCount++;
          }
          totalSize += await file.length();
        }
      }

      return {
        'totalFiles': pdfCount + excelCount,
        'pdfFiles': pdfCount,
        'excelFiles': excelCount,
        'totalSize': totalSize,
        'totalSizeFormatted': _shareService.formatFileSize(totalSize),
        'lastExport': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error obteniendo estadísticas: $e');
      return {
        'totalFiles': 0,
        'pdfFiles': 0,
        'excelFiles': 0,
        'totalSize': 0,
        'totalSizeFormatted': '0 B',
        'lastExport': null,
      };
    }
  }

  /// Limpia archivos temporales antiguos
  Future<void> cleanupOldFiles({int maxAgeInDays = 7}) async {
    try {
      LoggingService.info('🧹 [EXPORT] Limpiando archivos temporales antiguos');
      
      final directory = await getTemporaryDirectory();
      final files = await directory.list().toList();
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeInDays));
      
      int deletedCount = 0;
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }
      
      LoggingService.info('✅ [EXPORT] Limpieza completada: $deletedCount archivos eliminados');
    } catch (e) {
      LoggingService.error('❌ [EXPORT] Error en limpieza de archivos: $e');
    }
  }

  /// Muestra diálogo de exportación mejorado
  Future<void> showExportDialog(
    BuildContext context, {
    required String title,
    required Map<String, dynamic> data,
    List<Map<String, dynamic>>? recommendations,
    ExportOptions? exportOptions,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Exportar a PDF'),
              subtitle: const Text('Documento profesional con formato'),
              onTap: () async {
                Navigator.pop(context);
                await _handlePDFExport(context, data, recommendations, exportOptions);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.green),
              title: const Text('Exportar a Excel'),
              subtitle: const Text('Hojas de cálculo con datos estructurados'),
              onTap: () async {
                Navigator.pop(context);
                await _handleExcelExport(context, data, recommendations, exportOptions);
              },
            ),
            if (recommendations != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.blue),
                title: const Text('Exportar y Compartir'),
                subtitle: const Text('Genera y comparte automáticamente'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleExportAndShare(context, data, recommendations, exportOptions);
                },
              ),
            ],
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

  /// Maneja la exportación a PDF
  Future<void> _handlePDFExport(
    BuildContext context,
    Map<String, dynamic> data,
    List<Map<String, dynamic>>? recommendations,
    ExportOptions? exportOptions,
  ) async {
    try {
      if (!validateExportData(data)) {
        _showErrorMessage(context, 'Datos inválidos para exportar');
        return;
      }

      final fileName = generateFileName('insights', 'pdf');
      
      ExportResult result;
      if (recommendations != null) {
        result = await exportRecommendationsToPDF(
          recommendations: recommendations,
          fileName: fileName,
          options: exportOptions,
        );
      } else {
        result = await exportInsightsToPDF(
          insightsData: data,
          fileName: fileName,
          options: exportOptions,
        );
      }

      if (result.success) {
        _showSuccessMessage(context, 'PDF exportado exitosamente');
        _showShareOption(context, result.filePath!, fileName);
      } else {
        _showErrorMessage(context, 'Error exportando PDF: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorMessage(context, 'Error crítico exportando PDF: $e');
    }
  }

  /// Maneja la exportación a Excel
  Future<void> _handleExcelExport(
    BuildContext context,
    Map<String, dynamic> data,
    List<Map<String, dynamic>>? recommendations,
    ExportOptions? exportOptions,
  ) async {
    try {
      if (!validateExportData(data)) {
        _showErrorMessage(context, 'Datos inválidos para exportar');
        return;
      }

      final fileName = generateFileName('insights', 'xlsx');
      
      ExportResult result;
      if (recommendations != null) {
        result = await exportRecommendationsToExcel(
          recommendations: recommendations,
          fileName: fileName,
          options: exportOptions,
        );
      } else {
        result = await exportInsightsToExcel(
          insightsData: data,
          fileName: fileName,
          options: exportOptions,
        );
      }

      if (result.success) {
        _showSuccessMessage(context, 'Excel exportado exitosamente');
        _showShareOption(context, result.filePath!, fileName);
      } else {
        _showErrorMessage(context, 'Error exportando Excel: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorMessage(context, 'Error crítico exportando Excel: $e');
    }
  }

  /// Maneja la exportación y compartir
  Future<void> _handleExportAndShare(
    BuildContext context,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> recommendations,
    ExportOptions? exportOptions,
  ) async {
    try {
      if (!validateExportData(data)) {
        _showErrorMessage(context, 'Datos inválidos para exportar');
        return;
      }

      final fileName = generateFileName('recommendations', 'pdf');
      
      final result = await exportRecommendationsToPDF(
        recommendations: recommendations,
        fileName: fileName,
        options: exportOptions,
      );

      if (result.success && result.filePath != null) {
        final shareSuccess = await shareExportedFile(
          filePath: result.filePath!,
          fileName: fileName,
        );

        if (shareSuccess) {
          _showSuccessMessage(context, 'Archivo exportado y compartido exitosamente');
        } else {
          _showSuccessMessage(context, 'Archivo exportado exitosamente');
          _showShareOption(context, result.filePath!, fileName);
        }
      } else {
        _showErrorMessage(context, 'Error exportando archivo: ${result.errorMessage}');
      }
    } catch (e) {
      _showErrorMessage(context, 'Error crítico exportando y compartiendo: $e');
    }
  }

  /// Muestra opción de compartir
  void _showShareOption(BuildContext context, String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archivo Exportado'),
        content: Text('¿Deseas compartir el archivo "$fileName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await shareExportedFile(
                filePath: filePath,
                fileName: fileName,
              );
              if (success) {
                _showSuccessMessage(context, 'Archivo compartido exitosamente');
              } else {
                _showErrorMessage(context, 'Error compartiendo archivo');
              }
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  /// Muestra mensaje de éxito
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Muestra mensaje de error
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