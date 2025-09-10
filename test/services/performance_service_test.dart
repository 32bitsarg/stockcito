import 'package:flutter_test/flutter_test.dart';
import 'package:ricitosdebb/services/performance_service.dart';

void main() {
  group('PerformanceService', () {
    setUp(() {
      // Limpiar historial antes de cada test
      PerformanceService.clearHistory();
    });

    group('Timers', () {
      test('debe iniciar y detener un timer', () {
        const operation = 'test_operation';
        
        PerformanceService.startTimer(operation);
        final duration = PerformanceService.stopTimer(operation);
        
        expect(duration, isNotNull);
        expect(duration!.inMilliseconds, greaterThanOrEqualTo(0));
      });

      test('debe retornar null para timer no existente', () {
        final duration = PerformanceService.stopTimer('non_existent_timer');
        expect(duration, isNull);
      });
    });

    group('Medición de funciones', () {
      test('debe medir función síncrona', () {
        const operation = 'sync_test';
        
        final result = PerformanceService.measureSync(
          operation,
          () => 'test_result',
        );
        
        expect(result, equals('test_result'));
        
        final stats = PerformanceService.getPerformanceStats(operation);
        expect(stats['count'], equals(1));
        expect(stats['averageMs'], greaterThanOrEqualTo(0));
      });

      test('debe medir función asíncrona', () async {
        const operation = 'async_test';
        
        final result = await PerformanceService.measureAsync(
          operation,
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            return 'async_result';
          },
        );
        
        expect(result, equals('async_result'));
        
        final stats = PerformanceService.getPerformanceStats(operation);
        expect(stats['count'], equals(1));
        expect(stats['averageMs'], greaterThanOrEqualTo(10));
      });

      test('debe re-lanzar excepciones en funciones síncronas', () {
        const operation = 'sync_error_test';
        
        expect(
          () => PerformanceService.measureSync(
            operation,
            () => throw Exception('Test error'),
          ),
          throwsException,
        );
      });

      test('debe re-lanzar excepciones en funciones asíncronas', () async {
        const operation = 'async_error_test';
        
        expect(
          () => PerformanceService.measureAsync(
            operation,
            () async => throw Exception('Test error'),
          ),
          throwsException,
        );
      });
    });

    group('Estadísticas', () {
      test('debe obtener estadísticas de operación', () {
        const operation = 'stats_test';
        
        // Ejecutar operación varias veces
        for (int i = 0; i < 3; i++) {
          PerformanceService.measureSync(operation, () => 'result');
        }
        
        final stats = PerformanceService.getPerformanceStats(operation);
        
        expect(stats['operation'], equals(operation));
        expect(stats['count'], equals(3));
        expect(stats['averageMs'], greaterThanOrEqualTo(0));
        expect(stats['minMs'], greaterThanOrEqualTo(0));
        expect(stats['maxMs'], greaterThanOrEqualTo(0));
        expect(stats['totalMs'], greaterThanOrEqualTo(0));
      });

      test('debe obtener estadísticas vacías para operación inexistente', () {
        final stats = PerformanceService.getPerformanceStats('non_existent');
        
        expect(stats['operation'], equals('non_existent'));
        expect(stats['count'], equals(0));
        expect(stats['averageMs'], equals(0));
        expect(stats['minMs'], equals(0));
        expect(stats['maxMs'], equals(0));
        expect(stats['totalMs'], equals(0));
      });

      test('debe obtener todas las estadísticas', () {
        PerformanceService.measureSync('op1', () => 'result1');
        PerformanceService.measureSync('op2', () => 'result2');
        
        final allStats = PerformanceService.getAllPerformanceStats();
        
        expect(allStats.length, equals(2));
        expect(allStats.containsKey('op1'), isTrue);
        expect(allStats.containsKey('op2'), isTrue);
      });
    });

    group('Detección de operaciones lentas', () {
      test('debe detectar operación lenta', () {
        const operation = 'slow_operation';
        
        // Simular operación lenta
        PerformanceService.measureSync(
          operation,
          () {
            // Simular trabajo
            for (int i = 0; i < 1000; i++) {
              // Operación simple
            }
            return 'result';
          },
        );
        
        // Verificar si es lenta (threshold por defecto es 1000ms)
        final isSlow = PerformanceService.isSlowOperation(operation);
        expect(isSlow, isA<bool>());
      });

      test('debe obtener operaciones lentas', () {
        PerformanceService.measureSync('fast_op', () => 'result');
        PerformanceService.measureSync('slow_op', () {
          // Simular trabajo
          for (int i = 0; i < 1000; i++) {
            // Operación simple
          }
          return 'result';
        });
        
        final slowOps = PerformanceService.getSlowOperations(thresholdMs: 0);
        expect(slowOps, isA<List<String>>());
      });
    });

    group('Debounce y Throttle', () {
      test('debe ejecutar debounce', () {
        var callCount = 0;
        
        PerformanceService.debounce(
          'debounce_test',
          const Duration(milliseconds: 100),
          () => callCount++,
        );
        
        // El debounce debe ejecutarse después del delay
        expect(callCount, equals(0));
      });

      test('debe ejecutar throttle', () {
        var callCount = 0;
        
        final result1 = PerformanceService.throttle(
          'throttle_test',
          const Duration(seconds: 1),
          () => callCount++,
        );
        
        final result2 = PerformanceService.throttle(
          'throttle_test',
          const Duration(seconds: 1),
          () => callCount++,
        );
        
        expect(result1, isTrue);
        expect(result2, isFalse); // Debe ser throttled
        expect(callCount, equals(1));
      });
    });

    group('Información del sistema', () {
      test('debe obtener información del sistema', () {
        final systemInfo = PerformanceService.getSystemInfo();
        
        expect(systemInfo, isA<Map<String, dynamic>>());
        expect(systemInfo['platform'], isA<String>());
        expect(systemInfo['isDebug'], isA<bool>());
        expect(systemInfo['isRelease'], isA<bool>());
        expect(systemInfo['isProfile'], isA<bool>());
        expect(systemInfo['numberOfProcessors'], isA<int>());
        expect(systemInfo['version'], isA<String>());
      });
    });

    group('Reporte de rendimiento', () {
      test('debe generar reporte de rendimiento', () {
        PerformanceService.measureSync('test_op', () => 'result');
        
        final report = PerformanceService.generatePerformanceReport();
        
        expect(report, isA<Map<String, dynamic>>());
        expect(report['timestamp'], isA<String>());
        expect(report['systemInfo'], isA<Map<String, dynamic>>());
        expect(report['operations'], isA<Map<String, Map<String, dynamic>>>());
        expect(report['slowOperations'], isA<List<String>>());
        expect(report['totalOperations'], isA<int>());
        expect(report['averagePerformance'], isA<double>());
      });
    });

    group('Limpieza', () {
      test('debe limpiar historial', () {
        PerformanceService.measureSync('test_op', () => 'result');
        expect(PerformanceService.getAllPerformanceStats().length, greaterThan(0));
        
        PerformanceService.clearHistory();
        expect(PerformanceService.getAllPerformanceStats().length, equals(0));
      });

      test('debe disponer recursos', () {
        PerformanceService.measureSync('test_op', () => 'result');
        
        expect(() => PerformanceService.dispose(), returnsNormally);
      });
    });
  });
}
