/// Enums compartidos para conectividad y sincronización
/// Este archivo centraliza todas las definiciones de enums relacionados con conectividad

/// Estados de conectividad disponibles
enum ConnectivityStatus {
  online,
  offline,
  unknown,
  checking
}

/// Tipo de conexión de red
enum NetworkType {
  wifi,
  mobile,
  ethernet,
  bluetooth,
  vpn,
  other,
  none
}

/// Estados de sincronización disponibles
enum SyncStatus {
  synced,
  syncing,
  pending,
  offline,
  error
}

/// Tipos de operación de sincronización
enum SyncType {
  create,
  update,
  delete
}

/// Prioridades de sincronización
enum SyncPriority {
  low,
  normal,
  high,
  critical
}

