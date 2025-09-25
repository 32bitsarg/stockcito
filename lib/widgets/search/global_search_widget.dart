import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/services/search/search_service.dart';
import 'package:stockcito/services/navigation/search_navigation_service.dart';
import 'package:stockcito/models/search_result.dart';
import 'search_results_widget.dart';

/// Widget de búsqueda global con autocompletado y resultados
class GlobalSearchWidget extends StatefulWidget {
  final Function(SearchResult)? onResultSelected;
  final Function(String)? onSearchPerformed;
  final bool showSuggestions;
  final bool showHistory;
  final String? hintText;

  const GlobalSearchWidget({
    super.key,
    this.onResultSelected,
    this.onSearchPerformed,
    this.showSuggestions = true,
    this.showHistory = true,
    this.hintText,
  });

  @override
  State<GlobalSearchWidget> createState() => _GlobalSearchWidgetState();
}

class _GlobalSearchWidgetState extends State<GlobalSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SearchService _searchService = SearchService();
  final SearchNavigationService _navigationService = SearchNavigationService();
  
  List<SearchResult> _searchResults = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _currentQuery = '';
  
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _createOverlay() {
    if (_overlayEntry != null) return;
    
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo transparente para detectar clics fuera
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print('🔍 [DEBUG] Overlay: Clic fuera del contenido');
                _removeOverlay();
                _focusNode.unfocus();
              },
            ),
          ),
          // Contenido del overlay
          Positioned(
            left: offset.dx,
            top: offset.dy + renderBox.size.height + 8,
            width: renderBox.size.width,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxHeight: 300, // Limitar altura máxima
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildOverlayContent(),
              ),
            ),
          ),
        ],
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  Widget _buildOverlayContent() {
    print('🔍 [DEBUG] GlobalSearchWidget._buildOverlayContent:');
    print('   - Query actual: "$_currentQuery"');
    print('   - Resultados: ${_searchResults.length}');
    print('   - Mostrar sugerencias: $_showSuggestions');
    print('   - Sugerencias: ${_suggestions.length}');
    
    if (_currentQuery.isNotEmpty && _searchResults.isNotEmpty) {
      print('🔍 [DEBUG] Creando SearchResultsWidget con ${_searchResults.length} resultados');
      return SingleChildScrollView(
        child: SearchResultsWidget(
          results: _searchResults,
          onResultSelected: _onResultSelected,
        ),
      );
    } else if (_showSuggestions && _suggestions.isNotEmpty) {
      print('🔍 [DEBUG] Creando lista de sugerencias con ${_suggestions.length} sugerencias');
      return SingleChildScrollView(
        child: _buildSuggestionsList(),
      );
    } else {
      print('🔍 [DEBUG] No hay contenido para mostrar');
      return const SizedBox.shrink();
    }
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _currentQuery.isEmpty;
    });
    
    if (_focusNode.hasFocus && _currentQuery.isEmpty && _suggestions.isNotEmpty) {
      _createOverlay();
    }
  }

  Future<void> _loadSuggestions() async {
    if (!widget.showSuggestions) return;
    
    try {
      final suggestions = await _searchService.getSuggestions('');
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
        });
      }
    } catch (e) {
      // Error silencioso para sugerencias
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
        _showSuggestions = _focusNode.hasFocus;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
      _showSuggestions = false;
    });

    try {
      final results = await _searchService.searchGlobal(query: query);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        
        // Crear o actualizar overlay
        if (results.isNotEmpty) {
          _createOverlay();
        } else {
          _removeOverlay();
        }
        
        // Notificar que se realizó una búsqueda
        widget.onSearchPerformed?.call(query);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
    _focusNode.unfocus();
  }

  void _onResultSelected(SearchResult result) {
    print('🔍 [DEBUG] GlobalSearchWidget._onResultSelected:');
    print('   - Resultado seleccionado: ${result.title}');
    print('   - Tipo: ${result.type}');
    print('   - ID: ${result.id}');
    
    // Cerrar overlay y quitar foco
    _focusNode.unfocus();
    _removeOverlay();
    
    print('🔍 [DEBUG] GlobalSearchWidget._onResultSelected: Overlay cerrado, navegando...');
    
    // Navegar usando el servicio de navegación
    _navigationService.navigateToResult(context, result);
    
    // Llamar callback personalizado si existe
    widget.onResultSelected?.call(result);
    
    print('🔍 [DEBUG] GlobalSearchWidget._onResultSelected: Navegación completada');
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _currentQuery = '';
      _showSuggestions = _focusNode.hasFocus;
    });
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? AppTheme.primaryColor 
                  : AppTheme.borderColor.withOpacity(0.5),
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: _performSearch,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Buscar productos, ventas, clientes...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _focusNode.hasFocus 
                    ? AppTheme.primaryColor 
                    : AppTheme.textSecondary,
                size: 20,
              ),
              suffixIcon: _currentQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppTheme.textSecondary,
                        size: 18,
                      ),
                      onPressed: _clearSearch,
                    )
                  : _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header de sugerencias
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Búsquedas recientes',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de sugerencias
        ...(_suggestions.take(5).map((suggestion) => ListTile(
          dense: true,
          leading: Icon(
            Icons.search,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          title: Text(
            suggestion,
            style: const TextStyle(fontSize: 14),
          ),
          onTap: () => _onSuggestionSelected(suggestion),
        )).toList()),
      ],
    );
  }
}
