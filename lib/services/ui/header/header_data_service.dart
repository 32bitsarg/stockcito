import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../auth/supabase_auth_service.dart';
import '../../system/logging_service.dart';

/// Modelo para la información del usuario en el header
class HeaderUserInfo {
  final String displayName;
  final String? email;
  final bool isAnonymous;
  final String? avatarUrl;
  final Color userColor;

  HeaderUserInfo({
    required this.displayName,
    this.email,
    required this.isAnonymous,
    this.avatarUrl,
    required this.userColor,
  });

  /// Obtiene el saludo personalizado para el usuario
  String get greeting {
    if (isAnonymous) {
      return 'Hola, Invitado';
    }
    return 'Bienvenido de vuelta, $displayName';
  }

  /// Obtiene el icono apropiado para el usuario
  IconData get userIcon {
    if (isAnonymous) {
      return Icons.person_outline;
    }
    return Icons.person;
  }
}

/// Modelo para la información del header
class HeaderInfo {
  final String title;
  final String? subtitle;
  final HeaderUserInfo userInfo;
  final List<String> searchSuggestions;
  final bool showSearch;
  final bool showUserInfo;

  HeaderInfo({
    required this.title,
    this.subtitle,
    required this.userInfo,
    this.searchSuggestions = const [],
    this.showSearch = true,
    this.showUserInfo = true,
  });
}

/// Servicio para manejar los datos del header
class HeaderDataService {
  static final HeaderDataService _instance = HeaderDataService._internal();
  factory HeaderDataService() => _instance;
  HeaderDataService._internal();

  final SupabaseAuthService _authService = SupabaseAuthService();

  /// Obtiene la información del usuario para el header
  HeaderUserInfo getUserInfo() {
    try {
      final isAnonymous = _authService.isAnonymous;
      final userName = _authService.currentUserName;
      final userEmail = _authService.currentUserEmail;

      // Determinar nombre de visualización
      String displayName = 'Usuario';
      if (isAnonymous) {
        displayName = 'Invitado';
      } else if (userName != null && userName.isNotEmpty) {
        displayName = userName;
      } else if (userEmail != null && userEmail.isNotEmpty) {
        displayName = userEmail;
      }

      // Determinar color del usuario
      Color userColor = isAnonymous ? AppTheme.warningColor : AppTheme.primaryColor;

      return HeaderUserInfo(
        displayName: displayName,
        email: userEmail,
        isAnonymous: isAnonymous,
        avatarUrl: null, // TODO: Implementar avatares cuando esté disponible
        userColor: userColor,
      );
    } catch (e) {
      LoggingService.error('Error obteniendo información del usuario: $e');
      return HeaderUserInfo(
        displayName: 'Usuario',
        isAnonymous: true,
        userColor: AppTheme.warningColor,
      );
    }
  }

  /// Obtiene las sugerencias de búsqueda basadas en el contexto
  List<String> getSearchSuggestions(String context) {
    try {
      switch (context.toLowerCase()) {
        case 'inventario':
          return [
            'Buscar productos...',
            'Filtrar por categoría',
            'Buscar por talla',
            'Productos con stock bajo',
          ];
        case 'ventas':
          return [
            'Buscar ventas...',
            'Filtrar por cliente',
            'Ventas del día',
            'Ventas pendientes',
          ];
        case 'clientes':
          return [
            'Buscar clientes...',
            'Clientes activos',
            'Nuevos clientes',
            'Clientes por ubicación',
          ];
        case 'reportes':
          return [
            'Generar reporte...',
            'Análisis de ventas',
            'Reporte de inventario',
            'Métricas de clientes',
          ];
        default:
          return [
            'Buscar productos, ventas, clientes...',
            'Búsqueda global',
            'Filtrar resultados',
            'Búsqueda avanzada',
          ];
      }
    } catch (e) {
      LoggingService.error('Error obteniendo sugerencias de búsqueda: $e');
      return ['Buscar...'];
    }
  }

  /// Obtiene la información completa del header para una pantalla específica
  HeaderInfo getHeaderInfo({
    required String title,
    String? subtitle,
    String? context,
    bool showSearch = true,
    bool showUserInfo = true,
  }) {
    try {
      final userInfo = getUserInfo();
      final searchSuggestions = showSearch ? getSearchSuggestions(context ?? title) : <String>[];

      return HeaderInfo(
        title: title,
        subtitle: subtitle,
        userInfo: userInfo,
        searchSuggestions: searchSuggestions,
        showSearch: showSearch,
        showUserInfo: showUserInfo,
      );
    } catch (e) {
      LoggingService.error('Error obteniendo información del header: $e');
      return HeaderInfo(
        title: title,
        subtitle: subtitle,
        userInfo: HeaderUserInfo(
          displayName: 'Usuario',
          isAnonymous: true,
          userColor: AppTheme.warningColor,
        ),
        searchSuggestions: [],
        showSearch: showSearch,
        showUserInfo: showUserInfo,
      );
    }
  }

  /// Valida si el usuario puede realizar acciones específicas
  bool canPerformAction(String action) {
    try {
      switch (action) {
        case 'search':
          return true; // Todos pueden buscar
        case 'logout':
          return true; // Todos pueden cerrar sesión
        case 'export':
          return !_authService.isAnonymous; // Solo usuarios autenticados
        case 'sync':
          return !_authService.isAnonymous; // Solo usuarios autenticados
        default:
          return true;
      }
    } catch (e) {
      LoggingService.error('Error validando acción: $e');
      return false;
    }
  }

  /// Obtiene el contexto de la pantalla actual
  String getScreenContext(int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return 'dashboard';
      case 1:
        return 'inventario';
      case 2:
        return 'ventas';
      case 3:
        return 'clientes';
      case 4:
        return 'reportes';
      case 5:
        return 'calculo_precios';
      case 6:
        return 'configuracion';
      default:
        return 'unknown';
    }
  }
}
