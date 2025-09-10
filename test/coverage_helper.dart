import 'package:flutter_test/flutter_test.dart';
import 'package:ricitosdebb/services/validation_service.dart';
import 'package:ricitosdebb/services/error_handler_service.dart';
import 'package:ricitosdebb/services/logging_service.dart';
import 'package:ricitosdebb/services/cache_service.dart';
import 'package:ricitosdebb/services/performance_service.dart';

/// Helper para ejecutar todos los tests y generar cobertura de código
void main() {
  group('Test Suite Completa', () {
    test('debe ejecutar todos los tests de servicios', () async {
      // Este test asegura que todos los servicios se pueden instanciar
      // y no lanzan excepciones durante la inicialización
      
      expect(() => ValidationService(), returnsNormally);
      expect(() => ErrorHandlerService(), returnsNormally);
      expect(() => LoggingService(), returnsNormally);
      expect(() => CacheService(), returnsNormally);
      expect(() => PerformanceService(), returnsNormally);
    });

    test('debe validar que los servicios son singletons', () {
      final validation1 = ValidationService();
      final validation2 = ValidationService();
      expect(identical(validation1, validation2), isTrue);

      final errorHandler1 = ErrorHandlerService();
      final errorHandler2 = ErrorHandlerService();
      expect(identical(errorHandler1, errorHandler2), isTrue);

      final logging1 = LoggingService();
      final logging2 = LoggingService();
      expect(identical(logging1, logging2), isTrue);

      final cache1 = CacheService();
      final cache2 = CacheService();
      expect(identical(cache1, cache2), isTrue);

      final performance1 = PerformanceService();
      final performance2 = PerformanceService();
      expect(identical(performance1, performance2), isTrue);
    });
  });
}
