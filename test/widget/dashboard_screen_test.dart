import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ricitosdebb/screens/dashboard_screen.dart';
import 'package:ricitosdebb/services/dashboard_service.dart';
import 'package:ricitosdebb/services/theme_service.dart';
import 'package:ricitosdebb/services/theme_manager_service.dart';

void main() {
  group('DashboardScreen Widget Tests', () {
    late DashboardService dashboardService;
    late ThemeService themeService;
    late ThemeManagerService themeManagerService;

    setUp(() {
      dashboardService = DashboardService();
      themeService = ThemeService();
      themeManagerService = ThemeManagerService();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => dashboardService),
          ChangeNotifierProvider(create: (_) => themeService),
          ChangeNotifierProvider(create: (_) => themeManagerService),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
        ),
      );
    }

    testWidgets('debe mostrar elementos principales del dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que se muestran los elementos principales
      expect(find.text('Bienvenido a Stockcito'), findsOneWidget);
      expect(find.text('Métricas principales'), findsOneWidget);
      expect(find.text('Gráfico de ventas'), findsOneWidget);
      expect(find.text('Información del Negocio'), findsOneWidget);
    });

    testWidgets('debe mostrar métricas cuando hay datos', (WidgetTester tester) async {
      // Simular datos en el dashboard
      await dashboardService.cargarDatos();
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que se muestran las métricas
      expect(find.text('Total Productos'), findsOneWidget);
      expect(find.text('Ventas del Mes'), findsOneWidget);
      expect(find.text('Stock Bajo'), findsOneWidget);
      expect(find.text('Total Clientes'), findsOneWidget);
    });

    testWidgets('debe mostrar botón de tutorial', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Tutorial'), findsOneWidget);
    });

    testWidgets('debe mostrar botón de reintentar cuando hay error', (WidgetTester tester) async {
      // Simular error en el dashboard
      await dashboardService.cargarDatos();
      // Forzar un error
      dashboardService.error = 'Error de prueba';
      dashboardService.notifyListeners();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('debe mostrar indicador de carga', (WidgetTester tester) async {
      // Simular estado de carga
      dashboardService.isLoading = true;
      dashboardService.notifyListeners();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar sidebar con opciones de navegación', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar opciones del sidebar
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Inventario'), findsOneWidget);
      expect(find.text('Ventas'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('debe mostrar header con información de la aplicación', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Stockcito'), findsOneWidget);
      expect(find.text('Sistema de Gestión de Inventario'), findsOneWidget);
    });

    testWidgets('debe mostrar gráfico de ventas', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que se muestra el contenedor del gráfico
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('debe mostrar información del negocio', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Margen Promedio'), findsOneWidget);
      expect(find.text('Stock Bajo'), findsOneWidget);
      expect(find.text('Productos Activos'), findsOneWidget);
      expect(find.text('Última Venta'), findsOneWidget);
    });

    testWidgets('debe responder a cambios de estado del dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Cambiar estado de carga
      dashboardService.isLoading = true;
      dashboardService.notifyListeners();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cambiar a estado normal
      dashboardService.isLoading = false;
      dashboardService.notifyListeners();
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('debe mostrar botones de acción', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar botones de acción principales
      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Agregar Producto'), findsOneWidget);
    });

    testWidgets('debe ser responsive', (WidgetTester tester) async {
      // Probar con diferentes tamaños de pantalla
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);

      // Cambiar tamaño de pantalla
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
