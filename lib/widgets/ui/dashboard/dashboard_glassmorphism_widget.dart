import 'dart:ui';
import 'package:flutter/material.dart';

/// Widget que proporciona el efecto glassmorphism al dashboard
class DashboardGlassmorphismWidget extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final List<Color>? gradientColors;
  final double blurSigmaX;
  final double blurSigmaY;
  final double opacity;
  final double borderOpacity;

  const DashboardGlassmorphismWidget({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradientColors,
    this.blurSigmaX = 10.0,
    this.blurSigmaY = 10.0,
    this.opacity = 0.1,
    this.borderOpacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors ?? [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.85),
          ],
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              border: Border.all(
                color: Colors.white.withOpacity(borderOpacity),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
