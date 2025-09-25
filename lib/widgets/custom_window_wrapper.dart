import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Widget que envuelve la aplicación y maneja la configuración de ventana
class CustomWindowWrapper extends StatefulWidget {
  final Widget child;

  const CustomWindowWrapper({
    super.key,
    required this.child,
  });

  @override
  State<CustomWindowWrapper> createState() => _CustomWindowWrapperState();
}

class _CustomWindowWrapperState extends State<CustomWindowWrapper> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initWindow();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _initWindow() async {
    // Configuración básica de ventana
    await windowManager.setResizable(true);
    await windowManager.setMinimizable(true);
    await windowManager.setMaximizable(true);
    await windowManager.setClosable(true);
    await windowManager.setMinimumSize(const Size(1000, 800)); // Tamaño mínimo
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onWindowClose() {
    // Manejar el cierre de ventana
    windowManager.close();
  }

  @override
  void onWindowMinimize() {
    // Manejar minimización
  }

  @override
  void onWindowMaximize() {
    // Manejar maximización
  }

  @override
  void onWindowUnmaximize() {
    // Manejar restauración
  }
}
