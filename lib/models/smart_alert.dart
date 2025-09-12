import 'package:flutter/material.dart';

/// Tipos de alertas inteligentes
enum AlertType {
  stockBajo,        // Stock por debajo del mínimo
  precioAnomalo,    // Precio fuera del rango normal
  tendencia,        // Cambio en tendencias de venta
  rentabilidad,     // Producto poco rentable
  oportunidad,      // Oportunidad de mejora
  advertencia       // Advertencia general
}

/// Prioridades de alertas
enum AlertPriority {
  critica,  // Requiere acción inmediata
  alta,     // Importante - debe revisarse pronto
  media,    // Moderada - puede esperar
  baja      // Informativa
}

/// Modelo de alerta inteligente
class SmartAlert {
  final String id;
  final String title;
  final String message;
  final String? productId;
  final String? productName;
  final AlertType type;
  final AlertPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final bool isDismissed;
  final Map<String, dynamic>? metadata; // Datos adicionales específicos del tipo

  SmartAlert({
    required this.id,
    required this.title,
    required this.message,
    this.productId,
    this.productName,
    required this.type,
    required this.priority,
    required this.createdAt,
    this.isRead = false,
    this.isDismissed = false,
    this.metadata,
  });

  /// Crea una copia con nuevos valores
  SmartAlert copyWith({
    String? id,
    String? title,
    String? message,
    String? productId,
    String? productName,
    AlertType? type,
    AlertPriority? priority,
    DateTime? createdAt,
    bool? isRead,
    bool? isDismissed,
    Map<String, dynamic>? metadata,
  }) {
    return SmartAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convierte a Map para persistencia
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isDismissed': isDismissed,
      'metadata': metadata,
    };
  }

  /// Crea desde Map
  factory SmartAlert.fromMap(Map<String, dynamic> map) {
    return SmartAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      productId: map['productId'],
      productName: map['productName'],
      type: AlertType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlertType.advertencia,
      ),
      priority: AlertPriority.values.firstWhere(
        (e) => e.name == map['priority'],
        orElse: () => AlertPriority.media,
      ),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      isDismissed: map['isDismissed'] ?? false,
      metadata: map['metadata'] != null ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  /// Obtiene el color según el tipo de alerta
  Color get typeColor {
    switch (type) {
      case AlertType.stockBajo:
        return Colors.red;
      case AlertType.precioAnomalo:
        return Colors.orange;
      case AlertType.tendencia:
        return Colors.blue;
      case AlertType.rentabilidad:
        return Colors.purple;
      case AlertType.oportunidad:
        return Colors.green;
      case AlertType.advertencia:
        return Colors.yellow[700]!;
    }
  }

  /// Obtiene el icono según el tipo de alerta
  IconData get typeIcon {
    switch (type) {
      case AlertType.stockBajo:
        return Icons.inventory_2;
      case AlertType.precioAnomalo:
        return Icons.attach_money;
      case AlertType.tendencia:
        return Icons.trending_up;
      case AlertType.rentabilidad:
        return Icons.analytics;
      case AlertType.oportunidad:
        return Icons.lightbulb;
      case AlertType.advertencia:
        return Icons.warning;
    }
  }

  /// Obtiene el color según la prioridad
  Color get priorityColor {
    switch (priority) {
      case AlertPriority.critica:
        return Colors.red[800]!;
      case AlertPriority.alta:
        return Colors.red;
      case AlertPriority.media:
        return Colors.orange;
      case AlertPriority.baja:
        return Colors.blue;
    }
  }

  /// Obtiene el icono según la prioridad
  IconData get priorityIcon {
    switch (priority) {
      case AlertPriority.critica:
        return Icons.priority_high;
      case AlertPriority.alta:
        return Icons.keyboard_arrow_up;
      case AlertPriority.media:
        return Icons.remove;
      case AlertPriority.baja:
        return Icons.keyboard_arrow_down;
    }
  }

  /// Verifica si la alerta es crítica
  bool get isCritical => priority == AlertPriority.critica;

  /// Verifica si la alerta es nueva (no leída)
  bool get isNew => !isRead && !isDismissed;

  /// Verifica si la alerta puede ser eliminada
  bool get canBeDeleted => isDismissed || isRead;

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
    return 'SmartAlert(id: $id, title: $title, type: $type, priority: $priority, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SmartAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
