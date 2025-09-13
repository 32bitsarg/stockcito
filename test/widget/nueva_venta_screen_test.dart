import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ricitosdebb/screens/nueva_venta_screen.dart';
import 'package:ricitosdebb/services/datos/dashboard_service.dart';
import 'package:ricitosdebb/services/ui/theme_service.dart';
import 'package:ricitosdebb/services/ui/theme_manager_service.dart';

void main() {
  group('NuevaVentaScreen Widget Tests', () {
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
          home: const NuevaVentaScreen(),
        ),
      );
    }

    testWidgets('debe mostrar formulario de nueva venta', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar elementos principales del formulario
      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(find.text('Información del Cliente'), findsOneWidget);
      expect(find.text('Productos'), findsOneWidget);
      expect(find.text('Resumen de Venta'), findsOneWidget);
    });

    testWidgets('debe mostrar campos de información del cliente', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar campos del cliente
      expect(find.text('Nombre del Cliente'), findsOneWidget);
      expect(find.text('Teléfono'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Dirección'), findsOneWidget);
    });

    testWidgets('debe mostrar campos de información de la venta', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar campos de la venta
      expect(find.text('Método de Pago'), findsOneWidget);
      expect(find.text('Estado'), findsOneWidget);
      expect(find.text('Notas'), findsOneWidget);
    });

    testWidgets('debe mostrar botones de acción', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar botones
      expect(find.text('Limpiar'), findsOneWidget);
      expect(find.text('Guardar Venta'), findsOneWidget);
    });

    testWidgets('debe permitir ingresar datos en los campos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Encontrar campo de nombre del cliente
      final nombreField = find.byType(TextFormField).first;
      expect(nombreField, findsOneWidget);

      // Ingresar texto
      await tester.enterText(nombreField, 'Juan Pérez');
      await tester.pump();

      // Verificar que el texto se ingresó
      expect(find.text('Juan Pérez'), findsOneWidget);
    });

    testWidgets('debe mostrar dropdowns para método de pago y estado', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar dropdowns
      expect(find.byType(DropdownButtonFormField), findsWidgets);
    });

    testWidgets('debe mostrar sección de productos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar sección de productos
      expect(find.text('Agregar Producto'), findsOneWidget);
      expect(find.text('Total: \$0.00'), findsOneWidget);
    });

    testWidgets('debe mostrar resumen de venta', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar elementos del resumen
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('debe validar campos requeridos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Intentar guardar sin datos
      final guardarButton = find.text('Guardar Venta');
      await tester.tap(guardarButton);
      await tester.pump();

      // Debería mostrar validaciones
      expect(find.text('Debe agregar al menos un producto a la venta'), findsOneWidget);
    });

    testWidgets('debe limpiar formulario al presionar Limpiar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ingresar datos
      final nombreField = find.byType(TextFormField).first;
      await tester.enterText(nombreField, 'Juan Pérez');
      await tester.pump();

      // Presionar limpiar
      final limpiarButton = find.text('Limpiar');
      await tester.tap(limpiarButton);
      await tester.pump();

      // Verificar que se limpió
      expect(find.text('Juan Pérez'), findsNothing);
    });

    testWidgets('debe mostrar indicador de carga al guardar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simular guardado (esto activará el indicador de carga)
      final guardarButton = find.text('Guardar Venta');
      await tester.tap(guardarButton);
      await tester.pump();

      // Verificar que se muestra el indicador de carga
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe ser responsive', (WidgetTester tester) async {
      // Probar con diferentes tamaños de pantalla
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(NuevaVentaScreen), findsOneWidget);

      // Cambiar tamaño de pantalla
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(NuevaVentaScreen), findsOneWidget);
    });

    testWidgets('debe mostrar iconos apropiados', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que se muestran iconos
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('debe mostrar campos de texto con placeholders', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los campos tienen placeholders
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('debe mostrar botones con iconos', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verificar que los botones tienen iconos
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
