import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'screens/splash_screen.dart';
import 'services/ui/theme_service.dart';
import 'services/ui/theme_manager_service.dart';
import 'services/ui/windows_window_service.dart';
import 'services/system/logging_service.dart';
import 'services/notifications/smart_notification_service.dart';
import 'services/datos/dashboard_service.dart';
import 'services/system/sentry_service.dart';
import 'services/system/service_manager.dart';
import 'widgets/custom_window_wrapper.dart';
import 'config/supabase_config.dart';
import 'config/sentry_config.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar window_manager básico
  await windowManager.ensureInitialized();
  
  // Configuración básica de ventana
  await windowManager.setSize(const Size(1000, 800));
  await windowManager.setMinimumSize(const Size(1000, 800)); // Tamaño mínimo
  await windowManager.setResizable(true); // Permitir redimensionamiento
  await windowManager.center();
  
  // Configuración adicional de SystemChrome
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  await windowManager.waitUntilReadyToShow();
  await windowManager.show();
  await windowManager.focus();
  
  // Inicializar Sentry primero para capturar cualquier error durante el startup
  await SentryService().initialize();
  
  // Configurar logging
  LoggingService.info('Stockcito iniciando...');
  
  // Cargar variables de entorno
  LoggingService.info('Cargando configuración de Supabase...');
  await SupabaseConfig.load();
  LoggingService.info('Configuración de Supabase cargada');
  
  // Cargar configuración de Sentry
  LoggingService.info('Cargando configuración de Sentry...');
  await SentryConfig.load();
  LoggingService.info('Configuración de Sentry cargada');
  
  // Inicializar todos los servicios usando ServiceManager
  LoggingService.info('Inicializando todos los servicios con ServiceManager...');
  final serviceManager = ServiceManager();
  await serviceManager.initializeAllServices();
  LoggingService.info('Todos los servicios inicializados correctamente');
  
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
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
          
          return Platform.isWindows 
            ? CustomWindowWrapper(child: app)
            : app;
        },
      ),
    );
  }
}