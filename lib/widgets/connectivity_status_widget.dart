import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../models/connectivity_enums.dart';

/// Widget simplificado que muestra el estado de conectividad
class ConnectivityStatusWidget extends StatefulWidget {
  final bool showDetails;
  final bool showAnimation;
  final EdgeInsetsGeometry? padding;

  const ConnectivityStatusWidget({
    super.key,
    this.showDetails = false,
    this.showAnimation = true,
    this.padding,
  });

  @override
  State<ConnectivityStatusWidget> createState() => _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  ConnectivityStatus _currentStatus = ConnectivityStatus.online;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    print('🚀 [CONNECTIVITY WIDGET] initState() llamado');
    try {
      // Usar WidgetsBinding para asegurar que el contexto esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setupAnimation();
          _simulateConnectivityStatus();
          print('✅ [CONNECTIVITY WIDGET] Inicialización completada');
        }
      });
    } catch (e) {
      print('❌ [CONNECTIVITY WIDGET] Error en initState: $e');
    }
  }

  void _setupAnimation() {
    try {
      if (!mounted) return;
      
      _animationController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );
      
      _pulseAnimation = Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      // Solo iniciar animación si está habilitada y el widget está montado
      if (widget.showAnimation && mounted) {
        _animationController.repeat(reverse: true);
      }
    } catch (e) {
      print('❌ [CONNECTIVITY WIDGET] Error configurando animación: $e');
    }
  }

  void _simulateConnectivityStatus() {
    // Simular estado de conectividad - por ahora siempre online
    setState(() {
      _currentStatus = ConnectivityStatus.online;
    });
    
    // Opcional: cambiar estado cada 30 segundos para testing
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentStatus = _currentStatus == ConnectivityStatus.online 
              ? ConnectivityStatus.offline 
              : ConnectivityStatus.online;
        });
      }
    });
  }

  @override
  void dispose() {
    print('🛑 [CONNECTIVITY WIDGET] dispose() llamado');
    try {
      // Cancelar timer
      _statusTimer?.cancel();
      _statusTimer = null;
      
      // Detener y liberar animación
      if (_animationController.isAnimating) {
        _animationController.stop();
      }
      _animationController.dispose();
      
      print('✅ [CONNECTIVITY WIDGET] dispose() completado');
    } catch (e) {
      print('❌ [CONNECTIVITY WIDGET] Error en dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('🔍 [CONNECTIVITY WIDGET] build() llamado - Status: $_currentStatus');
    
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
      print('❌ [CONNECTIVITY WIDGET] Error en build: $e');
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

    // Solo aplicar animación si está habilitada y el estado es online
    if (widget.showAnimation && 
        _currentStatus == ConnectivityStatus.online && 
        _animationController.isAnimating) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
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
      case ConnectivityStatus.online:
        return FontAwesomeIcons.wifi;
      case ConnectivityStatus.offline:
        return FontAwesomeIcons.wifi;
      case ConnectivityStatus.checking:
        return FontAwesomeIcons.spinner;
      case ConnectivityStatus.unknown:
        return FontAwesomeIcons.question;
    }
  }

  Color _getStatusColor() {
    switch (_currentStatus) {
      case ConnectivityStatus.online:
        return AppTheme.successColor;
      case ConnectivityStatus.offline:
        return AppTheme.errorColor;
      case ConnectivityStatus.checking:
        return AppTheme.warningColor;
      case ConnectivityStatus.unknown:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText() {
    switch (_currentStatus) {
      case ConnectivityStatus.online:
        return 'Conectado';
      case ConnectivityStatus.offline:
        return 'Sin conexión';
      case ConnectivityStatus.checking:
        return 'Verificando...';
      case ConnectivityStatus.unknown:
        return 'Desconocido';
    }
  }
}
