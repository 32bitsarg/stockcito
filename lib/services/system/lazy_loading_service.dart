import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/services/system/intelligent_cache_service.dart';

/// Servicio de lazy loading con paginación inteligente y precarga
class LazyLoadingService {
  static final LazyLoadingService _instance = LazyLoadingService._internal();
  factory LazyLoadingService() => _instance;
  LazyLoadingService._internal();

  final IntelligentCacheService _cacheService = IntelligentCacheService();

  // Configuración de paginación
  static const int _defaultPageSize = 20;
  static const int _maxPreloadPages = 3; // Máximo 3 páginas de precarga

  // Estado de carga por entidad
  final Map<String, _LoadingState> _loadingStates = {};

  /// Inicializa el servicio de lazy loading
  Future<void> initialize() async {
    try {
      LoggingService.info('Inicializando LazyLoadingService...');
      
      // Limpiar estados de carga existentes
      _loadingStates.clear();
      
      // Inicializar el servicio de caché si no está inicializado
      // El IntelligentCacheService ya es singleton, así que no necesitamos inicializarlo aquí
      
      LoggingService.info('LazyLoadingService inicializado correctamente');
    } catch (e) {
      LoggingService.error('Error inicializando LazyLoadingService: $e');
    }
  }

  /// Carga datos con lazy loading
  Future<List<T>> loadData<T>({
    required String entityKey,
    required int page,
    required int pageSize,
    required Future<List<T>> Function(int page, int pageSize) dataLoader,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    Map<String, dynamic>? filters,
    bool enablePreload = true,
  }) async {
    try {
      final cacheKey = _generateCacheKey(entityKey, page, pageSize, filters);
      
      // 1. Verificar caché primero
      final cachedData = await _cacheService.get<List<T>>(
        cacheKey,
        (data) => (data['items'] as List).map((item) => fromJson(item as Map<String, dynamic>)).toList(),
      );
      
      if (cachedData != null) {
        LoggingService.debug('Datos cargados desde caché: $entityKey página $page');
        
        // Precargar páginas siguientes si está habilitado
        if (enablePreload) {
          _preloadNextPages(entityKey, page, pageSize, dataLoader, fromJson, toJson, filters);
        }
        
        return cachedData;
      }
      
      // 2. Cargar desde fuente de datos
      LoggingService.debug('Cargando datos desde fuente: $entityKey página $page');
      final data = await dataLoader(page, pageSize);
      
      // 3. Guardar en caché
      await _cacheService.set(
        cacheKey,
        data,
        (items) => {'items': items.map(toJson).toList()},
      );
      
      // 4. Actualizar estado de carga
      _updateLoadingState(entityKey, page, data.length);
      
      // 5. Precargar páginas siguientes
      if (enablePreload && data.length == pageSize) {
        _preloadNextPages(entityKey, page, pageSize, dataLoader, fromJson, toJson, filters);
      }
      
      return data;
      
    } catch (e) {
      LoggingService.error('Error en lazy loading: $e');
      return [];
    }
  }

  /// Verifica si una página está cargada
  bool isPageLoaded(String entityKey, int page) {
    final state = _loadingStates[entityKey];
    return state?.loadedPages.contains(page) ?? false;
  }

  /// Verifica si hay más páginas disponibles
  bool hasMorePages(String entityKey) {
    final state = _loadingStates[entityKey];
    return state?.hasMore ?? true;
  }

  /// Obtiene el número total de elementos cargados
  int getLoadedCount(String entityKey) {
    final state = _loadingStates[entityKey];
    return state?.totalLoaded ?? 0;
  }

  /// Obtiene el número de páginas cargadas
  int getLoadedPagesCount(String entityKey) {
    final state = _loadingStates[entityKey];
    return state?.loadedPages.length ?? 0;
  }

  /// Invalida caché para una entidad específica
  Future<void> invalidateEntity(String entityKey) async {
    try {
      await _cacheService.invalidatePattern(entityKey);
      _loadingStates.remove(entityKey);
      LoggingService.debug('Caché invalidado para entidad: $entityKey');
    } catch (e) {
      LoggingService.error('Error invalidando entidad: $e');
    }
  }

  /// Precarga páginas siguientes
  Future<void> _preloadNextPages<T>(
    String entityKey,
    int currentPage,
    int pageSize,
    Future<List<T>> Function(int page, int pageSize) dataLoader,
    T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic> Function(T) toJson,
    Map<String, dynamic>? filters,
  ) async {
    try {
      final state = _loadingStates[entityKey];
      if (state == null || !state.hasMore) return;
      
      // Precargar hasta 3 páginas siguientes
      final pagesToPreload = <int>[];
      for (int i = 1; i <= _maxPreloadPages; i++) {
        final nextPage = currentPage + i;
        if (!state.loadedPages.contains(nextPage)) {
          pagesToPreload.add(nextPage);
        }
      }
      
      // Precargar en paralelo
      final preloadFutures = pagesToPreload.map((page) async {
        try {
          final cacheKey = _generateCacheKey(entityKey, page, pageSize, filters);
          
          // Verificar si ya está en caché
          final cachedData = await _cacheService.get<List<T>>(
            cacheKey,
            (data) => (data['items'] as List).map((item) => fromJson(item as Map<String, dynamic>)).toList(),
          );
          
          if (cachedData == null) {
            // Cargar y guardar en caché
            final data = await dataLoader(page, pageSize);
            await _cacheService.set(
              cacheKey,
              data,
              (items) => {'items': items.map(toJson).toList()},
            );
            
            _updateLoadingState(entityKey, page, data.length);
            
            LoggingService.debug('Página precargada: $entityKey página $page');
          }
        } catch (e) {
          LoggingService.error('Error precargando página $page: $e');
        }
      });
      
      await Future.wait(preloadFutures);
      
    } catch (e) {
      LoggingService.error('Error en precarga: $e');
    }
  }

  /// Actualiza el estado de carga
  void _updateLoadingState(String entityKey, int page, int itemCount) {
    final state = _loadingStates[entityKey] ?? _LoadingState();
    
    state.loadedPages.add(page);
    state.totalLoaded += itemCount;
    
    // Si la página no está llena, no hay más páginas
    if (itemCount < _defaultPageSize) {
      state.hasMore = false;
    }
    
    _loadingStates[entityKey] = state;
  }

  /// Genera clave de caché única
  String _generateCacheKey(String entityKey, int page, int pageSize, Map<String, dynamic>? filters) {
    final buffer = StringBuffer();
    buffer.write('${entityKey}_page_${page}_size_$pageSize');
    
    if (filters != null && filters.isNotEmpty) {
      final sortedFilters = Map.fromEntries(
        filters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write('_filters_${sortedFilters.toString()}');
    }
    
    return buffer.toString();
  }

  /// Obtiene estadísticas de lazy loading
  Map<String, dynamic> getStats() {
    return {
      'entities': _loadingStates.length,
      'total_pages_loaded': _loadingStates.values.fold(0, (sum, state) => sum + state.loadedPages.length),
      'total_items_loaded': _loadingStates.values.fold(0, (sum, state) => sum + state.totalLoaded),
      'cache_stats': _cacheService.getStats(),
    };
  }

  /// Limpia todos los estados de carga
  void clearStates() {
    _loadingStates.clear();
    LoggingService.debug('Estados de lazy loading limpiados');
  }
}

/// Estado de carga para una entidad
class _LoadingState {
  final Set<int> loadedPages = {};
  int totalLoaded = 0;
  bool hasMore = true;
}
