import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
      final minor = int.tryParse(parts[1]) ?? 0;
      
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
  static const Duration _checkInterval = Duration(hours: 24);
  
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
    if (_packageInfo?.version == null) return false;
    
    final currentVersion = _packageInfo!.version;
    return _compareVersions(newVersion, currentVersion) > 0;
  }

  /// Compara dos versiones (retorna 1 si v1 > v2, -1 si v1 < v2, 0 si iguales)
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();
    
    final maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    
    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final part2 = i < parts2.length ? (parts2[i] ?? 0) : 0;
      
      if (part1 > part2) return 1;
      if (part1 < part2) return -1;
    }
    
    return 0;
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

  /// Obtiene la versión actual de la aplicación
  String get currentVersion => _packageInfo?.version ?? 'Desconocida';

  /// Obtiene el nombre de la aplicación
  String get appName => _packageInfo?.appName ?? 'Ricitos de BB';

  /// Fuerza una verificación de actualizaciones
  Future<UpdateInfo?> forceCheckForUpdates() async {
    return await checkForUpdates(forceCheck: true);
  }
}
