/// Modelos de datos para el servicio de exportación
class ExportData {
  final Map<String, dynamic> insightsData;
  final List<Map<String, dynamic>> recommendations;
  final String fileName;
  final ExportFormat format;
  final String? title;
  final DateTime createdAt;

  ExportData({
    required this.insightsData,
    required this.recommendations,
    required this.fileName,
    required this.format,
    this.title,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'insightsData': insightsData,
      'recommendations': recommendations,
      'fileName': fileName,
      'format': format.name,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum ExportFormat {
  pdf,
  excel,
  csv,
  json,
}

class ExportResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final ExportFormat format;
  final DateTime exportedAt;

  ExportResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    required this.format,
    DateTime? exportedAt,
  }) : exportedAt = exportedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'filePath': filePath,
      'errorMessage': errorMessage,
      'format': format.name,
      'exportedAt': exportedAt.toIso8601String(),
    };
  }
}

class ExportOptions {
  final bool includeCharts;
  final bool includeRecommendations;
  final bool includeMetadata;
  final String? customTitle;
  final Map<String, dynamic>? customStyles;

  ExportOptions({
    this.includeCharts = true,
    this.includeRecommendations = true,
    this.includeMetadata = true,
    this.customTitle,
    this.customStyles,
  });

  Map<String, dynamic> toMap() {
    return {
      'includeCharts': includeCharts,
      'includeRecommendations': includeRecommendations,
      'includeMetadata': includeMetadata,
      'customTitle': customTitle,
      'customStyles': customStyles,
    };
  }
}

class ShareOptions {
  final String? subject;
  final String? text;
  final List<String>? recipients;
  final bool showShareSheet;

  ShareOptions({
    this.subject,
    this.text,
    this.recipients,
    this.showShareSheet = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'text': text,
      'recipients': recipients,
      'showShareSheet': showShareSheet,
    };
  }
}
