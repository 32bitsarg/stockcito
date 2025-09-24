import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'screens/splash_screen.dart';
import 'services/ui/theme_service.dart';
import 'services/ui/theme_manager_service.dart';
import 'services/ui/windows_window_service.dart';
import 'services/system/logging_service.dart';
import 'services/notifications/smart_notification_service.dart';
import 'services/auth/supabase_auth_service.dart';
import 'services/ml/ml_training_service.dart';
import 'services/datos/datos.dart';
import 'services/datos/dashboard_service.dart';
import 'services/system/data_migration_service.dart';
import 'services/ml/ml_consent_service.dart';
import 'services/system/connectivity_service.dart';
import 'services/datos/enhanced_sync_service.dart';
import 'widgets/window_manager_wrapper.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar logging
  LoggingService.info('Stockcito iniciando...');
  
  // Cargar variables de entorno
  LoggingService.info('Cargando configuración de Supabase...');
  await SupabaseConfig.load();
  LoggingService.info('Configuración de Supabase cargada');
  
  // Inicializar Supabase Auth
  LoggingService.info('Inicializando Supabase Auth...');
  final authService = SupabaseAuthService();
  await authService.initialize();
  LoggingService.info('Supabase Auth inicializado correctamente');
  
  // Inicializar DatosService con dependencia de autenticación
  LoggingService.info('Inicializando DatosService...');
  final datosService = DatosService();
  datosService.initializeAuthService(authService);
  authService.initializeDatosService(datosService);
  
  // Inicializar datos de prueba si la base de datos está vacía
  await datosService.initializeSampleDataIfEmpty();
  
  LoggingService.info('DatosService inicializado correctamente');
  
  // Inicializar MLTrainingService con dependencia de DatosService
  LoggingService.info('Inicializando MLTrainingService...');
  final mlTrainingService = MLTrainingService();
  datosService.initializeMLTrainingService(mlTrainingService);
  await mlTrainingService.initialize();
  LoggingService.info('MLTrainingService inicializado correctamente');
  
  // Inicializar DataMigrationService
  LoggingService.info('Inicializando DataMigrationService...');
  final dataMigrationService = DataMigrationService();
  LoggingService.info('DataMigrationService inicializado correctamente');
  
  // Inicializar MLConsentService
  LoggingService.info('Inicializando MLConsentService...');
  final mlConsentService = MLConsentService();
  LoggingService.info('MLConsentService inicializado correctamente');
  
  // Inicializar ConnectivityService
  LoggingService.info('Inicializando ConnectivityService...');
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  LoggingService.info('ConnectivityService inicializado correctamente');
  
  // Inicializar EnhancedSyncService
  LoggingService.info('Inicializando EnhancedSyncService...');
  final enhancedSyncService = EnhancedSyncService();
  await enhancedSyncService.initialize();
  LoggingService.info('EnhancedSyncService inicializado correctamente');
  
  // Configurar dependencias circulares
  LoggingService.info('Configurando dependencias de servicios...');
  dataMigrationService.initializeServices(
    datosService: datosService,
    mlTrainingService: mlTrainingService,
    consentService: mlConsentService,
  );
  
  mlConsentService.initializeServices(
    mlTrainingService: mlTrainingService,
    dataMigrationService: dataMigrationService,
  );
  
  datosService.initializeMLConsentService(mlConsentService);
  LoggingService.info('Dependencias de servicios configuradas correctamente');
  
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
            ? WindowManagerWrapper(child: app)
            : app;
        },
      ),
    );
  }
}