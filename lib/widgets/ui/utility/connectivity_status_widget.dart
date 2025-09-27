import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';
import '../../../models/connectivity_enums.dart';
import '../../../services/system/connectivity_service.dart';

/// Widget que muestra el estado real de conectividad usando ConnectivityService
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
  
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<ConnectivityInfo>? _connectivitySubscription;
  ConnectivityInfo _currentInfo = ConnectivityInfo(
    status: ConnectivityStatus.unknown,
    networkType: NetworkType.none,
    timestamp: DateTime.now(),
    hasInternet: false,
  );

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeConnectivity();
  }

  void _setupAnimation() {
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

    // Solo iniciar animación si está habilitada y el estado es online
    if (widget.showAnimation && _currentInfo.status == ConnectivityStatus.online) {
      _animationController.repeat(reverse: true);
    }
  }

  Future<void> _initializeConnectivity() async {
    try {
      // Inicializar el servicio de conectividad
      await _connectivityService.initialize();
      
      // Obtener estado inicial
      _currentInfo = _connectivityService.currentInfo;
      
      // Suscribirse a cambios de conectividad
      _connectivitySubscription = _connectivityService.connectivityStream.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ [CONNECTIVITY WIDGET] Error en stream: $error');
        },
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ [CONNECTIVITY WIDGET] Error inicializando conectividad: $e');
    }
  }

  void _onConnectivityChanged(ConnectivityInfo info) {
    if (!mounted) return;
    
    _currentInfo = info;
    
    // Controlar animación basada en el estado
    if (widget.showAnimation) {
      if (info.status == ConnectivityStatus.online && !_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      } else if (info.status != ConnectivityStatus.online && _animationController.isAnimating) {
        _animationController.stop();
      }
    }
    
    setState(() {});
    
    print('🔍 [CONNECTIVITY WIDGET] Estado actualizado: ${info.status} (${info.networkType})');
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

    // Solo aplicar animación si está habilitada y el estado es online
    if (widget.showAnimation && 
        _currentInfo.status == ConnectivityStatus.online && 
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
    switch (_currentInfo.status) {
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
    switch (_currentInfo.status) {
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
    switch (_currentInfo.status) {
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
