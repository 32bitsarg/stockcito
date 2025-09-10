import 'package:flutter/material.dart';

class WindowConstraints {
  // Tamaño fijo de la ventana
  static const double width = 1400.0;
  static const double height = 800.0;
  
  // Tamaño mínimo (por si acaso)
  static const double minWidth = 1400.0;
  static const double minHeight = 800.0;
  
  // Tamaño máximo (igual al fijo para evitar redimensionado)
  static const double maxWidth = 1400.0;
  static const double maxHeight = 800.0;
  
  // Configuración de la ventana
  static const Size windowSize = Size(width, height);
  static const Size minWindowSize = Size(minWidth, minHeight);
  static const Size maxWindowSize = Size(maxWidth, maxHeight);
  
  // Widget para forzar el tamaño fijo
  static Widget buildFixedSizeWidget({required Widget child}) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}
