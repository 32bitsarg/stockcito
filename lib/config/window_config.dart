import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class WindowConfig {
  static const double minWidth = 800.0;
  static const double minHeight = 600.0;
  static const double defaultWidth = 1200.0;
  static const double defaultHeight = 800.0;

  static void setWindowConstraints() {
    // Configurar tamaño mínimo de ventana
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // En Windows, establecer tamaño mínimo
    if (Platform.isWindows) {
      // Esto se maneja en el archivo main de Windows
    }
  }
}

// Extensión para detectar plataforma
extension PlatformExtension on BuildContext {
  bool get isWindows => Theme.of(this).platform == TargetPlatform.windows;
  bool get isDesktop => Theme.of(this).platform == TargetPlatform.windows ||
                       Theme.of(this).platform == TargetPlatform.linux ||
                       Theme.of(this).platform == TargetPlatform.macOS;
}
