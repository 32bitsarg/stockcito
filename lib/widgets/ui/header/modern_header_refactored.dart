import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/ui/header/header_data_service.dart';
import '../../../services/ui/header/header_navigation_service.dart';
import 'header_title_section.dart';
import 'header_actions_section.dart';
import 'header_user_section.dart';
import '../../search/global_search_widget.dart';

/// Header moderno refactorizado siguiendo el estilo de Eduplex
class ModernHeaderRefactored extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? context;
  final Function(String)? onSearch;
  final List<Widget>? customActions;
  final bool showSearch;
  final bool showUserInfo;
  final bool showGreeting;
  final bool showNotifications;
  final String? notificationBadge;

  const ModernHeaderRefactored({
    super.key,
    required this.title,
    this.subtitle,
    this.context,
    this.onSearch,
    this.customActions,
    this.showSearch = true,
    this.showUserInfo = true,
    this.showGreeting = false,
    this.showNotifications = true,
    this.notificationBadge,
  });

  @override
  State<ModernHeaderRefactored> createState() => _ModernHeaderRefactoredState();
}

class _ModernHeaderRefactoredState extends State<ModernHeaderRefactored> {
  final HeaderDataService _dataService = HeaderDataService();
  final HeaderNavigationService _navigationService = HeaderNavigationService();

  HeaderInfo? _headerInfo;
  List<HeaderNavigationAction> _actions = [];

  @override
  void initState() {
    super.initState();
    _loadHeaderData();
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

      // Obtener acciones para la pantalla actual
      _actions = _navigationService.getActionsForScreen(
        context,
        widget.context ?? 'default',
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
      height: 100, // Altura aumentada para estilo Eduplex
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
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sección de título con saludo
          HeaderTitleSection(
            title: _headerInfo!.title,
            subtitle: _headerInfo!.subtitle,
            showGreeting: widget.showGreeting,
            userName: _headerInfo!.userInfo.displayName,
          ),

          const SizedBox(width: 24),

          // Sección de búsqueda
          if (widget.showSearch)
            GlobalSearchWidget(
              hintText: _headerInfo!.searchSuggestions.isNotEmpty
                  ? _headerInfo!.searchSuggestions.first
                  : 'Buscar...',
              onSearchPerformed: widget.onSearch,
              showSuggestions: true,
              showHistory: true,
            ),

          if (widget.showSearch) const SizedBox(width: 24),

          // Sección de acciones
          if (_actions.isNotEmpty || widget.customActions != null)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Acciones personalizadas
                  if (widget.customActions != null) ...[
                    ...widget.customActions!,
                    const SizedBox(width: 16),
                  ],

                  // Acciones del servicio de navegación
                  if (_actions.isNotEmpty)
                    HeaderActionsSection(
                      actions: _actions,
                      showNotifications: widget.showNotifications,
                      notificationBadge: widget.notificationBadge,
                    ),

                  const SizedBox(width: 16),

                  // Sección de usuario
                  HeaderUserSection(
                    showUserInfo: widget.showUserInfo,
                  ),
                ],
              ),
            )
          else
            // Solo sección de usuario si no hay acciones
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
