import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowsWindowService {
  static const double fixedWidth = 1400.0;
  static const double fixedHeight = 800.0;

  static Future<void> initializeWindow() async {
    if (!Platform.isWindows) return;

    await windowManager.ensureInitialized();

    WindowOptions windowOptions = WindowOptions(
      size: const Size(fixedWidth, fixedHeight),
      minimumSize: const Size(fixedWidth, fixedHeight),
      maximumSize: const Size(1920, 1080), // Permitir hasta Full HD
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      windowButtonVisibility: true,
      title: 'Stockcito - Gestión de Inventario',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  static Future<void> setWindowFixed() async {
    if (!Platform.isWindows) return;

    // Habilitar redimensionado pero con límites
    await windowManager.setResizable(true);
    
    // Establecer tamaño mínimo
    await windowManager.setMinimumSize(const Size(fixedWidth, fixedHeight));
    
    // Establecer tamaño máximo (Full HD)
    await windowManager.setMaximumSize(const Size(1920, 1080));
    
    // Establecer tamaño inicial
    await windowManager.setSize(const Size(fixedWidth, fixedHeight));
    
    // Centrar la ventana
    await windowManager.center();
    
    // Asegurar que la ventana esté visible
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> setWindowTitle(String title) async {
    if (!Platform.isWindows) return;
    await windowManager.setTitle(title);
  }

  static Future<void> minimizeWindow() async {
    if (!Platform.isWindows) return;
    await windowManager.minimize();
  }

  static Future<void> maximizeWindow() async {
    if (!Platform.isWindows) return;
    await windowManager.maximize();
  }

  static Future<void> closeWindow() async {
    if (!Platform.isWindows) return;
    await windowManager.close();
  }
}
