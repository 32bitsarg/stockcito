import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/connectivity_enums.dart';
import '../../../services/datos/enhanced_sync_service.dart';
import '../../../services/system/connectivity_service.dart';

/// Widget que muestra el estado real de sincronización usando EnhancedSyncService
class SyncStatusWidget extends StatefulWidget {
  final bool showDetails;
  final bool showAnimation;
  final EdgeInsetsGeometry? padding;

  const SyncStatusWidget({
    super.key,
    this.showDetails = false,
    this.showAnimation = true,
    this.padding,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  
  final EnhancedSyncService _syncService = EnhancedSyncService();
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<ConnectivityInfo>? _connectivitySubscription;
  
  SyncStatus _currentStatus = SyncStatus.synced;
  int _pendingOperations = 0;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeSync();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  Future<void> _initializeSync() async {
    try {
      // Inicializar servicios
      await _connectivityService.initialize();
      await _syncService.initialize();
      
      // Obtener estado inicial
      _isOnline = _connectivityService.isOnline;
      _pendingOperations = _syncService.pendingOperations;
      _currentStatus = _syncService.syncStatus;
      
      // Suscribirse a cambios de conectividad
      _connectivitySubscription = _connectivityService.connectivityStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ [SYNC WIDGET] Error en stream de conectividad: $error');
        },
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ [SYNC WIDGET] Error inicializando sincronización: $e');
    }
  }

  void _onConnectivityChanged(ConnectivityInfo info) {
    if (!mounted) return;
    
    _isOnline = info.hasInternet;
    
    // Actualizar estado de sincronización
    _pendingOperations = _syncService.pendingOperations;
    _currentStatus = _syncService.syncStatus;
    
    // Controlar animación basada en el estado
    if (widget.showAnimation) {
      if (_currentStatus == SyncStatus.syncing && !_animationController.isAnimating) {
        _animationController.repeat();
      } else if (_currentStatus != SyncStatus.syncing && _animationController.isAnimating) {
        _animationController.stop();
      }
    }
    
    setState(() {});
    
    print('🔍 [SYNC WIDGET] Estado actualizado: $_currentStatus, Pendientes: $_pendingOperations, Online: $_isOnline');
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          if (widget.showDetails) ...[
            const SizedBox(width: 8),
            _buildStatusText(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    final icon = _getStatusIcon();
    final color = _getStatusColor();
    
    final baseIcon = FaIcon(
      icon,
      size: 16,
      color: color,
    );

    // Solo aplicar animación si está habilitada y el estado es syncing
    if (widget.showAnimation && 
        _currentStatus == SyncStatus.syncing && 
        _animationController.isAnimating) {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: baseIcon,
          );
        },
      );
    }

    return baseIcon;
  }

  Widget _buildStatusText() {
    final text = _getStatusText();
    final color = _getStatusColor();
    
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return FontAwesomeIcons.circleCheck;
      case SyncStatus.syncing:
        return FontAwesomeIcons.spinner;
      case SyncStatus.pending:
        return FontAwesomeIcons.clock;
      case SyncStatus.offline:
        return FontAwesomeIcons.wifi;
      case SyncStatus.error:
        return FontAwesomeIcons.triangleExclamation;
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return AppTheme.successColor;
      case SyncStatus.syncing:
        return AppTheme.primaryColor;
      case SyncStatus.pending:
        return AppTheme.warningColor;
      case SyncStatus.offline:
        return AppTheme.errorColor;
      case SyncStatus.error:
        return AppTheme.errorColor;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.pending:
        return '$_pendingOperations pendientes';
      case SyncStatus.offline:
        return 'Sin conexión';
      case SyncStatus.error:
        return 'Error de sincronización';
    }
  }
}
