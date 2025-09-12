import 'package:flutter/material.dart';

/// Estados de una recomendación de IA
enum RecommendationStatus {
  nueva,      // Recién generada por la IA
  vista,      // El usuario la vio pero no la aplicó
  aplicada,   // El usuario la implementó
  descartada  // El usuario la rechazó
}

/// Prioridades de una recomendación
enum RecommendationPriority {
  alta,   // Crítica - requiere acción inmediata
  media,  // Importante - debe considerarse pronto
  baja    // Informativa - puede esperar
}

/// Modelo de recomendación de IA con estados y persistencia local
class AIRecommendation {
  final String id;
  final String title;
  final String message;
  final String action;
  final RecommendationPriority priority;
  final RecommendationStatus status;
  final DateTime createdAt;
  final DateTime? viewedAt;
  final DateTime? appliedAt;
  final DateTime? discardedAt;
  final String category; // pricing, stock, profitability, trend, etc.

  AIRecommendation({
    required this.id,
    required this.title,
    required this.message,
    required this.action,
    required this.priority,
    this.status = RecommendationStatus.nueva,
    required this.createdAt,
    this.viewedAt,
    this.appliedAt,
    this.discardedAt,
    required this.category,
  });

  /// Crea una copia con nuevos valores
  AIRecommendation copyWith({
    String? id,
    String? title,
    String? message,
    String? action,
    RecommendationPriority? priority,
    RecommendationStatus? status,
    DateTime? createdAt,
    DateTime? viewedAt,
    DateTime? appliedAt,
    DateTime? discardedAt,
    String? category,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      viewedAt: viewedAt ?? this.viewedAt,
      appliedAt: appliedAt ?? this.appliedAt,
      discardedAt: discardedAt ?? this.discardedAt,
      category: category ?? this.category,
    );
  }

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'action': action,
      'priority': priority.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
      'appliedAt': appliedAt?.toIso8601String(),
      'discardedAt': discardedAt?.toIso8601String(),
      'category': category,
    };
  }

  /// Crea desde Map
  factory AIRecommendation.fromMap(Map<String, dynamic> map) {
    return AIRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      action: map['action'] ?? '',
      priority: RecommendationPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => RecommendationPriority.media,
      ),
      status: RecommendationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RecommendationStatus.nueva,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      viewedAt: map['viewedAt'] != null ? DateTime.parse(map['viewedAt']) : null,
      appliedAt: map['appliedAt'] != null ? DateTime.parse(map['appliedAt']) : null,
      discardedAt: map['discardedAt'] != null ? DateTime.parse(map['discardedAt']) : null,
      category: map['category'] ?? 'general',
    );
  }

  /// Obtiene el color según la prioridad
  Color get priorityColor {
    switch (priority) {
      case RecommendationPriority.alta:
        return Colors.red;
      case RecommendationPriority.media:
        return Colors.orange;
      case RecommendationPriority.baja:
        return Colors.green;
    }
  }

  /// Obtiene el icono según la prioridad
  IconData get priorityIcon {
    switch (priority) {
      case RecommendationPriority.alta:
        return Icons.priority_high;
      case RecommendationPriority.media:
        return Icons.info;
      case RecommendationPriority.baja:
        return Icons.check_circle;
    }
  }

  /// Obtiene el color según el estado
  Color get statusColor {
    switch (status) {
      case RecommendationStatus.nueva:
        return Colors.blue;
      case RecommendationStatus.vista:
        return Colors.orange;
      case RecommendationStatus.aplicada:
        return Colors.green;
      case RecommendationStatus.descartada:
        return Colors.grey;
    }
  }

  /// Obtiene el icono según el estado
  IconData get statusIcon {
    switch (status) {
      case RecommendationStatus.nueva:
        return Icons.fiber_new;
      case RecommendationStatus.vista:
        return Icons.visibility;
      case RecommendationStatus.aplicada:
        return Icons.check_circle;
      case RecommendationStatus.descartada:
        return Icons.cancel;
    }
  }

  /// Verifica si la recomendación es nueva
  bool get isNew => status == RecommendationStatus.nueva;

  /// Verifica si la recomendación puede ser eliminada
  bool get canBeDeleted => status == RecommendationStatus.descartada || 
                          status == RecommendationStatus.aplicada;

  /// Obtiene el tiempo transcurrido desde la creación
  Duration get timeElapsed => DateTime.now().difference(createdAt);

  /// Obtiene una descripción del tiempo transcurrido
  String get timeElapsedDescription {
    final duration = timeElapsed;
    if (duration.inDays > 0) {
      return 'Hace ${duration.inDays} día${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return 'Hace ${duration.inHours} hora${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 0) {
      return 'Hace ${duration.inMinutes} minuto${duration.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos segundos';
    }
  }

  @override
  String toString() {
    return 'AIRecommendation(id: $id, title: $title, priority: $priority, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIRecommendation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
