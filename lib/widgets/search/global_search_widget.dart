import 'package:flutter/material.dart';
import 'package:stockcito/config/app_theme.dart';
import 'package:stockcito/services/search/search_service.dart';
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
  
  List<SearchResult> _searchResults = [];
  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _currentQuery.isEmpty;
    });
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
    widget.onResultSelected?.call(result);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _currentQuery = '';
      _showSuggestions = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Campo de búsqueda
        Container(
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
        ),

        // Resultados o sugerencias
        if (_currentQuery.isNotEmpty && _searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SearchResultsWidget(
              results: _searchResults,
              onResultSelected: _onResultSelected,
            ),
          )
        else if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.borderColor.withOpacity(0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildSuggestionsList(),
          ),
      ],
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
