import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../models/connectivity_enums.dart';

/// Widget simplificado que muestra el estado de sincronización
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
  
  SyncStatus _currentStatus = SyncStatus.synced;
  int _pendingOperations = 0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 [SYNC WIDGET] initState() llamado');
    try {
      // Usar WidgetsBinding para asegurar que el contexto esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setupAnimation();
          _simulateSyncStatus();
          print('✅ [SYNC WIDGET] Inicialización completada');
        }
      });
    } catch (e) {
      print('❌ [SYNC WIDGET] Error en initState: $e');
    }
  }

  void _setupAnimation() {
    try {
      if (!mounted) return;
      
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

      // Solo iniciar animación si está habilitada y el widget está montado
      if (widget.showAnimation && mounted) {
        _animationController.repeat();
      }
    } catch (e) {
      print('❌ [SYNC WIDGET] Error configurando animación: $e');
    }
  }

  void _simulateSyncStatus() {
    // Simular estado de sincronización - por ahora siempre sincronizado
    setState(() {
      _currentStatus = SyncStatus.synced;
      _pendingOperations = 0;
    });
    
    // Opcional: cambiar estado cada 45 segundos para testing
    _statusTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (mounted) {
        setState(() {
          if (_currentStatus == SyncStatus.synced) {
            _currentStatus = SyncStatus.pending;
            _pendingOperations = 3;
          } else {
            _currentStatus = SyncStatus.synced;
            _pendingOperations = 0;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    print('🛑 [SYNC WIDGET] dispose() llamado');
    try {
      _statusTimer?.cancel();
      _statusTimer = null;
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.dispose();
      print('✅ [SYNC WIDGET] dispose() completado');
    } catch (e) {
      print('❌ [SYNC WIDGET] Error en dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [SYNC WIDGET] build() llamado - Status: $_currentStatus, Pending: $_pendingOperations');
    
    // Guard para evitar builds cuando el widget no está montado
    if (!mounted) {
      return const SizedBox.shrink();
    }
    
    try {
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
    } catch (e) {
      print('❌ [SYNC WIDGET] Error en build: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildStatusIcon() {
    final icon = _getStatusIcon();
    final color = _getStatusColor();
    
    // Crear el icono base una sola vez
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
