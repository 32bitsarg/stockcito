import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/header/header_data_service.dart';
import 'header_title_section.dart';
import 'header_user_section.dart';
import '../../search/global_search_widget.dart';

/// Header moderno simplificado - Solo búsqueda global y cerrar sesión
class ModernHeaderRefactored extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? context;
  final Function(String)? onSearch;
  final bool showSearch;
  final bool showUserInfo;

  const ModernHeaderRefactored({
    super.key,
    required this.title,
    this.subtitle,
    this.context,
    this.onSearch,
    this.showSearch = true,
    this.showUserInfo = true,
  });

  @override
  State<ModernHeaderRefactored> createState() => _ModernHeaderRefactoredState();
}

class _ModernHeaderRefactoredState extends State<ModernHeaderRefactored> {
  final HeaderDataService _dataService = HeaderDataService();
  HeaderInfo? _headerInfo;

  @override
  void initState() {
    super.initState();
    _loadHeaderData();
  }

  @override
  void didUpdateWidget(ModernHeaderRefactored oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Recargar datos si cambió el contexto, título o subtítulo
    if (oldWidget.context != widget.context ||
        oldWidget.title != widget.title ||
        oldWidget.subtitle != widget.subtitle) {
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
        showSearch: widget.showSearch,
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
      height: 80, // Altura reducida para diseño plano
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB), // Gris claro para separación sutil
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sección de título - Flexible pero con mínimo
          Flexible(
            flex: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
              child: HeaderTitleSection(
                title: _headerInfo!.title,
                subtitle: _headerInfo!.subtitle,
                showGreeting: false, // Simplificado - sin saludo
                userName: _headerInfo!.userInfo.displayName,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Búsqueda global centrada
          Expanded(
            flex: 2, // Más espacio para la búsqueda
            child: Center(
              child: widget.showSearch
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 300,
                        maxWidth: 500,
                      ),
                      child: GlobalSearchWidget(
                        hintText: _headerInfo!.searchSuggestions.isNotEmpty
                            ? _headerInfo!.searchSuggestions.first
                            : 'Buscar...',
                        onSearchPerformed: widget.onSearch,
                        showSuggestions: true,
                        showHistory: true,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          const SizedBox(width: 16),

          // Botón "Cerrar Sesión" en la esquina derecha
          Container(
            margin: const EdgeInsets.only(right: 16), // 16px del borde derecho
            child: HeaderUserSection(
              showUserInfo: widget.showUserInfo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHeader() {
    return Container(
      height: 80, // Altura reducida para diseño plano
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB), // Gris claro para separación sutil
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Título de carga - Flexible pero con mínimo
          Flexible(
            flex: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 20,
                    width: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Búsqueda de carga centrada
          Expanded(
            flex: 2,
            child: Center(
              child: widget.showSearch
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 300,
                        maxWidth: 500,
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Botón "Cerrar Sesión" de carga
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Container(
              height: 32,
              width: 100,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}