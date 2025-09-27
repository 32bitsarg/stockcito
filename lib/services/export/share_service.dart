import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../system/logging_service.dart';
import 'export_models.dart';

/// Servicio para compartir archivos reales
class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  /// Comparte un archivo usando share_plus
  Future<bool> shareFile({
    required String filePath,
    required String fileName,
    ShareOptions? options,
  }) async {
    try {
      LoggingService.info('📤 [SHARE] Compartiendo archivo: $fileName');
      
      final file = File(filePath);
      if (!await file.exists()) {
        LoggingService.error('❌ [SHARE] Archivo no existe: $filePath');
        return false;
      }

      final shareOptions = options ?? ShareOptions();
      
      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text: shareOptions.text ?? 'Archivo generado por Stockcito',
        subject: shareOptions.subject ?? fileName,
      );

      LoggingService.info('✅ [SHARE] Archivo compartido exitosamente: $fileName');
      return true;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error compartiendo archivo: $e');
      return false;
    }
  }

  /// Comparte múltiples archivos
  Future<bool> shareMultipleFiles({
    required List<String> filePaths,
    required String subject,
    ShareOptions? options,
  }) async {
    try {
      LoggingService.info('📤 [SHARE] Compartiendo ${filePaths.length} archivos');
      
      // Verificar que todos los archivos existan
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          LoggingService.error('❌ [SHARE] Archivo no existe: $filePath');
          return false;
        }
      }

      final shareOptions = options ?? ShareOptions();
      final xFiles = filePaths.map((path) => XFile(path)).toList();
      
      await Share.shareXFiles(
        xFiles,
        text: shareOptions.text ?? 'Archivos generados por Stockcito',
        subject: subject,
      );

      LoggingService.info('✅ [SHARE] Múltiples archivos compartidos exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error compartiendo múltiples archivos: $e');
      return false;
    }
  }

  /// Comparte texto con archivos adjuntos
  Future<bool> shareTextWithFiles({
    required String text,
    required List<String> filePaths,
    String? subject,
  }) async {
    try {
      LoggingService.info('📤 [SHARE] Compartiendo texto con ${filePaths.length} archivos adjuntos');
      
      // Verificar archivos
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (!await file.exists()) {
          LoggingService.error('❌ [SHARE] Archivo no existe: $filePath');
          return false;
        }
      }

      final xFiles = filePaths.map((path) => XFile(path)).toList();
      
      await Share.shareXFiles(
        xFiles,
        text: text,
        subject: subject ?? 'Compartido desde Stockcito',
      );

      LoggingService.info('✅ [SHARE] Texto con archivos compartido exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error compartiendo texto con archivos: $e');
      return false;
    }
  }

  /// Comparte solo texto
  Future<bool> shareText({
    required String text,
    String? subject,
  }) async {
    try {
      LoggingService.info('📤 [SHARE] Compartiendo texto');
      
      await Share.share(
        text,
        subject: subject ?? 'Compartido desde Stockcito',
      );

      LoggingService.info('✅ [SHARE] Texto compartido exitosamente');
      return true;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error compartiendo texto: $e');
      return false;
    }
  }

  /// Obtiene la ruta del directorio de documentos
  Future<String> getDocumentsDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error obteniendo directorio de documentos: $e');
      rethrow;
    }
  }

  /// Obtiene la ruta del directorio temporal
  Future<String> getTemporaryDirectoryPath() async {
    try {
      final directory = await getTemporaryDirectory();
      return directory.path;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error obteniendo directorio temporal: $e');
      rethrow;
    }
  }

  /// Verifica si un archivo existe
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error verificando existencia de archivo: $e');
      return false;
    }
  }

  /// Obtiene el tamaño de un archivo
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      LoggingService.error('❌ [SHARE] Error obteniendo tamaño de archivo: $e');
      return 0;
    }
  }

  /// Formatea el tamaño de archivo en formato legible
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Valida si el archivo es compatible para compartir
  bool isFileShareable(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    const shareableExtensions = [
      'pdf', 'xlsx', 'xls', 'csv', 'json', 'txt',
      'png', 'jpg', 'jpeg', 'gif', 'bmp',
      'mp4', 'avi', 'mov', 'wmv',
      'mp3', 'wav', 'aac', 'flac',
      'doc', 'docx', 'ppt', 'pptx',
    ];
    return shareableExtensions.contains(extension);
  }

  /// Genera un mensaje de compartir personalizado
  String generateShareMessage({
    required String fileName,
    required String format,
    String? customMessage,
  }) {
    if (customMessage != null) {
      return customMessage;
    }

    final formatName = format.toUpperCase();
    return 'Archivo $formatName generado por Stockcito\n\n'
           'Archivo: $fileName\n'
           'Generado el: ${DateTime.now().toString()}\n\n'
           'Descarga la app Stockcito para más funcionalidades.';
  }
}
