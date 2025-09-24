import 'dart:async';
import 'package:stockcito/services/datos/datos.dart';
import 'package:stockcito/services/system/logging_service.dart';
import 'package:stockcito/models/search_result.dart';

/// Servicio centralizado de búsqueda global
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final DatosService _datosService = DatosService();
  
  // Historial de búsquedas
  final List<String> _searchHistory = [];
  static const int _maxHistorySize = 20;
  
  // Cache de resultados de búsqueda
  final Map<String, List<SearchResult>> _searchCache = {};

  /// Realiza una búsqueda global en productos, ventas y clientes
  Future<List<SearchResult>> searchGlobal({
    required String query,
    SearchFilters filters = const SearchFilters(),
    int maxResults = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      LoggingService.info('🔍 Realizando búsqueda global: "$query"');

      // Verificar cache primero
      final cacheKey = _generateCacheKey(query, filters);
      if (_searchCache.containsKey(cacheKey)) {
        LoggingService.info('📋 Resultados encontrados en cache');
        return _searchCache[cacheKey]!;
      }

      // Agregar a historial
      _addToHistory(query);

      // Realizar búsquedas paralelas
      final List<Future<List<SearchResult>>> searchTasks = [];

      if (_shouldSearchEntity(filters.entityTypes, SearchEntityType.producto)) {
        searchTasks.add(_searchProductos(query, filters));
      }

      if (_shouldSearchEntity(filters.entityTypes, SearchEntityType.venta)) {
        searchTasks.add(_searchVentas(query, filters));
      }

      if (_shouldSearchEntity(filters.entityTypes, SearchEntityType.cliente)) {
        searchTasks.add(_searchClientes(query, filters));
      }

      // Esperar todas las búsquedas
      final List<List<SearchResult>> results = await Future.wait(searchTasks);
      
      // Combinar y ordenar resultados
      final List<SearchResult> allResults = [];
      for (final resultList in results) {
        allResults.addAll(resultList);
      }

      // Ordenar por relevancia y fecha
      allResults.sort((a, b) {
        // Primero por relevancia
        final relevanceComparison = b.relevanceScore.compareTo(a.relevanceScore);
        if (relevanceComparison != 0) return relevanceComparison;
        
        // Luego por fecha (más recientes primero)
        return b.createdAt.compareTo(a.createdAt);
      });

      // Limitar resultados
      final limitedResults = allResults.take(maxResults).toList();

      // Guardar en cache
      _searchCache[cacheKey] = limitedResults;

      LoggingService.info('✅ Búsqueda completada: ${limitedResults.length} resultados');
      return limitedResults;

    } catch (e) {
      LoggingService.error('❌ Error en búsqueda global: $e');
      return [];
    }
  }

  /// Busca productos
  Future<List<SearchResult>> _searchProductos(String query, SearchFilters filters) async {
    try {
      final productos = await _datosService.getProductos();
      final queryLower = query.toLowerCase();

      final results = productos
          .where((producto) => _matchesProducto(producto, queryLower, filters))
          .map((producto) => SearchResult.fromProducto(producto.toMap()))
          .toList();

      // Calcular relevancia
      for (final result in results) {
        result.relevanceScore = _calculateProductoRelevance(result, queryLower);
        result.matchedFields = _getMatchedProductoFields(result.data, queryLower);
      }

      return results;
    } catch (e) {
      LoggingService.error('Error buscando productos: $e');
      return [];
    }
  }

  /// Busca ventas
  Future<List<SearchResult>> _searchVentas(String query, SearchFilters filters) async {
    try {
      final ventas = await _datosService.getVentas();
      final queryLower = query.toLowerCase();

      final results = ventas
          .where((venta) => _matchesVenta(venta, queryLower, filters))
          .map((venta) => SearchResult.fromVenta(venta.toMap()))
          .toList();

      // Calcular relevancia
      for (final result in results) {
        result.relevanceScore = _calculateVentaRelevance(result, queryLower);
        result.matchedFields = _getMatchedVentaFields(result.data, queryLower);
      }

      return results;
    } catch (e) {
      LoggingService.error('Error buscando ventas: $e');
      return [];
    }
  }

  /// Busca clientes
  Future<List<SearchResult>> _searchClientes(String query, SearchFilters filters) async {
    try {
      final clientes = await _datosService.getClientes();
      final queryLower = query.toLowerCase();

      final results = clientes
          .where((cliente) => _matchesCliente(cliente, queryLower, filters))
          .map((cliente) => SearchResult.fromCliente(cliente.toMap()))
          .toList();

      // Calcular relevancia
      for (final result in results) {
        result.relevanceScore = _calculateClienteRelevance(result, queryLower);
        result.matchedFields = _getMatchedClienteFields(result.data, queryLower);
      }

      return results;
    } catch (e) {
      LoggingService.error('Error buscando clientes: $e');
      return [];
    }
  }

  /// Verifica si un producto coincide con la búsqueda
  bool _matchesProducto(dynamic producto, String query, SearchFilters filters) {
    final nombre = (producto.nombre ?? '').toLowerCase();
    final categoria = (producto.categoria ?? '').toLowerCase();
    final talla = (producto.talla ?? '').toLowerCase();

    // Filtro por categoría
    if (filters.category != null && filters.category != 'Todas') {
      if (producto.categoria != filters.category) return false;
    }

    // Búsqueda por texto
    return nombre.contains(query) || 
           categoria.contains(query) || 
           talla.contains(query);
  }

  /// Verifica si una venta coincide con la búsqueda
  bool _matchesVenta(dynamic venta, String query, SearchFilters filters) {
    final cliente = (venta.cliente ?? '').toLowerCase();
    final estado = (venta.estado ?? '').toLowerCase();
    final metodoPago = (venta.metodoPago ?? '').toLowerCase();

    // Filtro por estado
    if (filters.status != null && filters.status != 'Todas') {
      if (venta.estado != filters.status) return false;
    }

    // Filtro por fecha
    if (filters.dateFrom != null && venta.fecha.isBefore(filters.dateFrom!)) {
      return false;
    }
    if (filters.dateTo != null && venta.fecha.isAfter(filters.dateTo!)) {
      return false;
    }

    // Búsqueda por texto
    return cliente.contains(query) || 
           estado.contains(query) || 
           metodoPago.contains(query);
  }

  /// Verifica si un cliente coincide con la búsqueda
  bool _matchesCliente(dynamic cliente, String query, SearchFilters filters) {
    final nombre = (cliente.nombre ?? '').toLowerCase();
    final telefono = (cliente.telefono ?? '').toLowerCase();
    final email = (cliente.email ?? '').toLowerCase();

    // Búsqueda por texto
    return nombre.contains(query) || 
           telefono.contains(query) || 
           email.contains(query);
  }

  /// Calcula la relevancia de un producto
  double _calculateProductoRelevance(SearchResult result, String query) {
    double score = 0.0;
    final data = result.data;

    // Coincidencia exacta en nombre (mayor peso)
    if ((data['nombre'] ?? '').toLowerCase() == query) {
      score += 10.0;
    } else if ((data['nombre'] ?? '').toLowerCase().startsWith(query)) {
      score += 8.0;
    } else if ((data['nombre'] ?? '').toLowerCase().contains(query)) {
      score += 5.0;
    }

    // Coincidencia en categoría
    if ((data['categoria'] ?? '').toLowerCase().contains(query)) {
      score += 3.0;
    }

    // Coincidencia en talla
    if ((data['talla'] ?? '').toLowerCase().contains(query)) {
      score += 2.0;
    }

    return score;
  }

  /// Calcula la relevancia de una venta
  double _calculateVentaRelevance(SearchResult result, String query) {
    double score = 0.0;
    final data = result.data;

    // Coincidencia en cliente (mayor peso)
    if ((data['cliente'] ?? '').toLowerCase().contains(query)) {
      score += 6.0;
    }

    // Coincidencia en estado
    if ((data['estado'] ?? '').toLowerCase().contains(query)) {
      score += 3.0;
    }

    // Coincidencia en método de pago
    if ((data['metodoPago'] ?? '').toLowerCase().contains(query)) {
      score += 2.0;
    }

    return score;
  }

  /// Calcula la relevancia de un cliente
  double _calculateClienteRelevance(SearchResult result, String query) {
    double score = 0.0;
    final data = result.data;

    // Coincidencia exacta en nombre (mayor peso)
    if ((data['nombre'] ?? '').toLowerCase() == query) {
      score += 10.0;
    } else if ((data['nombre'] ?? '').toLowerCase().startsWith(query)) {
      score += 8.0;
    } else if ((data['nombre'] ?? '').toLowerCase().contains(query)) {
      score += 5.0;
    }

    // Coincidencia en teléfono
    if ((data['telefono'] ?? '').contains(query)) {
      score += 4.0;
    }

    // Coincidencia en email
    if ((data['email'] ?? '').toLowerCase().contains(query)) {
      score += 3.0;
    }

    return score;
  }

  /// Obtiene los campos que coincidieron en un producto
  List<String> _getMatchedProductoFields(Map<String, dynamic> data, String query) {
    final matchedFields = <String>[];
    
    if ((data['nombre'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('nombre');
    }
    if ((data['categoria'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('categoria');
    }
    if ((data['talla'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('talla');
    }
    
    return matchedFields;
  }

  /// Obtiene los campos que coincidieron en una venta
  List<String> _getMatchedVentaFields(Map<String, dynamic> data, String query) {
    final matchedFields = <String>[];
    
    if ((data['cliente'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('cliente');
    }
    if ((data['estado'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('estado');
    }
    if ((data['metodoPago'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('metodoPago');
    }
    
    return matchedFields;
  }

  /// Obtiene los campos que coincidieron en un cliente
  List<String> _getMatchedClienteFields(Map<String, dynamic> data, String query) {
    final matchedFields = <String>[];
    
    if ((data['nombre'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('nombre');
    }
    if ((data['telefono'] ?? '').contains(query)) {
      matchedFields.add('telefono');
    }
    if ((data['email'] ?? '').toLowerCase().contains(query)) {
      matchedFields.add('email');
    }
    
    return matchedFields;
  }

  /// Verifica si debe buscar en una entidad específica
  bool _shouldSearchEntity(List<SearchEntityType> types, SearchEntityType entity) {
    return types.contains(SearchEntityType.all) || types.contains(entity);
  }

  /// Genera clave de cache para la búsqueda
  String _generateCacheKey(String query, SearchFilters filters) {
    return 'search_${query.toLowerCase()}_${filters.toMap().toString()}';
  }

  /// Agrega término al historial de búsquedas
  void _addToHistory(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    // Remover si ya existe
    _searchHistory.remove(trimmedQuery);
    
    // Agregar al inicio
    _searchHistory.insert(0, trimmedQuery);
    
    // Limitar tamaño
    if (_searchHistory.length > _maxHistorySize) {
      _searchHistory.removeRange(_maxHistorySize, _searchHistory.length);
    }
  }

  /// Obtiene el historial de búsquedas
  List<String> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  /// Limpia el historial de búsquedas
  void clearSearchHistory() {
    _searchHistory.clear();
  }

  /// Obtiene sugerencias basadas en el historial y datos existentes
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) {
      return _searchHistory.take(5).toList();
    }

    try {
      final suggestions = <String>[];
      final queryLower = partialQuery.toLowerCase();

      // Agregar del historial
      for (final historyItem in _searchHistory) {
        if (historyItem.toLowerCase().contains(queryLower)) {
          suggestions.add(historyItem);
        }
      }

      // Agregar nombres de productos, clientes, etc.
      final productos = await _datosService.getProductos();
      for (final producto in productos.take(10)) {
        final nombre = producto.nombre.toLowerCase();
        if (nombre.contains(queryLower) && !suggestions.contains(producto.nombre)) {
          suggestions.add(producto.nombre);
        }
      }

      final clientes = await _datosService.getClientes();
      for (final cliente in clientes.take(10)) {
        final nombre = cliente.nombre.toLowerCase();
        if (nombre.contains(queryLower) && !suggestions.contains(cliente.nombre)) {
          suggestions.add(cliente.nombre);
        }
      }

      return suggestions.take(10).toList();
    } catch (e) {
      LoggingService.error('Error obteniendo sugerencias: $e');
      return _searchHistory.take(5).toList();
    }
  }

  /// Limpia el cache de búsquedas
  void clearSearchCache() {
    _searchCache.clear();
  }

  /// Obtiene estadísticas de búsqueda
  Map<String, dynamic> getSearchStats() {
    return {
      'historySize': _searchHistory.length,
      'cacheSize': _searchCache.length,
      'lastSearch': _searchHistory.isNotEmpty ? _searchHistory.first : null,
    };
  }
}
