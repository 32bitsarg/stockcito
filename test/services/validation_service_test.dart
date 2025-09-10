import 'package:flutter_test/flutter_test.dart';
import 'package:ricitosdebb/services/validation_service.dart';

void main() {
  group('ValidationService', () {
    group('validateRequired', () {
      test('debe retornar null para valores válidos', () {
        expect(ValidationService.validateRequired('test', 'Campo'), isNull);
        expect(ValidationService.validateRequired('  test  ', 'Campo'), isNull);
      });

      test('debe retornar mensaje de error para valores vacíos', () {
        expect(
          ValidationService.validateRequired('', 'Campo'),
          equals('Campo es requerido'),
        );
        expect(
          ValidationService.validateRequired('   ', 'Campo'),
          equals('Campo es requerido'),
        );
        expect(
          ValidationService.validateRequired(null, 'Campo'),
          equals('Campo es requerido'),
        );
      });
    });

    group('validatePositiveNumber', () {
      test('debe retornar null para números válidos', () {
        expect(ValidationService.validatePositiveNumber('123', 'Precio'), isNull);
        expect(ValidationService.validatePositiveNumber('0', 'Precio'), isNull);
        expect(ValidationService.validatePositiveNumber('123.45', 'Precio'), isNull);
      });

      test('debe retornar error para valores inválidos', () {
        expect(
          ValidationService.validatePositiveNumber('', 'Precio'),
          equals('Precio es requerido'),
        );
        expect(
          ValidationService.validatePositiveNumber('abc', 'Precio'),
          equals('Precio debe ser un número válido'),
        );
        expect(
          ValidationService.validatePositiveNumber('-5', 'Precio'),
          equals('Precio debe ser mayor o igual a 0'),
        );
      });
    });

    group('validateEmail', () {
      test('debe retornar null para emails válidos', () {
        expect(ValidationService.validateEmail('test@example.com'), isNull);
        expect(ValidationService.validateEmail('user.name@domain.co.uk'), isNull);
        expect(ValidationService.validateEmail(''), isNull); // Email es opcional
        expect(ValidationService.validateEmail(null), isNull);
      });

      test('debe retornar error para emails inválidos', () {
        expect(
          ValidationService.validateEmail('invalid-email'),
          equals('Email debe tener un formato válido'),
        );
        expect(
          ValidationService.validateEmail('test@'),
          equals('Email debe tener un formato válido'),
        );
        expect(
          ValidationService.validateEmail('@domain.com'),
          equals('Email debe tener un formato válido'),
        );
      });
    });

    group('validatePhone', () {
      test('debe retornar null para teléfonos válidos', () {
        expect(ValidationService.validatePhone('1234567890'), isNull);
        expect(ValidationService.validatePhone('+1234567890'), isNull);
        expect(ValidationService.validatePhone('(123) 456-7890'), isNull);
        expect(ValidationService.validatePhone(''), isNull); // Teléfono es opcional
        expect(ValidationService.validatePhone(null), isNull);
      });

      test('debe retornar error para teléfonos inválidos', () {
        expect(
          ValidationService.validatePhone('123'),
          equals('Teléfono debe tener un formato válido'),
        );
        expect(
          ValidationService.validatePhone('abc'),
          equals('Teléfono debe tener un formato válido'),
        );
      });
    });

    group('validateName', () {
      test('debe retornar null para nombres válidos', () {
        expect(ValidationService.validateName('Juan Pérez', 'Nombre'), isNull);
        expect(ValidationService.validateName('María José', 'Nombre'), isNull);
        expect(ValidationService.validateName('José María', 'Nombre'), isNull);
      });

      test('debe retornar error para nombres inválidos', () {
        expect(
          ValidationService.validateName('', 'Nombre'),
          equals('Nombre es requerido'),
        );
        expect(
          ValidationService.validateName('J', 'Nombre'),
          equals('Nombre debe tener al menos 2 caracteres'),
        );
        expect(
          ValidationService.validateName('Juan123', 'Nombre'),
          equals('Nombre solo puede contener letras y espacios'),
        );
      });
    });

    group('validateStock', () {
      test('debe retornar null para stock válido', () {
        expect(ValidationService.validateStock('10'), isNull);
        expect(ValidationService.validateStock('0'), isNull);
        expect(ValidationService.validateStock('999'), isNull);
      });

      test('debe retornar error para stock inválido', () {
        expect(
          ValidationService.validateStock(''),
          equals('Stock es requerido'),
        );
        expect(
          ValidationService.validateStock('abc'),
          equals('Stock debe ser un número entero válido'),
        );
        expect(
          ValidationService.validateStock('-5'),
          equals('Stock debe ser mayor o igual a 0'),
        );
      });
    });

    group('validatePrice', () {
      test('debe retornar null para precios válidos', () {
        expect(ValidationService.validatePrice('10.50'), isNull);
        expect(ValidationService.validatePrice('0'), isNull);
        expect(ValidationService.validatePrice('999.99'), isNull);
      });

      test('debe retornar error para precios inválidos', () {
        expect(
          ValidationService.validatePrice(''),
          equals('Precio es requerido'),
        );
        expect(
          ValidationService.validatePrice('abc'),
          equals('Precio debe ser un número válido'),
        );
        expect(
          ValidationService.validatePrice('-5'),
          equals('Precio debe ser mayor o igual a 0'),
        );
      });
    });

    group('validateListNotEmpty', () {
      test('debe retornar null para listas no vacías', () {
        expect(ValidationService.validateListNotEmpty([1, 2, 3], 'item'), isNull);
        expect(ValidationService.validateListNotEmpty(['a'], 'item'), isNull);
      });

      test('debe retornar error para listas vacías', () {
        expect(
          ValidationService.validateListNotEmpty([], 'item'),
          equals('Debe agregar al menos un item'),
        );
        expect(
          ValidationService.validateListNotEmpty(null, 'item'),
          equals('Debe agregar al menos un item'),
        );
      });
    });

    group('validatePercentage', () {
      test('debe retornar null para porcentajes válidos', () {
        expect(ValidationService.validatePercentage('0', 'Margen'), isNull);
        expect(ValidationService.validatePercentage('50', 'Margen'), isNull);
        expect(ValidationService.validatePercentage('100', 'Margen'), isNull);
      });

      test('debe retornar error para porcentajes inválidos', () {
        expect(
          ValidationService.validatePercentage('', 'Margen'),
          equals('Margen es requerido'),
        );
        expect(
          ValidationService.validatePercentage('abc', 'Margen'),
          equals('Margen debe ser un número válido'),
        );
        expect(
          ValidationService.validatePercentage('-5', 'Margen'),
          equals('Margen debe estar entre 0 y 100'),
        );
        expect(
          ValidationService.validatePercentage('150', 'Margen'),
          equals('Margen debe estar entre 0 y 100'),
        );
      });
    });
  });
}
