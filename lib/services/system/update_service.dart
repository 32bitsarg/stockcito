import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'logging_service.dart';

/// Información sobre una actualización disponible
class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final bool isMandatory;
  final DateTime publishedAt;
  final String tagName;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.isMandatory,
    required this.publishedAt,
    required this.tagName,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['tag_name']?.toString().replaceFirst('v', '') ?? '',
      downloadUrl: _extractDownloadUrl(json),
      releaseNotes: json['body'] ?? '',
      isMandatory: _isMandatoryVersion(json['tag_name']?.toString() ?? ''),
      publishedAt: DateTime.parse(json['published_at'] ?? DateTime.now().toIso8601String()),
      tagName: json['tag_name'] ?? '',
    );
  }

  static String _extractDownloadUrl(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>?;
    if (assets != null && assets.isNotEmpty) {
      for (final asset in assets) {
        final name = asset['name']?.toString() ?? '';
        if (name.endsWith('.exe') || name.endsWith('.msi')) {
          return asset['browser_download_url'] ?? '';
        }
      }
    }
    return '';
  }

  static bool _isMandatoryVersion(String tagName) {
    // Versiones obligatorias: v2.0.0, v3.0.0, etc. (cambios mayores)
    final version = tagName.replaceFirst('v', '');
    final parts = version.split('.');
    if (parts.length >= 2) {
      final major = int.tryParse(parts[0]) ?? 0;
      
      // Versiones obligatorias: cambios mayores o versiones específicas
      return major >= 2 || _isSpecificMandatoryVersion(version);
    }
    return false;
  }

  static bool _isSpecificMandatoryVersion(String version) {
    // Lista de versiones específicas que son obligatorias
    const mandatoryVersions = ['1.5.0', '2.0.0', '2.1.0'];
    return mandatoryVersions.contains(version);
  }
}

/// Servicio para manejar actualizaciones desde GitHub Releases
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();
         
  // Configuración del repositorio
  static const String _githubOwner = '32bitsarg'; // Cambiar por tu usuario
  static const String _githubRepo = 'stockcito'; // Cambiar por tu repo
  static const String _githubApiUrl = 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
  
  // Cache de verificación
  DateTime? _lastCheck;
  static const Duration _checkInterval = Duration(minutes: 5); // Reducido para testing
  
  PackageInfo? _packageInfo;

  /// Inicializa el servicio
  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      LoggingService.info('UpdateService inicializado - Versión actual: ${_packageInfo?.version}');
    } catch (e) {
      LoggingService.error('Error inicializando UpdateService: $e');
    }
  }

  /// Verifica si hay actualizaciones disponibles
  Future<UpdateInfo?> checkForUpdates({bool forceCheck = false}) async {
    try {
      // Inicializar automáticamente si no está inicializado
      if (_packageInfo == null) {
        LoggingService.info('🔧 [UPDATE] Inicializando UpdateService automáticamente...');
        await initialize();
      }

      // Verificar si ya se revisó recientemente
      if (!forceCheck && _lastCheck != null && 
          DateTime.now().difference(_lastCheck!) < _checkInterval) {
        LoggingService.info('Verificación de actualizaciones omitida (muy reciente)');
        return null;
      }

      LoggingService.info('🔍 Verificando actualizaciones en GitHub...');
      
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updateInfo = UpdateInfo.fromJson(data);
        
        _lastCheck = DateTime.now();
        
        // Verificar si la versión es más nueva
        if (_isNewerVersion(updateInfo.version)) {
          LoggingService.info('🆕 Nueva versión disponible: ${updateInfo.version} (${updateInfo.isMandatory ? 'OBLIGATORIA' : 'OPCIONAL'})');
          return updateInfo;
        } else {
          LoggingService.info('✅ Aplicación actualizada (versión ${_packageInfo?.version})');
          return null;
        }
      } else {
        LoggingService.warning('Error verificando actualizaciones: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      LoggingService.error('Error verificando actualizaciones: $e');
      return null;
    }
  }

  /// Compara si una versión es más nueva que la actual
  bool _isNewerVersion(String newVersion) {
    if (_packageInfo?.version == null) {
      LoggingService.warning('⚠️ [UPDATE] No se puede comparar versiones - PackageInfo no inicializado');
      return false;
    }
    
    final currentVersion = _packageInfo!.version;
    final isNewer = _compareVersions(newVersion, currentVersion) > 0;
    
    LoggingService.info('📊 [UPDATE] Comparando versiones: $newVersion vs $currentVersion -> ${isNewer ? "MÁS NUEVA" : "NO ES MÁS NUEVA"}');
    return isNewer;
  }

  /// Compara dos versiones (retorna 1 si v1 > v2, -1 si v1 < v2, 0 si iguales)
  int _compareVersions(String v1, String v2) {
    try {
      // Limpiar versiones (remover 'v' si existe)
      final cleanV1 = v1.replaceFirst(RegExp(r'^v'), '');
      final cleanV2 = v2.replaceFirst(RegExp(r'^v'), '');
      
      final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      
      final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
      
      for (int i = 0; i < maxLength; i++) {
        final part1 = i < parts1.length ? parts1[i] : 0;
        final part2 = i < parts2.length ? parts2[i] : 0;
        
        if (part1 > part2) return 1;
        if (part1 < part2) return -1;
      }
      
      return 0;
    } catch (e) {
      LoggingService.error('Error comparando versiones "$v1" vs "$v2": $e');
      return 0; // En caso de error, considerar iguales
    }
  }

  /// Abre la URL de descarga en el navegador
  Future<void> downloadUpdate(UpdateInfo updateInfo) async {
    try {
      LoggingService.info('🌐 Abriendo descarga de actualización: ${updateInfo.version}');
      
      final uri = Uri.parse(updateInfo.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        LoggingService.info('✅ Descarga iniciada en navegador');
      } else {
        LoggingService.error('❌ No se pudo abrir la URL de descarga');
      }
    } catch (e) {
      LoggingService.error('Error descargando actualización: $e');
    }
  }

  /// Descarga el archivo de actualización automáticamente
  Future<String> downloadUpdateFile(UpdateInfo updateInfo, Function(double) onProgress) async {
    try {
      LoggingService.info('📥 Iniciando descarga automática de: ${updateInfo.downloadUrl}');
      
      // Obtener directorio temporal
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ricitosdebb_update_${updateInfo.version}.exe';
      final filePath = '${tempDir.path}/$fileName';
      
      LoggingService.info('📁 Directorio temporal: ${tempDir.path}');
      LoggingService.info('📄 Archivo destino: $filePath');
      
      // Verificar si el archivo ya existe
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        LoggingService.info('🗑️ Eliminando archivo existente...');
        await existingFile.delete();
      }
      
      // Configurar Dio para descarga
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      
      LoggingService.info('🌐 Configurando descarga con timeout de 30s conexión, 5min recepción');
      
      // Descargar con progreso
      await dio.download(
        updateInfo.downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onProgress(progress);
            LoggingService.info('📊 Progreso: ${(progress * 100).toStringAsFixed(1)}% (${received}/${total} bytes)');
          }
        },
      );
      
      // Verificar que el archivo se descargó correctamente
      final downloadedFile = File(filePath);
      if (await downloadedFile.exists()) {
        final fileSize = await downloadedFile.length();
        LoggingService.info('✅ Descarga completada: $filePath (${fileSize} bytes)');
        return filePath;
      } else {
        throw Exception('El archivo no se descargó correctamente');
      }
    } catch (e) {
      LoggingService.error('❌ Error descargando actualización: $e');
      LoggingService.error('📋 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Instala la actualización descargada
  Future<void> installUpdate(String filePath) async {
    try {
      LoggingService.info('🔧 Iniciando instalación de: $filePath');
      
      // Verificar que el archivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        LoggingService.error('❌ Archivo no encontrado: $filePath');
        throw Exception('Archivo de actualización no encontrado: $filePath');
      }
      
      // Obtener información del archivo
      final fileSize = await file.length();
      final fileStat = await file.stat();
      LoggingService.info('📁 Archivo encontrado - Tamaño: ${fileSize} bytes, Modificado: ${fileStat.modified}');
      
      // Verificar permisos de ejecución
      LoggingService.info('🔐 Verificando permisos de ejecución...');
      
      // Intentar diferentes parámetros de instalación
      final installParams = [
        [],               // Sin parámetros - interfaz gráfica completa
        ['/D=C:\\Program Files\\Stockcito'], // Especificar directorio de instalación
        ['/NCRC'],        // Sin verificar CRC
        ['/S'],           // Silencioso para NSIS (fallback)
      ];
      
      ProcessResult? result;
      String? usedParams;
      
      for (final params in installParams) {
        try {
          LoggingService.info('🔄 Intentando instalación con parámetros: ${params.join(' ')}');
          
          result = await Process.run(
            filePath,
            params.cast<String>(),
            runInShell: true,
          );
          
          LoggingService.info('📊 Resultado - Exit Code: ${result.exitCode}');
          LoggingService.info('📤 stdout: ${result.stdout}');
          LoggingService.info('📥 stderr: ${result.stderr}');
          
          if (result.exitCode == 0) {
            usedParams = params.join(' ');
            break;
          } else {
            LoggingService.warning('⚠️ Parámetros ${params.join(' ')} fallaron con código ${result.exitCode}');
          }
        } catch (e) {
          LoggingService.warning('⚠️ Error con parámetros ${params.join(' ')}: $e');
        }
      }
      
      if (result == null) {
        throw Exception('No se pudo ejecutar el instalador con ningún parámetro');
      }
      
      if (result.exitCode == 0) {
        LoggingService.info('✅ Instalador ejecutado exitosamente con parámetros: $usedParams');
        LoggingService.info('📋 El instalador se ha abierto. Por favor, completa la instalación.');
        LoggingService.info('⏳ Esperando a que completes la instalación...');
        
        // Esperar a que el usuario complete la instalación
        // Verificar periódicamente si la nueva versión se instaló
        final newAppPath = 'C:\\Program Files\\Stockcito\\stockcito.exe';
        bool installationCompleted = false;
        int attempts = 0;
        const maxAttempts = 60; // 5 minutos máximo
        
        while (!installationCompleted && attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: 5));
          attempts++;
          
          final newAppFile = File(newAppPath);
          if (await newAppFile.exists()) {
            LoggingService.info('✅ Nueva versión detectada en: $newAppPath');
            LoggingService.info('🚀 Reiniciando aplicación con la nueva versión...');
            
            // Ejecutar la nueva versión
            try {
              LoggingService.info('🔄 Intentando iniciar nueva versión...');
              final newProcess = await Process.start(newAppPath, [], mode: ProcessStartMode.detached);
              LoggingService.info('✅ Nueva versión iniciada exitosamente (PID: ${newProcess.pid})');
              installationCompleted = true;
              
              // Cerrar la aplicación actual inmediatamente después de iniciar la nueva
              LoggingService.info('🔄 Cerrando aplicación actual...');
              exit(0);
            } catch (e) {
              LoggingService.warning('⚠️ Error iniciando nueva versión: $e');
              LoggingService.info('🔄 Intentando método alternativo...');
              
              // Método alternativo usando cmd
              try {
                await Process.run('cmd', ['/c', 'start', '', newAppPath], runInShell: true);
                LoggingService.info('✅ Nueva versión iniciada con método alternativo');
                installationCompleted = true;
                
                // Cerrar la aplicación actual inmediatamente después de iniciar la nueva
                LoggingService.info('🔄 Cerrando aplicación actual...');
                exit(0);
              } catch (e2) {
                LoggingService.warning('⚠️ Error con método alternativo: $e2');
                LoggingService.info('💡 Por favor, reinicia la aplicación manualmente desde: $newAppPath');
                installationCompleted = true; // Salir del bucle aunque falle
              }
            }
          } else {
            LoggingService.info('⏳ Esperando instalación... (intento $attempts/$maxAttempts)');
          }
        }
        
        if (!installationCompleted) {
          LoggingService.warning('⚠️ Tiempo de espera agotado. Por favor, reinicia la aplicación manualmente.');
        }
        
        LoggingService.info('🔄 Cerrando aplicación actual...');
        // Cerrar la aplicación actual
        exit(0);
      } else {
        LoggingService.error('❌ Error en la instalación:');
        LoggingService.error('   - Exit Code: ${result.exitCode}');
        LoggingService.error('   - stdout: ${result.stdout}');
        LoggingService.error('   - stderr: ${result.stderr}');
        LoggingService.error('   - Parámetros usados: $usedParams');
        throw Exception('Error en la instalación (código ${result.exitCode}): ${result.stderr}');
      }
    } catch (e) {
      LoggingService.error('❌ Error instalando actualización: $e');
      LoggingService.error('📋 Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  /// Obtiene la versión actual de la aplicación
  String get currentVersion => _packageInfo?.version ?? 'Desconocida';

  /// Obtiene el nombre de la aplicación
  String get appName => _packageInfo?.appName ?? 'Stockcito';

  /// Fuerza una verificación de actualizaciones
  Future<UpdateInfo?> forceCheckForUpdates() async {
    return await checkForUpdates(forceCheck: true);
  }
}
