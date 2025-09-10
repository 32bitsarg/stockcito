import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowService {
  static const double fixedWidth = 1400.0;
  static const double fixedHeight = 800.0;

  static Future<void> setWindowConstraints() async {
    // Configurar orientaciones permitidas
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
  }

  static Widget buildFixedLayout({
    required Widget child,
  }) {
    return Container(
      width: fixedWidth,
      height: fixedHeight,
      child: child,
    );
  }

}
