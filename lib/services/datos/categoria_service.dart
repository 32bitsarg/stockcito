import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/categoria.dart';
import '../../services/datos/database/local_database_service.dart';
import '../../services/auth/supabase_auth_service.dart';
import '../../services/system/logging_service.dart';

class CategoriaService {
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final SupabaseAuthService _authService = SupabaseAuthService();

  /// Obtiene todas las categorías del usuario
  Future<List<Categoria>> getCategorias() async {
    try {
      // Obtener categorías de la base de datos local
      final categoriasLocales = await _localDb.getAllCategorias();
      
      // Si no hay categorías locales, cargar las por defecto
      if (categoriasLocales.isEmpty) {
        await _cargarCategoriasPorDefecto();
        return await _localDb.getAllCategorias();
      }
      
      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _sincronizarConSupabase();
        return await _localDb.getAllCategorias();
      }
      
      return categoriasLocales;
    } catch (e) {
      LoggingService.error('Error obteniendo categorías: $e');
      return [];
    }
  }

  /// Guarda una nueva categoría
  Future<Categoria> saveCategoria(Categoria categoria) async {
    try {
      final now = DateTime.now();
      final categoriaConFechas = categoria.copyWith(
        fechaCreacion: now,
        updatedAt: now,
      );

      // Guardar en base de datos local
      final id = await _localDb.insertCategoria(categoriaConFechas);
      final categoriaGuardada = categoriaConFechas.copyWith(id: id);

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _syncCategoriaWithSupabase(categoriaGuardada);
      }

      LoggingService.info('Categoría guardada: ${categoriaGuardada.nombre}');
      return categoriaGuardada;
    } catch (e) {
      LoggingService.error('Error guardando categoría: $e');
      rethrow;
    }
  }

  /// Actualiza una categoría existente
  Future<Categoria> updateCategoria(Categoria categoria) async {
    try {
      final now = DateTime.now();
      final categoriaActualizada = categoria.copyWith(updatedAt: now);

      // Actualizar en base de datos local
      await _localDb.updateCategoria(categoriaActualizada);

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _syncCategoriaWithSupabase(categoriaActualizada);
      }

      LoggingService.info('Categoría actualizada: ${categoriaActualizada.nombre}');
      return categoriaActualizada;
    } catch (e) {
      LoggingService.error('Error actualizando categoría: $e');
      rethrow;
    }
  }

  /// Elimina una categoría
  Future<void> deleteCategoria(int id) async {
    try {
      // Eliminar de base de datos local
      await _localDb.deleteCategoria(id);

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _deleteCategoriaFromSupabase(id);
      }

      LoggingService.info('Categoría eliminada: $id');
    } catch (e) {
      LoggingService.error('Error eliminando categoría: $e');
      rethrow;
    }
  }

  /// Carga las categorías por defecto en la base de datos local
  Future<void> _cargarCategoriasPorDefecto() async {
    try {
      final categoriasPorDefecto = Categoria.getCategoriasPorDefecto();
      final userId = _authService.currentUserId ?? 'default';
      
      for (final categoria in categoriasPorDefecto) {
        final categoriaConUserId = categoria.copyWith(userId: userId);
        await _localDb.insertCategoria(categoriaConUserId);
      }
      
      LoggingService.info('Categorías por defecto cargadas');
    } catch (e) {
      LoggingService.error('Error cargando categorías por defecto: $e');
    }
  }

  /// Sincroniza las categorías con Supabase
  Future<void> _sincronizarConSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUserId;
      
      if (userId == null) return;

      // Obtener categorías de Supabase
      final response = await supabase
          .from('categorias')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion');

      final categoriasSupabase = (response as List)
          .map((json) => Categoria.fromSupabaseMap(json))
          .toList();

      // Obtener categorías locales
      final categoriasLocales = await _localDb.getAllCategorias();

      // Sincronizar: agregar categorías de Supabase que no están localmente
      for (final categoriaSupabase in categoriasSupabase) {
        final existeLocal = categoriasLocales.any((c) => c.nombre == categoriaSupabase.nombre);
        if (!existeLocal) {
          await _localDb.insertCategoria(categoriaSupabase);
        }
      }

      // Sincronizar: enviar categorías locales que no están en Supabase
      for (final categoriaLocal in categoriasLocales) {
        if (!categoriaLocal.isDefault) {
          final existeSupabase = categoriasSupabase.any((c) => c.nombre == categoriaLocal.nombre);
          if (!existeSupabase) {
            await _syncCategoriaWithSupabase(categoriaLocal);
          }
        }
      }

      LoggingService.info('Categorías sincronizadas con Supabase');
    } catch (e) {
      LoggingService.error('Error sincronizando categorías con Supabase: $e');
    }
  }

  /// Sincroniza una categoría específica con Supabase
  Future<void> _syncCategoriaWithSupabase(Categoria categoria) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUserId;
      
      if (userId == null) return;

      final categoriaData = categoria.toSupabaseMap();
      categoriaData['user_id'] = userId;

      await supabase.from('categorias').upsert(categoriaData);
      
      LoggingService.info('Categoría sincronizada con Supabase: ${categoria.nombre}');
    } catch (e) {
      LoggingService.error('Error sincronizando categoría con Supabase: $e');
    }
  }

  /// Elimina una categoría de Supabase
  Future<void> _deleteCategoriaFromSupabase(int id) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = _authService.currentUserId;
      
      if (userId == null) return;

      await supabase
          .from('categorias')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      
      LoggingService.info('Categoría eliminada de Supabase: $id');
    } catch (e) {
      LoggingService.error('Error eliminando categoría de Supabase: $e');
    }
  }
}
