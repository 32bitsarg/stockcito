import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stockcito/services/auth/supabase_auth_service.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/ml/ml_training_service.dart';
import 'package:stockcito/services/ml/ml_consent_service.dart';
import 'package:stockcito/services/datos/enhanced_sync_service.dart' as enhanced_sync;
import 'package:stockcito/models/connectivity_enums.dart';
import 'package:stockcito/services/system/lazy_loading_service.dart';
import '../../models/producto.dart';
import '../../models/venta.dart';
import '../../models/cliente.dart';
import '../../models/categoria.dart';
import '../../models/talla.dart';
import '../../screens/calcularprecios_screen/models/costo_directo.dart';
import '../../screens/calcularprecios_screen/models/costo_indirecto.dart';
import 'database/local_database_service.dart';
import 'categoria_service.dart';
import 'talla_service.dart';

/// Servicio centralizado para manejo de datos con sincronización optimizada
class DatosService {
  static final DatosService _instance = DatosService._internal();
  factory DatosService() => _instance;
  DatosService._internal();

  SupabaseAuthService? _authService;
  MLTrainingService? _mlTrainingService;
  MLConsentService? _consentService;
  final CategoriaService _categoriaService = CategoriaService();
  final TallaService _tallaService = TallaService();
  final enhanced_sync.EnhancedSyncService _enhancedSyncService = enhanced_sync.EnhancedSyncService();
  final LazyLoadingService _lazyService = LazyLoadingService();
  
  /// Inicializa el servicio de autenticación (inyección de dependencia)
  void initializeAuthService(SupabaseAuthService authService) {
    _authService = authService;
  }
  
  /// Inicializa el servicio de ML training (inyección de dependencia)
  void initializeMLTrainingService(MLTrainingService mlTrainingService) {
    _mlTrainingService = mlTrainingService;
    _mlTrainingService!.initializeDatosService(this);
  }

  /// Inicializa el servicio de consentimiento ML (inyección de dependencia)
  void initializeMLConsentService(MLConsentService consentService) {
    _consentService = consentService;
  }

  /// Obtiene el servicio de sincronización mejorado
  enhanced_sync.EnhancedSyncService get enhancedSyncService => _enhancedSyncService;

  /// Inicializa datos de prueba si la base de datos está vacía
  Future<void> initializeSampleDataIfEmpty() async {
    try {
      final productos = await getProductos();
      if (productos.isEmpty) {
        LoggingService.info('Base de datos vacía, inicializando datos de prueba...');
        await _localDb.initializeSampleData();
        LoggingService.info('Datos de prueba inicializados correctamente');
      } else {
        LoggingService.info('Base de datos ya contiene datos, saltando inicialización de datos de prueba');
      }
    } catch (e) {
      LoggingService.error('Error inicializando datos de prueba: $e');
    }
  }

  /// Entrena la IA solo si el usuario ha dado consentimiento
  Future<void> _trainMLIfConsented() async {
    if (_mlTrainingService == null || _consentService == null) return;
    
    try {
      final hasConsent = await _consentService!.hasUserGivenConsent();
      final isAutomatic = await _consentService!.wasConsentSetAutomatically();
      
      if (hasConsent) {
        await _mlTrainingService!.trainWithNewData();
        if (isAutomatic) {
          LoggingService.info('🤖 IA entrenada con datos nuevos (consentimiento automático para usuario autenticado)');
        } else {
          LoggingService.info('🤖 IA entrenada con datos nuevos (consentimiento otorgado manualmente)');
        }
      } else {
        LoggingService.info('🤖 IA no entrenada - usuario no ha dado consentimiento');
      }
    } catch (e) {
      LoggingService.error('Error entrenando IA: $e');
    }
  }

  /// Elimina una venta
  Future<void> deleteVenta(int id) async {
    try {
      LoggingService.info('Eliminando venta con ID: $id');
      
      // Eliminar de base de datos local primero
      await _localDb.deleteVenta(id);
      LoggingService.info('Venta eliminada de base de datos local');
      
      // Solo sincronizar con Supabase si el usuario está autenticado (no anónimo)
      if (_isSignedIn && !_isAnonymous) {
        try {
          // Para usuarios autenticados, agregar a cola de sincronización
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.delete,
          table: 'ventas',
          data: {'id': id},
        ));
          LoggingService.info('Venta agregada a cola de sincronización para Supabase');
        } catch (e) {
          LoggingService.warning('Error agregando venta a cola de sincronización: $e');
          // No re-lanzar error, la venta ya se eliminó localmente
        }
      } else {
        LoggingService.info('Usuario anónimo - solo eliminación local');
      }
      
    } catch (e) {
      LoggingService.error('Error eliminando venta: $e');
      rethrow;
    }
  }
  
  /// Helper para verificar si el usuario está autenticado
  bool get _isSignedIn => _authService?.isSignedIn ?? false;
  
  /// Helper para verificar si el usuario es anónimo
  bool get _isAnonymous => _authService?.isAnonymous ?? false;
  
  /// Helper para obtener el ID del usuario actual
  String? get _currentUserId => _authService?.currentUserId;
  final LocalDatabaseService _localDb = LocalDatabaseService();
  
  // Sistema de sincronización viejo eliminado - ahora usamos EnhancedSyncService
  
  // Cache de datos para optimización
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // Rate limiting (mantenido para sincronización desde Supabase)
  static const Duration _rateLimitDelay = Duration(milliseconds: 500);
  DateTime? _lastApiCall;
  int _apiCallCount = 0;
  static const int _maxApiCallsPerMinute = 30;
  
  // Seguridad y validación
  static const int _maxDataSize = 1024 * 1024; // 1MB máximo por operación
  static const int _maxItemsPerPage = 50;
  static const Duration _sessionTimeout = Duration(hours: 24);
  
  // Cache de seguridad por usuario
  final Map<String, DateTime> _userCacheTimestamps = {};
  final Map<String, String> _userSessions = {}; // userId -> sessionId

  /// Inicializa el servicio de datos
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando DatosService...');
      
      // Cargar datos del usuario si está autenticado
      if (_isSignedIn && !_isAnonymous) {
        await _loadUserData();
      }
      
      // Procesar cola de sincronización pendiente (ahora manejado por EnhancedSyncService)
      await _enhancedSyncService.forceSync();
      
      LoggingService.info('DatosService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando DatosService: $e');
    }
  }

  // ==================== PRODUCTOS ====================

  /// Obtiene productos con lazy loading optimizado
  Future<List<Producto>> getProductosLazy({
    int page = 0, 
    int limit = _maxItemsPerPage,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      // Usar lazy loading service
      return await _lazyService.loadData<Producto>(
        entityKey: 'productos_$userId',
        page: page,
        pageSize: limit,
        dataLoader: (page, pageSize) => _loadProductosFromSource(page, pageSize, filters),
        fromJson: (json) => Producto.fromMap(json),
        toJson: (producto) => producto.toMap(),
        filters: filters,
      );
    } catch (e) {
      LoggingService.error('Error en getProductosLazy: $e');
      return [];
    }
  }

  /// Carga productos desde la fuente de datos (local + sync)
  Future<List<Producto>> _loadProductosFromSource(int page, int pageSize, Map<String, dynamic>? filters) async {
    try {
      final userId = _currentUserId!;
      
      // Cargar desde local con paginación
      final productos = await _localDb.getAllProductos(userId: userId);
      
      // Aplicar filtros si existen
      List<Producto> filteredProductos = productos;
      if (filters != null) {
        filteredProductos = _applyProductFilters(productos, filters);
      }
      
      // Paginación
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, filteredProductos.length);
      
      if (startIndex >= filteredProductos.length) {
        return [];
      }
      
      final paginatedProductos = filteredProductos.sublist(startIndex, endIndex);
      
      // Si está autenticado, sincronizar en background
      if (_isSignedIn && !_isAnonymous) {
        _syncProductosFromSupabase(); // Sin await para no bloquear
      }
      
      return paginatedProductos;
    } catch (e) {
      LoggingService.error('Error cargando productos desde fuente: $e');
      return [];
    }
  }

  /// Aplica filtros a la lista de productos
  List<Producto> _applyProductFilters(List<Producto> productos, Map<String, dynamic> filters) {
    var filtered = productos;
    
    if (filters.containsKey('categoria') && filters['categoria'] != 'Todas') {
      filtered = filtered.where((p) => p.categoria == filters['categoria']).toList();
    }
    
    if (filters.containsKey('talla') && filters['talla'] != 'Todas') {
      filtered = filtered.where((p) => p.talla == filters['talla']).toList();
    }
    
    if (filters.containsKey('busqueda') && filters['busqueda'].isNotEmpty) {
      final busqueda = filters['busqueda'].toLowerCase();
      filtered = filtered.where((p) => 
        p.nombre.toLowerCase().contains(busqueda) ||
        p.categoria.toLowerCase().contains(busqueda) ||
        p.talla.toLowerCase().contains(busqueda)
      ).toList();
    }
    
    if (filters.containsKey('stockBajo') && filters['stockBajo'] == true) {
      filtered = filtered.where((p) => p.stock < 10).toList();
    }
    
    return filtered;
  }

  /// Obtiene todos los productos (local + sincronizado) - Método legacy
  Future<List<Producto>> getProductos({int page = 0, int limit = _maxItemsPerPage}) async {
    try {
      final userId = _currentUserId;
      LoggingService.info('📦 [DATOS] getProductos - userId: $userId, isSignedIn: $_isSignedIn, isAnonymous: $_isAnonymous');
      
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando obtener productos');
        return [];
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'get_productos')) {
        LoggingService.warning('⚠️ [DATOS] Acceso denegado para get_productos');
        return [];
      }

      // Crear sesión si no existe
      if (!_userSessions.containsKey(userId)) {
        _createUserSession(userId);
        LoggingService.info('🆕 [DATOS] Sesión creada para usuario: $userId');
      }

      final cacheKey = 'productos_${userId}_${page}_$limit';
      
      // Verificar cache primero
      if (_isCacheValid(cacheKey)) {
        final cachedProductos = List<Producto>.from(_cache[cacheKey]);
        LoggingService.info('💾 [DATOS] Productos obtenidos desde cache: ${cachedProductos.length} productos');
        return cachedProductos;
      }

      // Cargar desde local con paginación
      LoggingService.info('🔍 [DATOS] Cargando productos desde base de datos local para userId: $userId');
      final productos = await _localDb.getAllProductos(userId: userId);
      LoggingService.info('📊 [DATOS] Productos encontrados en local: ${productos.length} productos');
      
      final startIndex = page * limit;
      final endIndex = (startIndex + limit).clamp(0, productos.length);
      final paginatedProductos = productos.sublist(startIndex, endIndex);
      LoggingService.info('📄 [DATOS] Productos paginados: ${paginatedProductos.length} productos (página $page, límite $limit)');
      
      // Si está autenticado, sincronizar con Supabase
      if (_isSignedIn && !_isAnonymous) {
        LoggingService.info('🔄 [DATOS] Usuario autenticado, sincronizando con Supabase...');
        await _syncProductosFromSupabase();
        // Recargar después de sincronizar
        final productosActualizados = await _localDb.getAllProductos(userId: userId);
        final paginatedActualizados = productosActualizados.sublist(startIndex, endIndex);
        LoggingService.info('✅ [DATOS] Productos actualizados después de sincronización: ${paginatedActualizados.length} productos');
        _updateCache(cacheKey, paginatedActualizados);
        return paginatedActualizados;
      } else {
        LoggingService.info('👤 [DATOS] Usuario anónimo, solo datos locales');
      }

      _updateCache(cacheKey, paginatedProductos);
      return paginatedProductos;
    } catch (e) {
      LoggingService.error('❌ [DATOS] Error obteniendo productos: $e');
      return [];
    }
  }

  /// Guarda un producto (local + Supabase si está autenticado)
  Future<bool> saveProducto(Producto producto) async {
    try {
      LoggingService.info('💾 [DATOS] Iniciando guardado de producto: ${producto.nombre}');
      
      final userId = _currentUserId;
      LoggingService.info('👤 [DATOS] Usuario actual: $userId (isSignedIn: $_isSignedIn, isAnonymous: $_isAnonymous)');
      
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando guardar producto');
        return false;
      }

      // Validar acceso del usuario
      LoggingService.info('🔐 [DATOS] Validando acceso del usuario...');
      if (!await _validateUserAccess(userId, 'save_producto')) {
        LoggingService.warning('⚠️ [DATOS] Acceso denegado para usuario $userId');
        return false;
      }

      // Validar tamaño de datos
      LoggingService.info('📏 [DATOS] Validando tamaño de datos...');
      final productoMap = producto.toMap();
      if (!_validateDataSize(productoMap)) {
        LoggingService.warning('⚠️ [DATOS] Producto excede el tamaño máximo permitido');
        return false;
      }

      // Sanitizar datos
      LoggingService.info('🧹 [DATOS] Sanitizando datos...');
      final sanitizedData = _sanitizeData(productoMap);
      final sanitizedProducto = Producto.fromMap(sanitizedData);

      // Guardar en local primero
      LoggingService.info('💾 [DATOS] Guardando en base de datos local para userId: $userId...');
      final insertId = await _localDb.insertProducto(sanitizedProducto, userId: userId);
      LoggingService.info('✅ [DATOS] Producto insertado en local con ID: $insertId');
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        LoggingService.info('🔄 [DATOS] Usuario autenticado, agregando a cola de sincronización...');
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'productos',
          data: _prepareProductoForSupabase(sanitizedProducto),
        ));
      } else {
        LoggingService.info('👤 [DATOS] Usuario anónimo, solo guardado local');
      }

      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'productos');
      LoggingService.info('🗑️ [DATOS] Cache invalidado para usuario: $userId');
      
      // Entrenar IA con el nuevo producto (solo si hay consentimiento)
      await _trainMLIfConsented();
      
      LoggingService.info('✅ [DATOS] Producto guardado exitosamente para usuario $userId: ${sanitizedProducto.nombre}');
      return true;
    } catch (e, stackTrace) {
      LoggingService.error('❌ [DATOS] Error guardando producto: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Actualiza un producto (local + Supabase si está autenticado)
  Future<bool> updateProducto(Producto producto) async {
    try {
      // Actualizar en local
      await _localDb.updateProducto(producto);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'productos',
          data: _prepareProductoForSupabase(producto),
        ));
      }

      // Invalidar cache
      _invalidateCache('productos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Producto actualizado: ${producto.nombre}');
      return true;
    } catch (e) {
      LoggingService.error('Error actualizando producto: $e');
      return false;
    }
  }

  /// Actualiza el stock de un producto (local + Supabase si está autenticado)
  Future<bool> updateStock(int productoId, int nuevaCantidad) async {
    try {
      LoggingService.info('Actualizando stock del producto $productoId a $nuevaCantidad');
      
      // Actualizar en local
      await _localDb.updateProductoStock(productoId, nuevaCantidad);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'productos',
          data: {
            'id': productoId,
            'stock': nuevaCantidad,
          },
        ));
      }

      // Invalidar cache
      _invalidateCache('productos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Stock actualizado: Producto $productoId = $nuevaCantidad');
      return true;
    } catch (e) {
      LoggingService.error('Error actualizando stock: $e');
      return false;
    }
  }

  /// Reduce el stock de un producto al venderlo
  Future<bool> reduceStock(int productoId, int cantidadVendida) async {
    try {
      LoggingService.info('Reduciendo stock: Producto $productoId, cantidad vendida: $cantidadVendida');
      
      // Obtener producto actual
      final productos = await getAllProductos();
      final producto = productos.firstWhere((p) => p.id == productoId);
      
      if (producto.stock < cantidadVendida) {
        LoggingService.warning('Stock insuficiente: ${producto.stock} < $cantidadVendida');
        return false;
      }
      
      // Calcular nuevo stock
      final nuevoStock = producto.stock - cantidadVendida;
      
      // Actualizar stock
      return await updateStock(productoId, nuevoStock);
    } catch (e) {
      LoggingService.error('Error reduciendo stock: $e');
      return false;
    }
  }

  /// Elimina un producto (local + Supabase si está autenticado)
  Future<bool> deleteProducto(int id) async {
    try {
      // Eliminar de local
      await _localDb.deleteProducto(id);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.delete,
          table: 'productos',
          data: {'id': id},
        ));
      }

      // Invalidar cache
      _invalidateCache('productos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Producto eliminado: $id');
      return true;
    } catch (e) {
      LoggingService.error('Error eliminando producto: $e');
      return false;
    }
  }

  // ==================== COSTOS DIRECTOS ====================

  /// Obtiene todos los costos directos
  Future<List<CostoDirecto>> getCostosDirectos() async {
    try {
      final userId = _currentUserId;
      LoggingService.info('🔨 [DATOS] getCostosDirectos - userId: $userId');
      
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando obtener costos directos');
        return [];
      }

      // Obtener de local
      final costos = await _localDb.getAllCostosDirectos(userId: userId);
      LoggingService.info('✅ [DATOS] ${costos.length} costos directos obtenidos de local');
      
      return costos;
    } catch (e) {
      LoggingService.error('❌ [DATOS] Error obteniendo costos directos: $e');
      return [];
    }
  }

  /// Guarda un costo directo (local + Supabase si está autenticado)
  Future<bool> saveCostoDirecto(CostoDirecto costo) async {
    try {
      LoggingService.info('💾 [DATOS] Iniciando guardado de costo directo: ${costo.nombre}');
      
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando guardar costo directo');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'save_costo_directo')) {
        LoggingService.warning('⚠️ [DATOS] Acceso denegado para usuario $userId');
        return false;
      }

      // Validar tamaño de datos
      final costoMap = costo.toMap();
      if (!_validateDataSize(costoMap)) {
        LoggingService.warning('⚠️ [DATOS] Costo directo excede el tamaño máximo permitido');
        return false;
      }

      // Sanitizar datos
      final sanitizedData = _sanitizeData(costoMap);
      final sanitizedCosto = CostoDirecto.fromMap(sanitizedData);

      // Guardar en local primero
      LoggingService.info('💾 [DATOS] Guardando costo directo en local para userId: $userId...');
      final insertId = await _localDb.insertCostoDirecto(sanitizedCosto, userId: userId);
      LoggingService.info('✅ [DATOS] Costo directo insertado en local con ID: $insertId');
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        LoggingService.info('🔄 [DATOS] Usuario autenticado, agregando a cola de sincronización...');
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'costos_directos',
          data: _prepareCostoDirectoForSupabase(sanitizedCosto),
        ));
      } else {
        LoggingService.info('👤 [DATOS] Usuario anónimo, solo guardado local');
      }

      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'costos_directos');
      LoggingService.info('🗑️ [DATOS] Cache invalidado para usuario: $userId');
      
      LoggingService.info('✅ [DATOS] Costo directo guardado exitosamente para usuario $userId: ${sanitizedCosto.nombre}');
      return true;
    } catch (e, stackTrace) {
      LoggingService.error('❌ [DATOS] Error guardando costo directo: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Actualiza un costo directo (local + Supabase si está autenticado)
  Future<bool> updateCostoDirecto(CostoDirecto costo) async {
    try {
      // Actualizar en local
      await _localDb.updateCostoDirecto(costo);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'costos_directos',
          data: _prepareCostoDirectoForSupabase(costo),
        ));
      }

      // Invalidar cache
      _invalidateCache('costos_directos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Costo directo actualizado: ${costo.nombre}');
      return true;
    } catch (e) {
      LoggingService.error('Error actualizando costo directo: $e');
      return false;
    }
  }

  /// Elimina un costo directo (local + Supabase si está autenticado)
  Future<bool> deleteCostoDirecto(int id) async {
    try {
      // Eliminar de local
      await _localDb.deleteCostoDirecto(id);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.delete,
          table: 'costos_directos',
          data: {'id': id},
        ));
      }

      // Invalidar cache
      _invalidateCache('costos_directos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Costo directo eliminado: $id');
      return true;
    } catch (e) {
      LoggingService.error('Error eliminando costo directo: $e');
      return false;
    }
  }

  // ==================== COSTOS INDIRECTOS ====================

  /// Obtiene todos los costos indirectos
  Future<List<CostoIndirecto>> getCostosIndirectos() async {
    try {
      final userId = _currentUserId;
      LoggingService.info('🏠 [DATOS] getCostosIndirectos - userId: $userId');
      
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando obtener costos indirectos');
        return [];
      }

      // Obtener de local
      final costos = await _localDb.getAllCostosIndirectos(userId: userId);
      LoggingService.info('✅ [DATOS] ${costos.length} costos indirectos obtenidos de local');
      
      return costos;
    } catch (e) {
      LoggingService.error('❌ [DATOS] Error obteniendo costos indirectos: $e');
      return [];
    }
  }

  /// Guarda un costo indirecto (local + Supabase si está autenticado)
  Future<bool> saveCostoIndirecto(CostoIndirecto costo) async {
    try {
      LoggingService.info('💾 [DATOS] Iniciando guardado de costo indirecto: ${costo.nombre}');
      
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('⚠️ [DATOS] Usuario no autenticado intentando guardar costo indirecto');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'save_costo_indirecto')) {
        LoggingService.warning('⚠️ [DATOS] Acceso denegado para usuario $userId');
        return false;
      }

      // Validar tamaño de datos
      final costoMap = costo.toMap();
      if (!_validateDataSize(costoMap)) {
        LoggingService.warning('⚠️ [DATOS] Costo indirecto excede el tamaño máximo permitido');
        return false;
      }

      // Sanitizar datos
      final sanitizedData = _sanitizeData(costoMap);
      final sanitizedCosto = CostoIndirecto.fromMap(sanitizedData);

      // Guardar en local primero
      LoggingService.info('💾 [DATOS] Guardando costo indirecto en local para userId: $userId...');
      final insertId = await _localDb.insertCostoIndirecto(sanitizedCosto, userId: userId);
      LoggingService.info('✅ [DATOS] Costo indirecto insertado en local con ID: $insertId');
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        LoggingService.info('🔄 [DATOS] Usuario autenticado, agregando a cola de sincronización...');
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'costos_indirectos',
          data: _prepareCostoIndirectoForSupabase(sanitizedCosto),
        ));
      } else {
        LoggingService.info('👤 [DATOS] Usuario anónimo, solo guardado local');
      }

      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'costos_indirectos');
      LoggingService.info('🗑️ [DATOS] Cache invalidado para usuario: $userId');
      
      LoggingService.info('✅ [DATOS] Costo indirecto guardado exitosamente para usuario $userId: ${sanitizedCosto.nombre}');
      return true;
    } catch (e, stackTrace) {
      LoggingService.error('❌ [DATOS] Error guardando costo indirecto: $e', stackTrace: stackTrace);
      return false;
    }
  }

  /// Actualiza un costo indirecto (local + Supabase si está autenticado)
  Future<bool> updateCostoIndirecto(CostoIndirecto costo) async {
    try {
      // Actualizar en local
      await _localDb.updateCostoIndirecto(costo);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'costos_indirectos',
          data: _prepareCostoIndirectoForSupabase(costo),
        ));
      }

      // Invalidar cache
      _invalidateCache('costos_indirectos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Costo indirecto actualizado: ${costo.nombre}');
      return true;
    } catch (e) {
      LoggingService.error('Error actualizando costo indirecto: $e');
      return false;
    }
  }

  /// Elimina un costo indirecto (local + Supabase si está autenticado)
  Future<bool> deleteCostoIndirecto(int id) async {
    try {
      // Eliminar de local
      await _localDb.deleteCostoIndirecto(id);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.delete,
          table: 'costos_indirectos',
          data: {'id': id},
        ));
      }

      // Invalidar cache
      _invalidateCache('costos_indirectos_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Costo indirecto eliminado: $id');
      return true;
    } catch (e) {
      LoggingService.error('Error eliminando costo indirecto: $e');
      return false;
    }
  }

  // ==================== VENTAS ====================

  /// Obtiene ventas con lazy loading optimizado
  Future<List<Venta>> getVentasLazy({
    int page = 0, 
    int limit = _maxItemsPerPage,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return [];

      // Usar lazy loading service
      return await _lazyService.loadData<Venta>(
        entityKey: 'ventas_$userId',
        page: page,
        pageSize: limit,
        dataLoader: (page, pageSize) => _loadVentasFromSource(page, pageSize, filters),
        fromJson: (json) => Venta.fromMap(json),
        toJson: (venta) => venta.toMap(),
        filters: filters,
      );
    } catch (e) {
      LoggingService.error('Error en getVentasLazy: $e');
      return [];
    }
  }

  /// Carga ventas desde la fuente de datos (local + sync)
  Future<List<Venta>> _loadVentasFromSource(int page, int pageSize, Map<String, dynamic>? filters) async {
    try {
      // Cargar desde local con paginación
      final ventas = await _localDb.getAllVentas();
      
      // Aplicar filtros si existen
      List<Venta> filteredVentas = ventas;
      if (filters != null) {
        filteredVentas = _applyVentaFilters(ventas, filters);
      }
      
      // Paginación
      final startIndex = page * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, filteredVentas.length);
      
      if (startIndex >= filteredVentas.length) {
        return [];
      }
      
      final paginatedVentas = filteredVentas.sublist(startIndex, endIndex);
      
      // Si está autenticado, sincronizar en background
      if (_isSignedIn && !_isAnonymous) {
        _syncVentasFromSupabase(); // Sin await para no bloquear
      }
      
      return paginatedVentas;
    } catch (e) {
      LoggingService.error('Error cargando ventas desde fuente: $e');
      return [];
    }
  }

  /// Aplica filtros a la lista de ventas
  List<Venta> _applyVentaFilters(List<Venta> ventas, Map<String, dynamic> filters) {
    var filtered = ventas;
    
    if (filters.containsKey('estado') && filters['estado'] != 'Todas') {
      filtered = filtered.where((v) => v.estado == filters['estado']).toList();
    }
    
    if (filters.containsKey('cliente') && filters['cliente'] != 'Todos') {
      filtered = filtered.where((v) => v.cliente == filters['cliente']).toList();
    }
    
    if (filters.containsKey('metodoPago') && filters['metodoPago'] != 'Todos') {
      filtered = filtered.where((v) => v.metodoPago == filters['metodoPago']).toList();
    }
    
    if (filters.containsKey('fechaDesde') && filters['fechaDesde'] != null) {
      final fechaDesde = filters['fechaDesde'] as DateTime;
      filtered = filtered.where((v) => v.fecha.isAfter(fechaDesde) || v.fecha.isAtSameMomentAs(fechaDesde)).toList();
    }
    
    if (filters.containsKey('fechaHasta') && filters['fechaHasta'] != null) {
      final fechaHasta = filters['fechaHasta'] as DateTime;
      filtered = filtered.where((v) => v.fecha.isBefore(fechaHasta) || v.fecha.isAtSameMomentAs(fechaHasta)).toList();
    }
    
    return filtered;
  }

  /// Obtiene todas las ventas (local + sincronizado) - Método legacy
  Future<List<Venta>> getVentas() async {
    try {
      final cacheKey = 'ventas_${_currentUserId ?? 'anon'}';
      if (_isCacheValid(cacheKey)) {
        return List<Venta>.from(_cache[cacheKey]);
      }

      final ventas = await _localDb.getAllVentas();
      
      if (_isSignedIn && !_isAnonymous) {
        await _syncVentasFromSupabase();
        await _syncDetallesVentaFromSupabase();
        final ventasActualizadas = await _localDb.getAllVentas();
        _updateCache(cacheKey, ventasActualizadas);
        return ventasActualizadas;
      }

      _updateCache(cacheKey, ventas);
      return ventas;
    } catch (e) {
      LoggingService.error('Error obteniendo ventas: $e');
      return [];
    }
  }

  /// Guarda una venta (local + Supabase si está autenticado)
  Future<bool> saveVenta(Venta venta) async {
    try {
      await _localDb.insertVenta(venta);
      
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'ventas',
          data: _prepareVentaForSupabase(venta),
        ));
        
        // Sincronizar también los detalles de venta
        for (final item in venta.items) {
          _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
            type: SyncType.create,
            table: 'detalles_venta',
            data: _prepareDetalleVentaForSupabase(item),
          ));
        }
      }

      _invalidateCache('ventas_${_currentUserId ?? 'anon'}');
      
      // Entrenar IA con la nueva venta (solo si hay consentimiento)
      await _trainMLIfConsented();
      
      LoggingService.info('Venta guardada: ${venta.id}');
      return true;
    } catch (e) {
      LoggingService.error('Error guardando venta: $e');
      return false;
    }
  }

  /// Actualiza una venta existente
  Future<Venta> updateVenta(Venta venta) async {
    try {
      LoggingService.info('Actualizando venta: ${venta.id}');
      
      // Actualizar en base de datos local
      await _localDb.updateVenta(venta);
      
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'ventas',
          data: _prepareVentaForSupabase(venta),
        ));
        
        // Sincronizar también los detalles de venta actualizados
        for (final item in venta.items) {
          _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
            type: SyncType.update,
            table: 'detalles_venta',
            data: _prepareDetalleVentaForSupabase(item),
          ));
        }
      }

      _invalidateCache('ventas_${_currentUserId ?? 'anon'}');
      
      LoggingService.info('Venta actualizada: ${venta.id}');
      return venta;
    } catch (e) {
      LoggingService.error('Error actualizando venta: $e');
      rethrow;
    }
  }

  // ==================== CLIENTES ====================

  /// Obtiene todos los clientes (local + sincronizado)
  Future<List<Cliente>> getClientes() async {
    try {
      final cacheKey = 'clientes_${_currentUserId ?? 'anon'}';
      if (_isCacheValid(cacheKey)) {
        return List<Cliente>.from(_cache[cacheKey]);
      }

      final clientes = await _localDb.getAllClientes();
      
      if (_isSignedIn && !_isAnonymous) {
        await _syncClientesFromSupabase();
        final clientesActualizados = await _localDb.getAllClientes();
        _updateCache(cacheKey, clientesActualizados);
        return clientesActualizados;
      }

      _updateCache(cacheKey, clientes);
      return clientes;
    } catch (e) {
      LoggingService.error('Error obteniendo clientes: $e');
      return [];
    }
  }

  /// Guarda un cliente (local + Supabase si está autenticado)
  Future<bool> saveCliente(Cliente cliente) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando guardar cliente');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'save_cliente')) {
        return false;
      }

      await _localDb.insertCliente(cliente);
      
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'clientes',
          data: _prepareClienteForSupabase(cliente),
        ));
      }

      _invalidateUserCache(userId, 'clientes');
      
      // Entrenar IA con el nuevo cliente (solo si hay consentimiento)
      await _trainMLIfConsented();
      
      LoggingService.info('Cliente guardado exitosamente para usuario $userId: ${cliente.nombre}');
      return true;
    } catch (e) {
      LoggingService.error('Error guardando cliente: $e');
      return false;
    }
  }

  /// Actualiza un cliente (local + Supabase si está autenticado)
  Future<bool> updateCliente(Cliente cliente) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando actualizar cliente');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'update_cliente')) {
        return false;
      }

      // Actualizar en local primero
      await _localDb.updateCliente(cliente);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        final data = _prepareClienteForSupabase(cliente);
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.update,
          table: 'clientes',
          data: data,
        ));
      }
      
      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'clientes');
      
      LoggingService.info('Cliente actualizado exitosamente para usuario $userId: ${cliente.nombre}');
      return true;
    } catch (e) {
      LoggingService.error('Error actualizando cliente: $e');
      return false;
    }
  }

  /// Elimina un cliente (local + Supabase si está autenticado)
  Future<bool> deleteCliente(int clienteId) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando eliminar cliente');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'delete_cliente')) {
        return false;
      }

      // Eliminar en local primero
      await _localDb.deleteCliente(clienteId);
      
      // Si está autenticado, agregar a cola de sincronización
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.delete,
          table: 'clientes',
          data: {'id': clienteId},
        ));
      }
      
      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'clientes');
      
      LoggingService.info('Cliente eliminado exitosamente para usuario $userId: ID $clienteId');
      return true;
    } catch (e) {
      LoggingService.error('Error eliminando cliente: $e');
      return false;
    }
  }

  // ==================== RATE LIMITING Y BATCHING ====================

  /// Verifica y aplica rate limiting
  Future<void> _applyRateLimit() async {
    final now = DateTime.now();
    
    // Resetear contador si ha pasado un minuto
    if (_lastApiCall != null && now.difference(_lastApiCall!).inMinutes >= 1) {
      _apiCallCount = 0;
    }
    
    // Si hemos excedido el límite, esperar
    if (_apiCallCount >= _maxApiCallsPerMinute) {
      final waitTime = 60 - (now.difference(_lastApiCall!).inSeconds);
      if (waitTime > 0) {
        LoggingService.info('Rate limit alcanzado. Esperando ${waitTime}s...');
        await Future.delayed(Duration(seconds: waitTime));
        _apiCallCount = 0;
      }
    }
    
    // Aplicar delay mínimo entre llamadas
    if (_lastApiCall != null) {
      final timeSinceLastCall = now.difference(_lastApiCall!);
      if (timeSinceLastCall < _rateLimitDelay) {
        await Future.delayed(_rateLimitDelay - timeSinceLastCall);
      }
    }
    
    _lastApiCall = DateTime.now();
    _apiCallCount++;
  }

  /// Procesa operaciones en lotes para optimizar llamadas a Supabase
  // Métodos de procesamiento batch eliminados - ahora usamos EnhancedSyncService

  // ==================== SINCRONIZACIÓN ====================

  /// Sincroniza productos desde Supabase
  Future<void> _syncProductosFromSupabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _applyRateLimit();

      // Obtener timestamp de última sincronización
      final lastSync = await _getLastSyncTime('productos');
      
      // Consulta optimizada: solo productos modificados después de la última sincronización
      final response = await Supabase.instance.client
          .from('productos')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: true);

      if (response.isNotEmpty) {
        // Obtener IDs existentes en lote para evitar consultas individuales
        final existingIds = await _getExistingProductIds(response.map((item) => item['id']).toList());
        
        for (final item in response) {
          if (!existingIds.contains(item['id'])) {
            final producto = Producto.fromMap(item);
            await _localDb.insertProducto(producto);
          }
        }
        
        // Actualizar timestamp de sincronización
        await _updateLastSyncTime('productos');
        
        LoggingService.info('${response.length} productos sincronizados desde Supabase');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando productos desde Supabase: $e');
    }
  }

  /// Sincroniza ventas desde Supabase
  Future<void> _syncVentasFromSupabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _applyRateLimit();

      final lastSync = await _getLastSyncTime('ventas');
      
      final response = await Supabase.instance.client
          .from('ventas')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: true);

      if (response.isNotEmpty) {
        final existingIds = await _getExistingVentaIds(response.map((item) => item['id']).toList());
        
        for (final item in response) {
          if (!existingIds.contains(item['id'])) {
            final venta = Venta.fromMap(item);
            await _localDb.insertVenta(venta);
          }
        }
        
        await _updateLastSyncTime('ventas');
        LoggingService.info('${response.length} ventas sincronizadas desde Supabase');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando ventas desde Supabase: $e');
    }
  }

  /// Sincroniza detalles de venta desde Supabase
  Future<void> _syncDetallesVentaFromSupabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _applyRateLimit();

      final lastSync = await _getLastSyncTime('detalles_venta');
      
      final response = await Supabase.instance.client
          .from('detalles_venta')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: true);

      if (response.isNotEmpty) {
        for (final item in response) {
          final detalle = VentaItem.fromMap(item);
          await _localDb.insertDetalleVenta(detalle);
        }
        
        await _updateLastSyncTime('detalles_venta');
        LoggingService.info('${response.length} detalles de venta sincronizados desde Supabase');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando detalles de venta desde Supabase: $e');
    }
  }

  /// Sincroniza clientes desde Supabase
  Future<void> _syncClientesFromSupabase() async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      await _applyRateLimit();

      final lastSync = await _getLastSyncTime('clientes');
      
      final response = await Supabase.instance.client
          .from('clientes')
          .select()
          .eq('user_id', userId)
          .gt('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: true);

      if (response.isNotEmpty) {
        final existingIds = await _getExistingClienteIds(response.map((item) => item['id']).toList());
        
        for (final item in response) {
          if (!existingIds.contains(item['id'])) {
            final cliente = Cliente.fromMap(item);
            await _localDb.insertCliente(cliente);
          }
        }
        
        await _updateLastSyncTime('clientes');
        LoggingService.info('${response.length} clientes sincronizados desde Supabase');
      }
    } catch (e) {
      LoggingService.error('Error sincronizando clientes desde Supabase: $e');
    }
  }

  /// Carga todos los datos del usuario
  Future<void> _loadUserData() async {
    try {
      await Future.wait([
        _syncProductosFromSupabase(),
        _syncVentasFromSupabase(),
        _syncClientesFromSupabase(),
      ]);
    } catch (e) {
      LoggingService.error('Error cargando datos del usuario: $e');
    }
  }

  // ==================== COLA DE SINCRONIZACIÓN ====================

  // Métodos del sistema viejo eliminados - ahora usamos EnhancedSyncService


  // ==================== PREPARACIÓN DE DATOS ====================

  /// Prepara un producto para Supabase
  Map<String, dynamic> _prepareProductoForSupabase(Producto producto) {
    final data = producto.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = producto.fechaCreacion.toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  /// Prepara un costo directo para Supabase
  Map<String, dynamic> _prepareCostoDirectoForSupabase(CostoDirecto costo) {
    final data = costo.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = costo.fechaCreacion.toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  /// Prepara un costo indirecto para Supabase
  Map<String, dynamic> _prepareCostoIndirectoForSupabase(CostoIndirecto costo) {
    final data = costo.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = costo.fechaCreacion.toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  /// Prepara una venta para Supabase
  Map<String, dynamic> _prepareVentaForSupabase(Venta venta) {
    final data = venta.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = venta.fecha.toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  /// Prepara un detalle de venta para Supabase
  Map<String, dynamic> _prepareDetalleVentaForSupabase(VentaItem detalle) {
    final data = detalle.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  /// Prepara un cliente para Supabase
  Map<String, dynamic> _prepareClienteForSupabase(Cliente cliente) {
    final data = cliente.toMap();
    data['user_id'] = _currentUserId;
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    return data;
  }

  // ==================== CACHE ====================

  /// Verifica si el cache es válido
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Actualiza el cache
  void _updateCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Invalida el cache
  void _invalidateCache(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Limpia todo el cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // ==================== SEGURIDAD Y VALIDACIÓN ====================

  /// Valida que el usuario tenga permisos para acceder a los datos
  Future<bool> _validateUserAccess(String userId, String operation) async {
    try {
      // Verificar que el usuario esté autenticado (incluyendo anónimos)
      if (!_isSignedIn) {
        LoggingService.warning('Usuario no autenticado intentando $operation');
        return false;
      }

      // Verificar que el userId coincida con el usuario actual
      final currentUserId = _currentUserId;
      if (currentUserId != userId) {
        LoggingService.warning('Usuario $currentUserId intentando acceder a datos de $userId');
        return false;
      }

      // Para usuarios anónimos, no verificar sesión (siempre válida)
      if (!_isAnonymous) {
        // Verificar sesión activa solo para usuarios no anónimos
        if (!_isSessionValid(userId)) {
          LoggingService.warning('Sesión expirada para usuario $userId');
          return false;
        }
      }

      return true;
    } catch (e) {
      LoggingService.error('Error validando acceso de usuario: $e');
      return false;
    }
  }

  /// Valida el tamaño de los datos antes de enviar
  bool _validateDataSize(Map<String, dynamic> data) {
    try {
      final jsonString = data.toString();
      final sizeInBytes = jsonString.length * 2; // Aproximación UTF-16
      
      if (sizeInBytes > _maxDataSize) {
        LoggingService.warning('Datos exceden el tamaño máximo: ${sizeInBytes}B > ${_maxDataSize}B');
        return false;
      }
      
      return true;
    } catch (e) {
      LoggingService.error('Error validando tamaño de datos: $e');
      return false;
    }
  }

  /// Sanitiza datos antes de guardar
  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in data.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Sanitizar claves
      final cleanKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      
      // Sanitizar valores
      if (value is String) {
        sanitized[cleanKey] = value.trim();
      } else if (value is Map<String, dynamic>) {
        sanitized[cleanKey] = _sanitizeData(value);
      } else {
        sanitized[cleanKey] = value;
      }
    }
    
    return sanitized;
  }

  /// Verifica si la sesión del usuario es válida
  bool _isSessionValid(String userId) {
    final sessionTime = _userCacheTimestamps[userId];
    if (sessionTime == null) return false;
    
    return DateTime.now().difference(sessionTime) < _sessionTimeout;
  }

  /// Crea una sesión segura para el usuario
  void _createUserSession(String userId) {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _userSessions[userId] = sessionId;
    _userCacheTimestamps[userId] = DateTime.now();
    
    // Configurar el userId en LocalDatabaseService
    _localDb.setCurrentUserId(userId);
    
    LoggingService.info('Sesión creada para usuario $userId');
  }


  /// Invalida el cache específico del usuario
  void _invalidateUserCache(String userId, String dataType) {
    // Invalidar cache general
    _invalidateCache('${dataType}_$userId');
    
    // Invalidar cache paginado
    for (int page = 0; page < 10; page++) {
      for (int limit = 10; limit <= 100; limit += 10) {
        _invalidateCache('${dataType}_${userId}_${page}_$limit');
      }
    }
    
    LoggingService.info('Cache invalidado para usuario $userId, tipo: $dataType');
  }


  // ==================== MÉTODOS AUXILIARES DE OPTIMIZACIÓN ====================

  /// Obtiene el timestamp de la última sincronización
  Future<DateTime> _getLastSyncTime(String table) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString('last_sync_$table');
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      // Si no hay timestamp, usar fecha muy antigua para sincronizar todo
      return DateTime(2020, 1, 1);
    } catch (e) {
      LoggingService.error('Error obteniendo timestamp de sincronización: $e');
      return DateTime(2020, 1, 1);
    }
  }

  /// Actualiza el timestamp de la última sincronización
  Future<void> _updateLastSyncTime(String table) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_$table', DateTime.now().toIso8601String());
    } catch (e) {
      LoggingService.error('Error actualizando timestamp de sincronización: $e');
    }
  }

  /// Obtiene IDs existentes en lote para evitar consultas individuales
  Future<Set<int>> _getExistingProductIds(List<dynamic> ids) async {
    try {
      if (ids.isEmpty) return <int>{};
      
      // Convertir a enteros y filtrar nulos
      final intIds = ids.where((id) => id != null).map((id) => id as int).toList();
      if (intIds.isEmpty) return <int>{};
      
      // Obtener productos existentes en una sola consulta
      final productos = await _localDb.getAllProductos();
      return productos.map((p) => p.id ?? 0).where((id) => id > 0).toSet();
    } catch (e) {
      LoggingService.error('Error obteniendo IDs existentes: $e');
      return <int>{};
    }
  }

  /// Obtiene IDs existentes de ventas en lote
  Future<Set<int>> _getExistingVentaIds(List<dynamic> ids) async {
    try {
      if (ids.isEmpty) return <int>{};
      
      final intIds = ids.where((id) => id != null).map((id) => id as int).toList();
      if (intIds.isEmpty) return <int>{};
      
      final ventas = await _localDb.getAllVentas();
      return ventas.map((v) => v.id ?? 0).where((id) => id > 0).toSet();
    } catch (e) {
      LoggingService.error('Error obteniendo IDs de ventas existentes: $e');
      return <int>{};
    }
  }

  /// Obtiene IDs existentes de clientes en lote
  Future<Set<int>> _getExistingClienteIds(List<dynamic> ids) async {
    try {
      if (ids.isEmpty) return <int>{};
      
      final intIds = ids.where((id) => id != null).map((id) => id as int).toList();
      if (intIds.isEmpty) return <int>{};
      
      final clientes = await _localDb.getAllClientes();
      return clientes.map((c) => c.id ?? 0).where((id) => id > 0).toSet();
    } catch (e) {
      LoggingService.error('Error obteniendo IDs de clientes existentes: $e');
      return <int>{};
    }
  }

  // ==================== MATERIALES Y CÁLCULOS ====================

  /// Guarda un material con información de cálculo de precio
  Future<bool> saveMaterialConCalculo({
    required String nombre,
    required double cantidad,
    required double precioUnitario,
    required String unidad,
    required String categoria,
    Map<String, dynamic>? metadatosCalculo,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando guardar material');
        return false;
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'save_material')) {
        return false;
      }

      // Crear datos del material
      final materialData = {
        'nombre': nombre.trim(),
        'cantidad': cantidad,
        'precio_unitario': precioUnitario,
        'unidad': unidad.trim(),
        'categoria': categoria.trim(),
        'precio_total': cantidad * precioUnitario,
        'metadatos_calculo': metadatosCalculo ?? {},
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Validar tamaño de datos
      if (!_validateDataSize(materialData)) {
        LoggingService.warning('Material excede el tamaño máximo permitido');
        return false;
      }

      // Sanitizar datos
      final sanitizedData = _sanitizeData(materialData);

      // Guardar en local (simulando con productos por ahora)
      final materialProducto = Producto(
        nombre: 'Material: ${sanitizedData['nombre']}',
        categoria: sanitizedData['categoria'],
        talla: sanitizedData['unidad'],
        costoMateriales: sanitizedData['precio_unitario'],
        costoManoObra: 0.0,
        gastosGenerales: 0.0,
        margenGanancia: 0.0,
        stock: sanitizedData['cantidad'].toInt(),
        fechaCreacion: DateTime.now(),
      );

      await _localDb.insertProducto(materialProducto, userId: userId);

      // Si está autenticado, sincronizar con Supabase
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'materiales',
          data: sanitizedData,
        ));
      }

      // Invalidar cache del usuario
      _invalidateUserCache(userId, 'materiales');

      LoggingService.info('Material guardado exitosamente para usuario $userId: $nombre');
      return true;
    } catch (e) {
      LoggingService.error('Error guardando material: $e');
      return false;
    }
  }

  /// Obtiene materiales del usuario con filtros
  Future<List<Map<String, dynamic>>> getMateriales({
    String? categoria,
    String? unidad,
    double? precioMin,
    double? precioMax,
    int page = 0,
    int limit = _maxItemsPerPage,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando obtener materiales');
        return [];
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'get_materiales')) {
        return [];
      }

      final cacheKey = 'materiales_${userId}_${categoria}_${unidad}_${precioMin}_${precioMax}_${page}_$limit';
      
      // Verificar cache primero
      if (_isCacheValid(cacheKey)) {
        return List<Map<String, dynamic>>.from(_cache[cacheKey]);
      }

      // Obtener productos que son materiales
      final productos = await _localDb.getAllProductos();
      final materiales = productos
          .where((p) => p.nombre.startsWith('Material: '))
          .map((p) => {
                'id': p.id,
                'nombre': p.nombre.replaceFirst('Material: ', ''),
                'cantidad': p.stock.toDouble(),
                'precio_unitario': p.costoMateriales,
                'precio_total': p.precioVenta,
                'unidad': p.talla,
                'categoria': p.categoria,
                'metadatos_calculo': {},
                'created_at': p.fechaCreacion.toIso8601String(),
                'updated_at': p.fechaCreacion.toIso8601String(),
              })
          .where((m) {
            if (categoria != null && m['categoria'] != categoria) return false;
            if (unidad != null && m['unidad'] != unidad) return false;
            if (precioMin != null && (m['precio_unitario'] as double) < precioMin) return false;
            if (precioMax != null && (m['precio_unitario'] as double) > precioMax) return false;
            return true;
          })
          .toList();

      // Aplicar paginación
      final startIndex = page * limit;
      final endIndex = (startIndex + limit).clamp(0, materiales.length);
      final paginatedMateriales = materiales.sublist(startIndex, endIndex);

      _updateCache(cacheKey, paginatedMateriales);
      return paginatedMateriales;
    } catch (e) {
      LoggingService.error('Error obteniendo materiales: $e');
      return [];
    }
  }

  /// Calcula el precio de un producto con materiales
  Future<Map<String, dynamic>> calcularPrecioProducto({
    required String nombreProducto,
    required List<Map<String, dynamic>> materiales,
    required double margenGanancia,
    required double costosAdicionales,
    Map<String, dynamic>? metadatosCalculo,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        LoggingService.warning('Usuario no autenticado intentando calcular precio');
        return {'error': 'Usuario no autenticado'};
      }

      // Validar acceso del usuario
      if (!await _validateUserAccess(userId, 'calcular_precio')) {
        return {'error': 'Acceso denegado'};
      }

      // Calcular costos de materiales
      double costoTotalMateriales = 0;
      for (final material in materiales) {
        final cantidad = material['cantidad'] as double;
        final precioUnitario = material['precio_unitario'] as double;
        costoTotalMateriales += cantidad * precioUnitario;
      }

      // Calcular precio final
      final costoTotal = costoTotalMateriales + costosAdicionales;
      final precioConMargen = costoTotal * (1 + margenGanancia / 100);
      final precioFinal = precioConMargen.roundToDouble();

      // Crear resultado del cálculo
      final resultado = {
        'nombre_producto': nombreProducto,
        'costo_materiales': costoTotalMateriales,
        'costos_adicionales': costosAdicionales,
        'costo_total': costoTotal,
        'margen_ganancia': margenGanancia,
        'precio_final': precioFinal,
        'utilidad': precioFinal - costoTotal,
        'porcentaje_utilidad': ((precioFinal - costoTotal) / precioFinal * 100).roundToDouble(),
        'materiales_utilizados': materiales,
        'metadatos_calculo': metadatosCalculo ?? {},
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Guardar cálculo en historial
      await _guardarCalculoEnHistorial(resultado);

      LoggingService.info('Precio calculado para usuario $userId: $nombreProducto = \$${precioFinal.toStringAsFixed(2)}');
      return resultado;
    } catch (e) {
      LoggingService.error('Error calculando precio: $e');
      return {'error': 'Error interno del servidor'};
    }
  }

  /// Guarda el cálculo en el historial
  Future<void> _guardarCalculoEnHistorial(Map<String, dynamic> calculo) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      // Guardar en local
      final calculoData = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'user_id': userId,
        'tipo': 'calculo_precio',
        'datos': calculo,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Simular guardado en base de datos local
      // En una implementación real, esto iría a una tabla de historial

      // Si está autenticado, sincronizar con Supabase
      if (_isSignedIn && !_isAnonymous) {
        _enhancedSyncService.addSyncOperation(enhanced_sync.SyncOperation(
          type: SyncType.create,
          table: 'historial_calculos',
          data: calculoData,
        ));
      }

      LoggingService.info('Cálculo guardado en historial para usuario $userId');
    } catch (e) {
      LoggingService.error('Error guardando cálculo en historial: $e');
    }
  }

  // ==================== MÉTODOS DE COMPATIBILIDAD ====================

  /// Inserta una nueva venta (método de compatibilidad)
  Future<int> insertVenta(Venta venta) async {
    final ventaId = await _localDb.insertVenta(venta);
    
    // Invalidar cache de productos porque el stock se redujo
    _invalidateCache('productos_${_currentUserId ?? 'anon'}');
    
    // Invalidar cache de ventas
    _invalidateCache('ventas_${_currentUserId ?? 'anon'}');
    
    LoggingService.info('Cache invalidado después de insertar venta $ventaId');
    return ventaId;
  }

  /// Obtiene todos los productos (método de compatibilidad)
  Future<List<Producto>> getAllProductos() async {
    return await getProductos();
  }

  /// Obtiene todos los clientes (método de compatibilidad)
  Future<List<Cliente>> getAllClientes() async {
    return await getClientes();
  }

  /// Obtiene todas las ventas (método de compatibilidad)
  Future<List<Venta>> getAllVentas() async {
    return await getVentas();
  }

  /// Obtiene ventas por rango de fechas
  Future<List<Venta>> getVentasByDateRange(DateTime startDate, DateTime endDate) async {
    try {
      LoggingService.info('📅 [DATOS] Obteniendo ventas por rango: ${startDate.toIso8601String()} - ${endDate.toIso8601String()}');
      LoggingService.info('👤 [DATOS] Usuario actual: $_currentUserId (isSignedIn: $_isSignedIn, isAnonymous: $_isAnonymous)');
      
      final ventas = await getVentas();
      LoggingService.info('📊 [DATOS] Total de ventas obtenidas: ${ventas.length}');
      
      final ventasFiltradas = ventas.where((venta) => 
        venta.fecha.isAfter(startDate.subtract(const Duration(days: 1))) && 
        venta.fecha.isBefore(endDate.add(const Duration(days: 1)))
      ).toList();
      
      LoggingService.info('📈 [DATOS] Ventas filtradas por fecha: ${ventasFiltradas.length}');
      
      return ventasFiltradas;
    } catch (e) {
      LoggingService.error('❌ [DATOS] Error obteniendo ventas por rango de fechas: $e');
      return [];
    }
  }

  // ==================== MÉTRICAS DEL DASHBOARD ====================

  /// Obtiene el total de ventas del mes actual
  Future<double> getTotalVentasDelMes() async {
    try {
      final ventas = await getVentas();
      final ahora = DateTime.now();
      final inicioDelMes = DateTime(ahora.year, ahora.month, 1);
      
      double total = 0.0;
      for (final venta in ventas) {
        if (venta.fecha.isAfter(inicioDelMes) && venta.fecha.isBefore(ahora)) {
          total += venta.total;
        }
      }
      
      return total;
    } catch (e) {
      LoggingService.error('Error obteniendo ventas del mes: $e');
      return 0.0;
    }
  }

  /// Obtiene las ventas de los últimos 7 días
  Future<List<Map<String, dynamic>>> getVentasUltimos7Dias() async {
    try {
      final ventas = await getVentas();
      final ahora = DateTime.now();
      final hace7Dias = ahora.subtract(const Duration(days: 7));
      
      // Agrupar ventas por día
      final Map<String, double> ventasPorDia = {};
      
      for (int i = 0; i < 7; i++) {
        final fecha = ahora.subtract(Duration(days: i));
        final fechaStr = fecha.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
        ventasPorDia[fechaStr] = 0.0;
      }
      
      // Sumar ventas por día
      for (final venta in ventas) {
        if (venta.fecha.isAfter(hace7Dias) && venta.fecha.isBefore(ahora)) {
          final fechaStr = venta.fecha.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
          ventasPorDia[fechaStr] = (ventasPorDia[fechaStr] ?? 0.0) + venta.total;
        }
      }
      
      // Convertir a lista ordenada
      final List<Map<String, dynamic>> resultado = [];
      for (int i = 6; i >= 0; i--) {
        final fecha = ahora.subtract(Duration(days: i));
        final fechaStr = fecha.toIso8601String().split('T')[0]; // Formato YYYY-MM-DD
        resultado.add({
          'fecha': fechaStr,
          'total': ventasPorDia[fechaStr] ?? 0.0,
        });
      }
      
      return resultado;
    } catch (e) {
      LoggingService.error('Error obteniendo ventas de los últimos 7 días: $e');
      return [];
    }
  }

  // ==================== UTILIDADES ====================

  /// Obtiene el estado de sincronización
  bool get isSyncing => _enhancedSyncService.syncStatus == SyncStatus.syncing;
  
  /// Obtiene el número de operaciones pendientes
  int get pendingOperations => _enhancedSyncService.pendingOperations;
  
  /// Fuerza la sincronización de todos los datos
  Future<void> forceSync() async {
    if (_isSignedIn && !_isAnonymous) {
      await _loadUserData();
      // Procesar cola de sincronización pendiente (ahora manejado por EnhancedSyncService)
      await _enhancedSyncService.forceSync();
    }
  }

  /// Obtiene el estado de sincronización mejorado
  SyncStatus get syncStatus => _enhancedSyncService.syncStatus;

  /// Obtiene el tiempo de la última sincronización exitosa
  DateTime? get lastSyncTime => _enhancedSyncService.lastSyncTime;

  // ==================== MÉTODOS PARA CATEGORÍAS ====================

  /// Obtiene todas las categorías
  Future<List<Categoria>> getCategorias() async {
    return await _categoriaService.getCategorias();
  }

  /// Guarda una nueva categoría
  Future<Categoria> saveCategoria(Categoria categoria) async {
    return await _categoriaService.saveCategoria(categoria);
  }

  /// Actualiza una categoría existente
  Future<Categoria> updateCategoria(Categoria categoria) async {
    return await _categoriaService.updateCategoria(categoria);
  }

  /// Elimina una categoría
  Future<void> deleteCategoria(int id) async {
    return await _categoriaService.deleteCategoria(id);
  }

  // ==================== MÉTODOS PARA TALLAS ====================

  /// Obtiene todas las tallas
  Future<List<Talla>> getTallas() async {
    return await _tallaService.getTallas();
  }

  /// Guarda una nueva talla
  Future<Talla> saveTalla(Talla talla) async {
    return await _tallaService.saveTalla(talla);
  }

  /// Actualiza una talla existente
  Future<Talla> updateTalla(Talla talla) async {
    return await _tallaService.updateTalla(talla);
  }

  /// Elimina una talla
  Future<void> deleteTalla(int id) async {
    return await _tallaService.deleteTalla(id);
  }
}

// Los enums SyncType ahora están en connectivity_enums.dart

/// Operación de sincronización
class SyncOperation {
  final SyncType type;
  final String table;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  SyncOperation({
    required this.type,
    required this.table,
    required this.data,
  }) : timestamp = DateTime.now();
}
