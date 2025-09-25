import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/app_theme.dart';

class TutorialOverlayWidget extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const TutorialOverlayWidget({
    super.key,
    required this.steps,
    this.onComplete,
    this.onSkip,
  });

  @override
  State<TutorialOverlayWidget> createState() => _TutorialOverlayWidgetState();
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final GlobalKey targetKey;
  final String? imagePath;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.targetKey,
    this.imagePath,
  });
}

class _TutorialOverlayWidgetState extends State<TutorialOverlayWidget>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= widget.steps.length) {
      return const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    final targetContext = step.targetKey.currentContext;
    
    if (targetContext == null) {
      return const SizedBox.shrink();
    }

    final RenderBox targetBox = targetContext.findRenderObject() as RenderBox;
    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final targetSize = targetBox.size;

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Overlay oscuro con agujero
          CustomPaint(
            painter: HolePainter(
              holeRect: Rect.fromLTWH(
                targetPosition.dx - 8,
                targetPosition.dy - 8,
                targetSize.width + 16,
                targetSize.height + 16,
              ),
            ),
            size: MediaQuery.of(context).size,
          ),

          // Tooltip del tutorial
          Positioned(
            left: _getTooltipPosition(targetPosition, targetSize).dx,
            top: _getTooltipPosition(targetPosition, targetSize).dy,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildTooltip(step),
                  ),
                );
              },
            ),
          ),

          // Botones de navegación
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: _buildNavigationButtons(),
          ),
        ],
      ),
    );
  }

  Widget _buildTooltip(TutorialStep step) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  step.icon,
                  color: step.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Descripción
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),

          // Imagen si existe
          if (step.imagePath != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  step.imagePath!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón saltar
          TextButton(
            onPressed: () {
              widget.onSkip?.call();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Saltar Tutorial',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),

          // Indicadores de pasos
          Row(
            children: List.generate(widget.steps.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == _currentStep
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),

          // Botón siguiente/anterior
          Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  child: const Text(
                    'Anterior',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _currentStep == widget.steps.length - 1 ? 'Finalizar' : 'Siguiente',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Offset _getTooltipPosition(Offset targetPosition, Size targetSize) {
    final screenSize = MediaQuery.of(context).size;
    final tooltipWidth = 320.0;
    final tooltipHeight = 200.0; // Estimado

    double x = targetPosition.dx + targetSize.width / 2 - tooltipWidth / 2;
    double y = targetPosition.dy - tooltipHeight - 20;

    // Ajustar si se sale de la pantalla
    if (x < 20) x = 20;
    if (x + tooltipWidth > screenSize.width - 20) {
      x = screenSize.width - tooltipWidth - 20;
    }
    if (y < 20) {
      y = targetPosition.dy + targetSize.height + 20;
    }

    return Offset(x, y);
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _animationController.reset();
      _animationController.forward();
    } else {
      widget.onComplete?.call();
      Navigator.of(context).pop();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }
}

class HolePainter extends CustomPainter {
  final Rect holeRect;

  HolePainter({required this.holeRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        holeRect,
        const Radius.circular(8),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
