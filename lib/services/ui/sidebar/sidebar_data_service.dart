import 'package:flutter/material.dart';

/// Servicio que maneja los datos del sidebar
class SidebarDataService {
  static final SidebarDataService _instance = SidebarDataService._internal();
  factory SidebarDataService() => _instance;
  SidebarDataService._internal();

  /// Obtiene la información del logo de la aplicación
  SidebarLogoInfo getLogoInfo() {
    return const SidebarLogoInfo(
      appName: 'Stockcito',
      logoText: 'S',
      version: '1.1.0',
    );
  }

  /// Obtiene la información de la sección de actualizaciones
  SidebarUpdateInfo getUpdateInfo() {
    return const SidebarUpdateInfo(
      title: 'Estado de actualizaciones',
      subtitle: 'Verifica si hay nuevas versiones disponibles',
      buttonText: 'Verificar',
      icon: Icons.system_update,
    );
  }

  /// Obtiene las estadísticas del sidebar
  SidebarStats getSidebarStats() {
    return const SidebarStats(
      totalProducts: 0,
      totalSales: 0,
      totalClients: 0,
      lastSyncTime: null,
    );
  }

  /// Actualiza las estadísticas del sidebar
  Future<void> updateStats() async {
    // Aquí se implementaría la lógica para obtener estadísticas reales
    // Por ahora retornamos datos estáticos
  }
}

/// Información del logo del sidebar
class SidebarLogoInfo {
  final String appName;
  final String logoText;
  final String version;

  const SidebarLogoInfo({
    required this.appName,
    required this.logoText,
    required this.version,
  });
}

/// Información de la sección de actualizaciones
class SidebarUpdateInfo {
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;

  const SidebarUpdateInfo({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
  });
}

/// Estadísticas del sidebar
class SidebarStats {
  final int totalProducts;
  final int totalSales;
  final int totalClients;
  final DateTime? lastSyncTime;

  const SidebarStats({
    required this.totalProducts,
    required this.totalSales,
    required this.totalClients,
    this.lastSyncTime,
  });

  /// Verifica si hay datos disponibles
  bool get hasData => totalProducts > 0 || totalSales > 0 || totalClients > 0;

  /// Obtiene el tiempo de última sincronización formateado
  String get formattedLastSync {
    if (lastSyncTime == null) return 'Nunca';
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    
    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}
