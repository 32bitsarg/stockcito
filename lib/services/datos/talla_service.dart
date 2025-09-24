import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/talla.dart';
import 'package:stockcito/services/datos/database/local_database_service.dart';
import 'package:stockcito/services/auth/supabase_auth_service.dart';
import 'package:stockcito/services/datos/datos.dart';

class TallaService {
  static final TallaService _instance = TallaService._internal();
  factory TallaService() => _instance;
  TallaService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  final SupabaseAuthService _authService = SupabaseAuthService();

  /// Obtiene todas las tallas del usuario
  Future<List<Talla>> getTallas() async {
    try {
      // Obtener tallas de la base de datos local
      final tallasLocales = await _localDb.getAllTallas();
      
      // Si no hay tallas locales, cargar las por defecto
      if (tallasLocales.isEmpty) {
        await _cargarTallasPorDefecto();
        return await _localDb.getAllTallas();
      }
      
      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _sincronizarConSupabase();
        return await _localDb.getAllTallas();
      }
      
      return tallasLocales;
    } catch (e) {
      LoggingService.error('Error obteniendo tallas: $e');
      return [];
    }
  }

  /// Guarda una nueva talla
  Future<Talla> saveTalla(Talla talla) async {
    try {
      print('💾 TallaService: Guardando talla...');
      print('💾 TallaService: Talla recibida con id: ${talla.id}');
      
      final now = DateTime.now();
      // Crear una nueva talla sin ID para inserciones nuevas
      final tallaSinId = Talla(
        nombre: talla.nombre,
        descripcion: talla.descripcion,
        orden: talla.orden,
        userId: talla.userId,
        isDefault: talla.isDefault,
        fechaCreacion: now,
        updatedAt: now,
      );
      
      print('💾 TallaService: Talla sin ID - id: ${tallaSinId.id}');
      print('💾 TallaService: toMap(): ${tallaSinId.toMap()}');

      // Guardar en base de datos local
      print('💾 TallaService: Insertando en base de datos local...');
      final id = await _localDb.insertTalla(tallaSinId);
      print('💾 TallaService: ID generado por la base de datos: $id');
      
      final tallaGuardada = tallaSinId.copyWith(id: id);
      print('💾 TallaService: Talla guardada con id final: ${tallaGuardada.id}');

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _sincronizarConSupabase();
      }

      LoggingService.info('Talla guardada: ${tallaGuardada.nombre}');
      return tallaGuardada;
    } catch (e) {
      print('❌ TallaService: Error guardando talla: $e');
      LoggingService.error('Error guardando talla: $e');
      rethrow;
    }
  }

  /// Actualiza una talla existente
  Future<Talla> updateTalla(Talla talla) async {
    try {
      // Verificar si ya existe una talla con el mismo nombre (excluyendo la talla actual)
      final tallasExistentes = await _localDb.getAllTallas();
      final tallaExistente = tallasExistentes.any((t) => 
        t.nombre.toLowerCase() == talla.nombre.toLowerCase() && 
        t.id != talla.id
      );
      
      if (tallaExistente) {
        throw Exception('Ya existe una talla con el nombre "${talla.nombre}"');
      }
      
      final now = DateTime.now();
      final tallaActualizada = talla.copyWith(updatedAt: now);

      // Actualizar en base de datos local
      await _localDb.updateTalla(tallaActualizada);

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _sincronizarConSupabase();
      }

      LoggingService.info('Talla actualizada: ${tallaActualizada.nombre}');
      return tallaActualizada;
    } catch (e) {
      LoggingService.error('Error actualizando talla: $e');
      rethrow;
    }
  }

  /// Elimina una talla
  Future<void> deleteTalla(int id) async {
    try {
      // Verificar si la talla tiene productos asociados
      final productos = await DatosService().getProductos();
      final productosConTalla = productos.where((p) => p.talla == id.toString()).toList();
      
      if (productosConTalla.isNotEmpty) {
        throw Exception('No se puede eliminar esta talla porque tiene productos asociados');
      }

      // Eliminar de base de datos local
      await _localDb.deleteTalla(id);

      // Sincronizar con Supabase si el usuario está autenticado
      if (_authService.isSignedIn) {
        await _sincronizarConSupabase();
      }

      LoggingService.info('Talla eliminada con ID: $id');
    } catch (e) {
      LoggingService.error('Error eliminando talla: $e');
      rethrow;
    }
  }

  /// Carga las tallas por defecto en la base de datos local
  Future<void> _cargarTallasPorDefecto() async {
    try {
      final tallasPorDefecto = Talla.defaultTallas;
      final userId = _authService.currentUserId ?? 'default';
      
      // Obtener tallas existentes para verificar duplicados
      final tallasExistentes = await _localDb.getAllTallas();
      
      for (final talla in tallasPorDefecto) {
        // Verificar si la talla ya existe por nombre (sin importar si es default o no)
        final tallaExistente = tallasExistentes.any((t) => 
          t.nombre.toLowerCase() == talla.nombre.toLowerCase()
        );
        
        if (!tallaExistente) {
          // Crear una nueva talla sin ID para que la base de datos genere uno automáticamente
          final tallaSinId = Talla(
            nombre: talla.nombre,
            descripcion: talla.descripcion,
            orden: talla.orden,
            userId: userId,
            isDefault: talla.isDefault,
          );
          await _localDb.insertTalla(tallaSinId);
        }
      }
      
      LoggingService.info('Tallas por defecto cargadas');
    } catch (e) {
      LoggingService.error('Error cargando tallas por defecto: $e');
    }
  }

  /// Sincroniza las tallas con Supabase
  Future<void> _sincronizarConSupabase() async {
    try {
      if (!_authService.isSignedIn) return;

      final userId = _authService.currentUserId;
      if (userId == null) return;

      // Obtener tallas de Supabase
      final response = await _supabase
          .from('tallas')
          .select()
          .eq('user_id', userId)
          .order('orden', ascending: true);

      final tallasSupabase = (response as List)
          .map((map) => Talla.fromJson(map))
          .toList();

      // Obtener tallas locales
      final tallasLocales = await _localDb.getAllTallas();

      // Sincronizar: insertar/actualizar tallas de Supabase en local
      for (final tallaSupabase in tallasSupabase) {
        final tallaLocal = tallasLocales.firstWhere(
          (t) => t.id == tallaSupabase.id,
          orElse: () => Talla(nombre: '', orden: 0), // Talla dummy
        );

        if (tallaLocal.nombre.isEmpty) {
          // Verificar si ya existe una talla con el mismo nombre antes de insertar
          final tallaConMismoNombre = tallasLocales.any((t) => 
            t.nombre.toLowerCase() == tallaSupabase.nombre.toLowerCase()
          );
          
          if (!tallaConMismoNombre) {
            // Insertar nueva talla sin ID para que la base de datos genere uno automáticamente
            final tallaSinId = Talla(
              nombre: tallaSupabase.nombre,
              descripcion: tallaSupabase.descripcion,
              orden: tallaSupabase.orden,
              userId: tallaSupabase.userId,
              isDefault: tallaSupabase.isDefault,
              fechaCreacion: tallaSupabase.fechaCreacion,
              updatedAt: tallaSupabase.updatedAt,
            );
            await _localDb.insertTalla(tallaSinId);
          }
        } else if (tallaSupabase.updatedAt.isAfter(tallaLocal.updatedAt)) {
          // Actualizar talla existente
          await _localDb.updateTalla(tallaSupabase);
        }
      }

      // Sincronizar: enviar tallas locales a Supabase
      for (final tallaLocal in tallasLocales) {
        if (tallaLocal.userId == userId) {
          final tallaSupabase = tallasSupabase.firstWhere(
            (t) => t.id == tallaLocal.id,
            orElse: () => Talla(nombre: '', orden: 0), // Talla dummy
          );

          if (tallaSupabase.nombre.isEmpty) {
            // Verificar si ya existe una talla con el mismo nombre en Supabase antes de insertar
            final tallaExistenteEnSupabase = tallasSupabase.any((t) => 
              t.nombre.toLowerCase() == tallaLocal.nombre.toLowerCase() && t.userId == userId
            );
            
            if (!tallaExistenteEnSupabase) {
              try {
                // Insertar en Supabase solo si no existe
                await _supabase.from('tallas').insert(tallaLocal.toJson());
                LoggingService.info('Talla "${tallaLocal.nombre}" insertada en Supabase');
              } catch (e) {
                if (e.toString().contains('duplicate key value violates unique constraint')) {
                  LoggingService.warning('Talla "${tallaLocal.nombre}" ya existe en Supabase (constraint violation), omitiendo inserción');
                } else {
                  LoggingService.error('Error insertando talla "${tallaLocal.nombre}" en Supabase: $e');
                  rethrow;
                }
              }
            } else {
              LoggingService.info('Talla "${tallaLocal.nombre}" ya existe en Supabase, omitiendo inserción');
            }
          } else if (tallaLocal.updatedAt.isAfter(tallaSupabase.updatedAt)) {
            // Actualizar en Supabase
            await _supabase
                .from('tallas')
                .update(tallaLocal.toJson())
                .eq('id', tallaLocal.id!);
          }
        }
      }

      LoggingService.info('Tallas sincronizadas con Supabase');
    } catch (e) {
      LoggingService.error('Error sincronizando tallas con Supabase: $e');
    }
  }
}
