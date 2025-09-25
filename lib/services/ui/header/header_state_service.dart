import 'dart:async';
import '../../system/logging_service.dart';
import '../../search/search_service.dart';
import '../../../models/search_result.dart';

/// Estados posibles para la búsqueda
enum SearchState {
  idle,
  searching,
  hasResults,
  noResults,
  error,
}

/// Estados posibles para las acciones del header
enum HeaderActionState {
  idle,
  loading,
  success,
  error,
}

/// Modelo para el estado de búsqueda
class SearchStateData {
  final SearchState state;
  final String query;
  final List<dynamic> results;
  final String? errorMessage;
  final DateTime lastSearch;

  SearchStateData({
    required this.state,
    required this.query,
    required this.results,
    this.errorMessage,
    required this.lastSearch,
  });

  SearchStateData copyWith({
    SearchState? state,
    String? query,
    List<dynamic>? results,
    String? errorMessage,
    DateTime? lastSearch,
  }) {
    return SearchStateData(
      state: state ?? this.state,
      query: query ?? this.query,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
      lastSearch: lastSearch ?? this.lastSearch,
    );
  }
}

/// Modelo para el estado de acciones
class ActionStateData {
  final HeaderActionState state;
  final String? actionType;
  final String? message;
  final DateTime timestamp;

  ActionStateData({
    required this.state,
    this.actionType,
    this.message,
    required this.timestamp,
  });

  ActionStateData copyWith({
    HeaderActionState? state,
    String? actionType,
    String? message,
    DateTime? timestamp,
  }) {
    return ActionStateData(
      state: state ?? this.state,
      actionType: actionType ?? this.actionType,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Servicio para manejar el estado del header
class HeaderStateService {
  static final HeaderStateService _instance = HeaderStateService._internal();
  factory HeaderStateService() => _instance;
  HeaderStateService._internal();

  // Streams para el estado
  final StreamController<SearchStateData> _searchStateController = 
      StreamController<SearchStateData>.broadcast();
  final StreamController<ActionStateData> _actionStateController = 
      StreamController<ActionStateData>.broadcast();
  final StreamController<bool> _isLoadingController = 
      StreamController<bool>.broadcast();

  // Servicios
  final SearchService _searchService = SearchService();

  // Estado actual
  SearchStateData _currentSearchState = SearchStateData(
    state: SearchState.idle,
    query: '',
    results: [],
    lastSearch: DateTime.now(),
  );

  ActionStateData _currentActionState = ActionStateData(
    state: HeaderActionState.idle,
    timestamp: DateTime.now(),
  );

  bool _isLoading = false;

  // Getters para streams
  Stream<SearchStateData> get searchStateStream => _searchStateController.stream;
  Stream<ActionStateData> get actionStateStream => _actionStateController.stream;
  Stream<bool> get isLoadingStream => _isLoadingController.stream;

  // Getters para estado actual
  SearchStateData get currentSearchState => _currentSearchState;
  ActionStateData get currentActionState => _currentActionState;
  bool get isLoading => _isLoading;

  /// Inicia una búsqueda
  Future<void> startSearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        _updateSearchState(SearchStateData(
          state: SearchState.idle,
          query: '',
          results: [],
          lastSearch: DateTime.now(),
        ));
        return;
      }

      _updateSearchState(_currentSearchState.copyWith(
        state: SearchState.searching,
        query: query.trim(),
        lastSearch: DateTime.now(),
      ));

      // Realizar búsqueda usando SearchService
      final results = await _performSearch(query.trim());

      _updateSearchState(_currentSearchState.copyWith(
        state: results.isEmpty ? SearchState.noResults : SearchState.hasResults,
        results: results,
        lastSearch: DateTime.now(),
      ));

    } catch (e) {
      LoggingService.error('Error en búsqueda: $e');
      _updateSearchState(_currentSearchState.copyWith(
        state: SearchState.error,
        errorMessage: e.toString(),
        lastSearch: DateTime.now(),
      ));
    }
  }

  /// Limpia la búsqueda actual
  void clearSearch() {
    _updateSearchState(SearchStateData(
      state: SearchState.idle,
      query: '',
      results: [],
      lastSearch: DateTime.now(),
    ));
  }

  /// Ejecuta una acción del header
  Future<void> executeAction(String actionType, Future<void> Function() action) async {
    try {
      _updateActionState(ActionStateData(
        state: HeaderActionState.loading,
        actionType: actionType,
        timestamp: DateTime.now(),
      ));

      await action();

      _updateActionState(ActionStateData(
        state: HeaderActionState.success,
        actionType: actionType,
        message: 'Acción completada exitosamente',
        timestamp: DateTime.now(),
      ));

    } catch (e) {
      LoggingService.error('Error ejecutando acción $actionType: $e');
      _updateActionState(ActionStateData(
        state: HeaderActionState.error,
        actionType: actionType,
        message: e.toString(),
        timestamp: DateTime.now(),
      ));
    }
  }

  /// Establece el estado de carga
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _isLoadingController.add(_isLoading);
    }
  }

  /// Obtiene el historial de búsquedas
  List<String> getSearchHistory() {
    return _searchService.getSearchHistory();
  }

  /// Limpia el historial de búsquedas
  void clearSearchHistory() {
    _searchService.clearSearchHistory();
  }

  /// Actualiza el estado de búsqueda
  void _updateSearchState(SearchStateData newState) {
    _currentSearchState = newState;
    _searchStateController.add(_currentSearchState);
  }

  /// Actualiza el estado de acciones
  void _updateActionState(ActionStateData newState) {
    _currentActionState = newState;
    _actionStateController.add(_currentActionState);
  }

  /// Realiza una búsqueda usando SearchService
  Future<List<SearchResult>> _performSearch(String query) async {
    try {
      LoggingService.info('🔍 Realizando búsqueda en header: "$query"');
      
      // Usar SearchService real
      final results = await _searchService.searchGlobal(
        query: query,
        maxResults: 20, // Limitar resultados para el header
      );
      
      LoggingService.info('📋 Búsqueda completada: ${results.length} resultados');
      return results;
      
    } catch (e) {
      LoggingService.error('❌ Error en búsqueda: $e');
      return [];
    }
  }

  /// Limpia los recursos
  void dispose() {
    _searchStateController.close();
    _actionStateController.close();
    _isLoadingController.close();
  }
}
