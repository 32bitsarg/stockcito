import 'package:flutter/material.dart';
import 'package:stockcito/services/system/lazy_loading_service.dart';
import 'package:stockcito/services/system/logging_service.dart';

/// Widget de lista con lazy loading y scroll infinito
class LazyListWidget<T> extends StatefulWidget {
  final String entityKey;
  final int pageSize;
  final Future<List<T>> Function(int page, int pageSize) dataLoader;
  final Widget Function(T item, int index) itemBuilder;
  final Widget Function()? loadingWidget;
  final Widget Function()? emptyWidget;
  final Widget Function()? errorWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Map<String, dynamic>? filters;
  final bool enablePreload;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;

  const LazyListWidget({
    super.key,
    required this.entityKey,
    required this.dataLoader,
    required this.itemBuilder,
    this.pageSize = 20,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
    this.filters,
    this.enablePreload = true,
    this.onLoadMore,
    this.onRefresh,
  });

  @override
  State<LazyListWidget<T>> createState() => _LazyListWidgetState<T>();
}

class _LazyListWidgetState<T> extends State<LazyListWidget<T>> {
  final LazyLoadingService _lazyService = LazyLoadingService();
  final ScrollController _scrollController = ScrollController();
  
  List<T> _items = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyListWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recargar si cambió la entidad o los filtros
    if (oldWidget.entityKey != widget.entityKey || 
        oldWidget.filters != widget.filters) {
      _resetAndReload();
    }
  }

  /// Carga datos iniciales
  Future<void> _loadInitialData() async {
    await _loadPage(0, isInitial: true);
  }

  /// Carga una página específica
  Future<void> _loadPage(int page, {bool isInitial = false}) async {
    if (_isLoading || (!_hasMore && !isInitial)) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      LoggingService.debug('Cargando página $page de ${widget.entityKey}');
      
      final newItems = await _lazyService.loadData<T>(
        entityKey: widget.entityKey,
        page: page,
        pageSize: widget.pageSize,
        dataLoader: widget.dataLoader,
        fromJson: _dummyFromJson, // Se manejará en el dataLoader
        toJson: _dummyToJson,     // Se manejará en el dataLoader
        filters: widget.filters,
        enablePreload: widget.enablePreload,
      );

      setState(() {
        if (isInitial) {
          _items = newItems;
        } else {
          _items.addAll(newItems);
        }
        _currentPage = page;
        _hasMore = newItems.length == widget.pageSize;
        _isLoading = false;
      });

      // Notificar que se cargó más
      if (!isInitial && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }

    } catch (e) {
      LoggingService.error('Error cargando página $page: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Maneja el scroll para cargar más datos
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  /// Carga la siguiente página
  Future<void> _loadNextPage() async {
    if (!_hasMore || _isLoading) return;
    await _loadPage(_currentPage + 1);
  }

  /// Resetea y recarga los datos
  Future<void> _resetAndReload() async {
    setState(() {
      _items.clear();
      _currentPage = 0;
      _hasMore = true;
      _hasError = false;
    });
    
    await _lazyService.invalidateEntity(widget.entityKey);
    await _loadInitialData();
  }

  /// Refresca los datos
  Future<void> _refresh() async {
    await _resetAndReload();
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget?.call() ?? _buildDefaultError();
    }

    if (_items.isEmpty && !_isLoading) {
      return widget.emptyWidget?.call() ?? _buildDefaultEmpty();
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        shrinkWrap: widget.shrinkWrap,
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _items.length) {
            return widget.itemBuilder(_items[index], index);
          } else {
            // Mostrar indicador de carga al final
            return _buildLoadingIndicator();
          }
        },
      ),
    );
  }

  /// Construye indicador de carga por defecto
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: widget.loadingWidget?.call() ?? 
        const CircularProgressIndicator(),
    );
  }

  /// Construye estado vacío por defecto
  Widget _buildDefaultEmpty() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay elementos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Los elementos aparecerán aquí cuando estén disponibles',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construye estado de error por defecto
  Widget _buildDefaultError() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar datos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hubo un problema al cargar los elementos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  // Métodos dummy para el tipo genérico
  T _dummyFromJson(Map<String, dynamic> json) => throw UnimplementedError();
  Map<String, dynamic> _dummyToJson(T item) => throw UnimplementedError();
}
