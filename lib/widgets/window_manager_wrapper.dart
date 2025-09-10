import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../services/windows_window_service.dart';

class WindowManagerWrapper extends StatefulWidget {
  final Widget child;

  const WindowManagerWrapper({
    super.key,
    required this.child,
  });

  @override
  State<WindowManagerWrapper> createState() => _WindowManagerWrapperState();
}

class _WindowManagerWrapperState extends State<WindowManagerWrapper>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      windowManager.addListener(this);
      _setWindowFixed();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _setWindowFixed() async {
    await WindowsWindowService.setWindowFixed();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  // WindowManager listeners
  @override
  void onWindowClose() {
    // Manejar cierre de ventana si es necesario
    super.onWindowClose();
  }

  @override
  void onWindowResize() {
    // Verificar que el tamaño esté dentro de los límites
    if (Platform.isWindows) {
      _ensureSizeWithinLimits();
    }
  }

  Future<void> _ensureSizeWithinLimits() async {
    final size = await windowManager.getSize();
    const minWidth = 1400.0;
    const minHeight = 800.0;
    const maxWidth = 1920.0;
    const maxHeight = 1080.0;

    double newWidth = size.width;
    double newHeight = size.height;

    // Ajustar si es muy pequeño
    if (newWidth < minWidth) newWidth = minWidth;
    if (newHeight < minHeight) newHeight = minHeight;

    // Ajustar si es muy grande
    if (newWidth > maxWidth) newWidth = maxWidth;
    if (newHeight > maxHeight) newHeight = maxHeight;

    // Aplicar el nuevo tamaño si cambió
    if (newWidth != size.width || newHeight != size.height) {
      await windowManager.setSize(Size(newWidth, newHeight));
    }
  }

  @override
  void onWindowMove() {
    // Manejar movimiento de ventana si es necesario
    super.onWindowMove();
  }
}
