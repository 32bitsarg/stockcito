import 'package:stockcito/services/system/logging_service.dart';

/// Servicio para resolver conflictos durante la restauración de backups
class BackupConflictResolver {
  static final BackupConflictResolver _instance = BackupConflictResolver._internal();
  factory BackupConflictResolver() => _instance;
  BackupConflictResolver._internal();

  /// Resuelve conflictos entre datos existentes y datos del backup
  Future<ConflictResolution> resolveConflict({
    required String entityType,
    required String entityId,
    required Map<String, dynamic> existingData,
    required Map<String, dynamic> backupData,
    required ConflictType conflictType,
  }) async {
    try {
      LoggingService.info('🔍 Resolviendo conflicto para $entityType ($entityId): ${conflictType.name}');

      switch (conflictType) {
        case ConflictType.dataModified:
          return _resolveDataModifiedConflict(existingData, backupData);
        case ConflictType.entityExists:
          return _resolveEntityExistsConflict(existingData, backupData);
        case ConflictType.versionMismatch:
          return _resolveVersionMismatchConflict(existingData, backupData);
        case ConflictType.checksumMismatch:
          return ConflictResolution.skip('Checksum inválido - datos corruptos');
      }
    } catch (e) {
      LoggingService.error('Error resolviendo conflicto: $e');
      return ConflictResolution.skip('Error resolviendo conflicto: $e');
    }
  }

  /// Resuelve conflicto cuando los datos han sido modificados
  ConflictResolution _resolveDataModifiedConflict(
    Map<String, dynamic> existingData,
    Map<String, dynamic> backupData,
  ) {
    // Comparar fechas de modificación
    final existingModified = _getModifiedDate(existingData);
    final backupModified = _getModifiedDate(backupData);

    if (backupModified.isAfter(existingModified)) {
      return ConflictResolution.replace('Los datos del backup son más recientes');
    } else if (existingModified.isAfter(backupModified)) {
      return ConflictResolution.skip('Los datos existentes son más recientes');
    } else {
      // Misma fecha, mantener existentes
      return ConflictResolution.skip('Los datos son idénticos');
    }
  }

  /// Resuelve conflicto cuando la entidad ya existe
  ConflictResolution _resolveEntityExistsConflict(
    Map<String, dynamic> existingData,
    Map<String, dynamic> backupData,
  ) {
    // Verificar si los datos son significativamente diferentes
    final differences = _findSignificantDifferences(existingData, backupData);
    
    if (differences.isEmpty) {
      return ConflictResolution.skip('Los datos son idénticos');
    } else {
      return ConflictResolution.replace('Los datos del backup son diferentes');
    }
  }

  /// Resuelve conflicto de versión
  ConflictResolution _resolveVersionMismatchConflict(
    Map<String, dynamic> existingData,
    Map<String, dynamic> backupData,
  ) {
    final existingVersion = existingData['version'] ?? '1.0.0';
    final backupVersion = backupData['version'] ?? '1.0.0';
    
    if (_isVersionNewer(backupVersion, existingVersion)) {
      return ConflictResolution.replace('Versión del backup es más nueva');
    } else {
      return ConflictResolution.skip('Versión existente es más nueva o igual');
    }
  }

  /// Obtiene la fecha de modificación de los datos
  DateTime _getModifiedDate(Map<String, dynamic> data) {
    try {
      if (data.containsKey('updatedAt')) {
        return DateTime.parse(data['updatedAt']);
      } else if (data.containsKey('fechaModificacion')) {
        return DateTime.parse(data['fechaModificacion']);
      } else if (data.containsKey('createdAt')) {
        return DateTime.parse(data['createdAt']);
      } else {
        return DateTime.now().subtract(const Duration(days: 365));
      }
    } catch (e) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
  }

  /// Encuentra diferencias significativas entre dos conjuntos de datos
  List<String> _findSignificantDifferences(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    final differences = <String>[];
    
    // Campos importantes a comparar
    final importantFields = ['nombre', 'precio', 'stock', 'categoria', 'talla', 'cliente', 'total', 'estado'];
    
    for (final field in importantFields) {
      if (data1.containsKey(field) && data2.containsKey(field)) {
        if (data1[field] != data2[field]) {
          differences.add(field);
        }
      }
    }
    
    return differences;
  }

  /// Compara versiones para determinar cuál es más nueva
  bool _isVersionNewer(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
        final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
        
        if (v1Part > v2Part) return true;
        if (v1Part < v2Part) return false;
      }
      
      return false; // Versiones iguales
    } catch (e) {
      return false; // Error parsing, considerar iguales
    }
  }

  /// Genera un resumen de conflictos para mostrar al usuario
  String generateConflictSummary(List<ConflictInfo> conflicts) {
    if (conflicts.isEmpty) {
      return 'No se encontraron conflictos';
    }

    final summary = StringBuffer();
    summary.writeln('Se encontraron ${conflicts.length} conflicto(s):');
    summary.writeln();

    final groupedConflicts = <ConflictType, List<ConflictInfo>>{};
    for (final conflict in conflicts) {
      groupedConflicts.putIfAbsent(conflict.type, () => []).add(conflict);
    }

    for (final entry in groupedConflicts.entries) {
      summary.writeln('${_getConflictTypeDescription(entry.key)}: ${entry.value.length}');
      for (final conflict in entry.value.take(3)) {
        summary.writeln('  • ${conflict.entityType}: ${conflict.entityId}');
      }
      if (entry.value.length > 3) {
        summary.writeln('  • ... y ${entry.value.length - 3} más');
      }
      summary.writeln();
    }

    return summary.toString();
  }

  /// Obtiene descripción legible del tipo de conflicto
  String _getConflictTypeDescription(ConflictType type) {
    switch (type) {
      case ConflictType.dataModified:
        return 'Datos modificados';
      case ConflictType.entityExists:
        return 'Entidad ya existe';
      case ConflictType.versionMismatch:
        return 'Versión diferente';
      case ConflictType.checksumMismatch:
        return 'Datos corruptos';
    }
  }
}

/// Tipos de conflictos que pueden ocurrir
enum ConflictType {
  dataModified,
  entityExists,
  versionMismatch,
  checksumMismatch,
}

/// Información sobre un conflicto específico
class ConflictInfo {
  final String entityType;
  final String entityId;
  final ConflictType type;
  final String description;

  const ConflictInfo({
    required this.entityType,
    required this.entityId,
    required this.type,
    required this.description,
  });
}

/// Resultado de la resolución de un conflicto
class ConflictResolution {
  final ConflictAction action;
  final String reason;

  const ConflictResolution._(this.action, this.reason);

  factory ConflictResolution.replace(String reason) {
    return ConflictResolution._(ConflictAction.replace, reason);
  }

  factory ConflictResolution.skip(String reason) {
    return ConflictResolution._(ConflictAction.skip, reason);
  }

  factory ConflictResolution.merge(String reason) {
    return ConflictResolution._(ConflictAction.merge, reason);
  }
}

/// Acciones posibles para resolver un conflicto
enum ConflictAction {
  replace, // Reemplazar datos existentes con datos del backup
  skip,    // Mantener datos existentes, saltar datos del backup
  merge,   // Combinar datos existentes con datos del backup
}
