import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'screens/dashboard_screen.dart';
import 'services/dashboard_service.dart';
import 'services/theme_service.dart';
import 'services/theme_manager_service.dart';
import 'services/windows_window_service.dart';
import 'services/logging_service.dart';
import 'services/smart_notification_service.dart';
import 'widgets/window_manager_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar logging
  LoggingService.info('Stockcito iniciando...');
  
  try {
    // Configurar ventana de Windows solo si es Windows
    if (Platform.isWindows) {
      LoggingService.info('Configurando ventana de Windows...');
      await WindowsWindowService.initializeWindow();
      LoggingService.info('Ventana de Windows configurada correctamente');
    }
    
    // Inicializar servicio de notificaciones inteligentes
    LoggingService.info('Inicializando notificaciones inteligentes...');
    await SmartNotificationService().initialize();
    LoggingService.info('Notificaciones inteligentes inicializadas');
    
    LoggingService.info('Iniciando Stockcito...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    LoggingService.error(
      'Error crítico al inicializar la aplicación',
      error: e,
      stackTrace: stackTrace,
    );
    
    // Fallback sin configuración de ventana
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => ThemeManagerService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          // Solo envolver en WindowManagerWrapper en Windows
          final app = MaterialApp(
            title: 'Stockcito',
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const DashboardScreen(),
            debugShowCheckedModeBanner: false,
          );
          
          return Platform.isWindows 
            ? WindowManagerWrapper(child: app)
            : app;
        },
      ),
    );
  }
}