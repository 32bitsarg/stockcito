import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/ui/header/header_data_service.dart';
import 'ui/header/header_title_section.dart';
import 'ui/header/header_user_section.dart';
import 'search/global_search_widget.dart';

class ModernHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final TextEditingController? searchController;
  final Function(String)? onSearch;
  final List<Widget>? actions;
  final bool showNotifications;
  final bool showUserInfo;
  final bool showGreeting;
  final String? context;

  const ModernHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchController,
    this.onSearch,
    this.actions,
    this.showNotifications = true,
    this.showUserInfo = true,
    this.showGreeting = false,
    this.context,
  });

  @override
  State<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends State<ModernHeader> {
  final HeaderDataService _dataService = HeaderDataService();

  HeaderInfo? _headerInfo;

  @override
  void initState() {
    super.initState();
    print('🔍 [DEBUG] ModernHeader initState: title="${widget.title}", subtitle="${widget.subtitle}"');
    _loadHeaderData();
  }

  @override
  void didUpdateWidget(ModernHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🔍 [DEBUG] ModernHeader didUpdateWidget:');
    print('   - Old title: "${oldWidget.title}"');
    print('   - New title: "${widget.title}"');
    print('   - Old subtitle: "${oldWidget.subtitle}"');
    print('   - New subtitle: "${widget.subtitle}"');
    
    if (oldWidget.title != widget.title || oldWidget.subtitle != widget.subtitle) {
      print('   - Title/Subtitle changed, reloading header data');
      _loadHeaderData();
    }
  }

  void _loadHeaderData() {
    try {
      // Obtener información del header
      _headerInfo = _dataService.getHeaderInfo(
        title: widget.title,
        subtitle: widget.subtitle,
        context: widget.context,
        showSearch: widget.searchController != null,
        showUserInfo: widget.showUserInfo,
      );

      setState(() {});
    } catch (e) {
      // Manejar error silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_headerInfo == null) {
      return _buildLoadingHeader();
    }

    return Container(
      height: 80, // Altura más compacta
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Sección de título con saludo - Flexible
          Expanded(
            flex: 3,
              child: HeaderTitleSection(
                title: _headerInfo!.title,
                subtitle: _headerInfo!.subtitle,
              ),
          ),

          const SizedBox(width: 8),

          // Sección de búsqueda - Tamaño fijo
          if (widget.searchController != null)
            SizedBox(
              width: 250,
              child: GlobalSearchWidget(
                hintText: _headerInfo!.searchSuggestions.isNotEmpty
                    ? _headerInfo!.searchSuggestions.first
                    : 'Buscar productos, clientes...',
                onSearchPerformed: widget.onSearch,
                showSuggestions: true,
                showHistory: true,
              ),
            ),

          if (widget.searchController != null) const SizedBox(width: 8),

          // Sección de acciones - Compacta
          if (widget.actions != null) ...[
            ...widget.actions!.map((action) => 
              SizedBox(
                width: 42,
                height: 42,
                child: action,
              )
            ),
            const SizedBox(width: 8),
          ],

          // Sección de usuario - Compacta
          HeaderUserSection(
            showUserInfo: widget.showUserInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Título de carga
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Búsqueda de carga
          Container(
            width: 400,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
          ),

          const SizedBox(width: 24),

          // Usuario de carga
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

}
