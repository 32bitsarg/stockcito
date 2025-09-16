import 'package:flutter_test/flutter_test.dart';
import 'package:stockcito/services/system/cache_service.dart';

void main() {
  group('CacheService', () {
    setUp(() async {
      // Limpiar caché antes de cada test
      await CacheService.clear();
    });

    group('Operaciones básicas', () {
      test('debe guardar y recuperar un valor simple', () async {
        const key = 'test_key';
        const value = 'test_value';
        
        await CacheService.set(key, value, (v) => v);
        final result = await CacheService.get<String>(key, (json) => json['value'] as String);
        
        expect(result, equals(value));
      });

      test('debe guardar y recuperar un mapa', () async {
        const key = 'test_map';
        final value = {'name': 'test', 'value': 123};
        
        await CacheService.set(key, value, (v) => v);
        final result = await CacheService.get<Map<String, dynamic>>(
          key, 
          (json) => json['value'] as Map<String, dynamic>,
        );
        
        expect(result, equals(value));
      });

      test('debe retornar null para clave no existente', () async {
        final result = await CacheService.get<String>(
          'non_existent_key', 
          (json) => json['value'] as String,
        );
        
        expect(result, isNull);
      });

      test('debe eliminar un valor', () async {
        const key = 'test_key';
        const value = 'test_value';
        
        await CacheService.set(key, value, (v) => v);
        await CacheService.remove(key);
        
        final result = await CacheService.get<String>(key, (json) => json['value'] as String);
        expect(result, isNull);
      });
    });

    group('Expiración', () {
      test('debe retornar null para valores expirados', () async {
        const key = 'expired_key';
        const value = 'test_value';
        
        // Guardar con expiración muy corta
        await CacheService.set(
          key, 
          value, 
          (v) => v,
          expiry: const Duration(milliseconds: 1),
        );
        
        // Esperar a que expire
        await Future.delayed(const Duration(milliseconds: 10));
        
        final result = await CacheService.get<String>(key, (json) => json['value'] as String);
        expect(result, isNull);
      });

      test('debe retornar valor válido antes de expirar', () async {
        const key = 'valid_key';
        const value = 'test_value';
        
        await CacheService.set(
          key, 
          value, 
          (v) => v,
          expiry: const Duration(seconds: 1),
        );
        
        final result = await CacheService.get<String>(key, (json) => json['value'] as String);
        expect(result, equals(value));
      });
    });

    group('Verificaciones', () {
      test('debe verificar si una clave existe', () async {
        const key = 'test_key';
        const value = 'test_value';
        
        expect(await CacheService.exists(key), isFalse);
        
        await CacheService.set(key, value, (v) => v);
        
        expect(await CacheService.exists(key), isTrue);
      });

      test('debe obtener el tamaño del caché', () async {
        expect(await CacheService.getSize(), equals(0));
        
        await CacheService.set('key1', 'value1', (v) => v);
        expect(await CacheService.getSize(), equals(1));
        
        await CacheService.set('key2', 'value2', (v) => v);
        expect(await CacheService.getSize(), equals(2));
      });
    });

    group('Limpieza', () {
      test('debe limpiar todo el caché', () async {
        await CacheService.set('key1', 'value1', (v) => v);
        await CacheService.set('key2', 'value2', (v) => v);
        
        expect(await CacheService.getSize(), equals(2));
        
        await CacheService.clear();
        
        expect(await CacheService.getSize(), equals(0));
      });

      test('debe limpiar elementos expirados', () async {
        // Agregar elemento válido
        await CacheService.set('valid_key', 'valid_value', (v) => v);
        
        // Agregar elemento expirado
        await CacheService.set(
          'expired_key', 
          'expired_value', 
          (v) => v,
          expiry: const Duration(milliseconds: 1),
        );
        
        // Esperar a que expire
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Limpiar expirados
        await CacheService.cleanExpired();
        
        // Verificar que solo queda el elemento válido
        expect(await CacheService.getSize(), equals(1));
        expect(await CacheService.exists('valid_key'), isTrue);
        expect(await CacheService.exists('expired_key'), isFalse);
      });
    });

    group('Información del caché', () {
      test('debe obtener información del caché', () async {
        final info = await CacheService.getInfo();
        
        expect(info, isA<Map<String, dynamic>>());
        expect(info['totalItems'], isA<int>());
        expect(info['validItems'], isA<int>());
        expect(info['expiredItems'], isA<int>());
        expect(info['lastCleanup'], isA<String>());
      });
    });
  });
}
