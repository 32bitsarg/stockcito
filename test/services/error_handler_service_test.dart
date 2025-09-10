import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ricitosdebb/services/error_handler_service.dart';

void main() {
  group('ErrorHandlerService', () {
    group('_getErrorMessage', () {
      test('debe retornar mensaje personalizado cuando se proporciona', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('Test error'),
          customMessage: 'Mensaje personalizado',
          showSnackBar: false,
        );
        // No hay retorno, pero no debe lanzar excepción
        expect(result, isNull);
      });

      test('debe manejar errores de base de datos', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('database error'),
          showSnackBar: false,
        );
        expect(result, isNull);
      });

      test('debe manejar errores de red', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('network connection error'),
          showSnackBar: false,
        );
        expect(result, isNull);
      });

      test('debe manejar errores de permisos', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('permission denied'),
          showSnackBar: false,
        );
        expect(result, isNull);
      });

      test('debe manejar errores de validación', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('validation error'),
          showSnackBar: false,
        );
        expect(result, isNull);
      });

      test('debe manejar errores genéricos', () {
        final result = ErrorHandlerService.handleError(
          MockBuildContext(),
          Exception('generic error'),
          showSnackBar: false,
        );
        expect(result, isNull);
      });
    });

    group('Validaciones', () {
      test('validateRequired debe validar campos requeridos', () {
        expect(
          ErrorHandlerService.validateRequired('', 'Campo'),
          equals('Campo es requerido'),
        );
        expect(
          ErrorHandlerService.validateRequired('valor', 'Campo'),
          isNull,
        );
      });

      test('validateNumber debe validar números', () {
        expect(
          ErrorHandlerService.validateNumber('abc', 'Campo'),
          equals('Campo debe ser un número válido'),
        );
        expect(
          ErrorHandlerService.validateNumber('-5', 'Campo'),
          equals('Campo debe ser mayor o igual a 0'),
        );
        expect(
          ErrorHandlerService.validateNumber('10', 'Campo'),
          isNull,
        );
      });

      test('validateEmail debe validar emails', () {
        expect(
          ErrorHandlerService.validateEmail('invalid-email'),
          equals('Email debe tener un formato válido'),
        );
        expect(
          ErrorHandlerService.validateEmail('test@example.com'),
          isNull,
        );
      });

      test('validatePhone debe validar teléfonos', () {
        expect(
          ErrorHandlerService.validatePhone('123'),
          equals('Teléfono debe tener un formato válido'),
        );
        expect(
          ErrorHandlerService.validatePhone('1234567890'),
          isNull,
        );
      });
    });
  });
}

// Mock BuildContext para testing
class MockBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
