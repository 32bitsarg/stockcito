import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/system/update_service.dart';
import '../../../widgets/ui/utility/update_notification_widget.dart';

/// Servicio que maneja el estado del sidebar
class SidebarStateService {
  static final SidebarStateService _instance = SidebarStateService._internal();
  factory SidebarStateService() => _instance;
  SidebarStateService._internal();

  final UpdateService _updateService = UpdateService();
  
  // Estado de actualizaciones
  UpdateInfo? _pendingUpdate;
  bool _isCheckingUpdates = false;
  OverlayEntry? _currentOverlayEntry;

  // Streams para notificar cambios de estado
  final StreamController<UpdateInfo?> _updateController = StreamController<UpdateInfo?>.broadcast();
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();

  /// Stream de actualizaciones pendientes
  Stream<UpdateInfo?> get updateStream => _updateController.stream;

  /// Stream de estado de carga
  Stream<bool> get loadingStream => _loadingController.stream;

  /// Obtiene la actualización pendiente actual
  UpdateInfo? get pendingUpdate => _pendingUpdate;

  /// Verifica si está verificando actualizaciones
  bool get isCheckingUpdates => _isCheckingUpdates;

  /// Inicializa el servicio y verifica actualizaciones
  Future<void> initialize() async {
    await _checkForUpdates();
  }

  /// Verifica si hay actualizaciones disponibles
  Future<void> _checkForUpdates() async {
    try {
      _setLoadingState(true);
      
      final updateInfo = await _updateService.checkForUpdates();
      
      if (updateInfo != null && updateInfo.version.isNotEmpty) {
        _pendingUpdate = updateInfo;
        _updateController.add(_pendingUpdate);
      } else {
        _pendingUpdate = null;
        _updateController.add(null);
      }
    } catch (e) {
      // Error manejado silenciosamente
      _pendingUpdate = null;
      _updateController.add(null);
    } finally {
      _setLoadingState(false);
    }
  }

  /// Actualiza el estado de carga
  void _setLoadingState(bool isLoading) {
    _isCheckingUpdates = isLoading;
    _loadingController.add(isLoading);
  }

  /// Muestra la notificación de actualización
  void showUpdateNotification(BuildContext context) {
    if (_pendingUpdate == null || _currentOverlayEntry != null) return;

    try {
      _currentOverlayEntry = OverlayEntry(
        builder: (context) => UpdateNotificationWidget(
          updateInfo: _pendingUpdate!,
          onDismiss: _dismissCurrentNotification,
        ),
      );

      Overlay.of(context).insert(_currentOverlayEntry!);
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  /// Oculta la notificación actual
  void _dismissCurrentNotification() {
    try {
      _currentOverlayEntry?.remove();
      _currentOverlayEntry = null;
    } catch (e) {
      // Error manejado silenciosamente
    }
  }

  /// Fuerza una nueva verificación de actualizaciones
  Future<void> forceUpdateCheck() async {
    await _checkForUpdates();
  }

  /// Limpia los recursos del servicio
  void dispose() {
    _dismissCurrentNotification();
    _updateController.close();
    _loadingController.close();
  }
}
