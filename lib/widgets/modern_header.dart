import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/app_theme.dart';
import '../services/supabase_auth_service.dart';
import '../screens/auth/login_screen.dart';

class ModernHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextEditingController? searchController;
  final Function(String)? onSearch;
  final List<Widget>? actions;
  final bool showNotifications;
  final bool showUserInfo;

  ModernHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchController,
    this.onSearch,
    this.actions,
    this.showNotifications = true,
    this.showUserInfo = true,
  });

  final SupabaseAuthService _authService = SupabaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Search bar
          if (searchController != null) ...[
            Container(
              width: 320,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.borderColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) => onSearch?.call(value),
                decoration: InputDecoration(
                  hintText: 'Buscar productos, clientes...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    FontAwesomeIcons.magnifyingGlass,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: searchController!.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.xmark,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            searchController!.clear();
                            onSearch?.call('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          
          // Actions
          if (actions != null) ...[
            Row(
              children: actions!,
            ),
            const SizedBox(width: 16),
          ],
          
          // Notificaciones (opcional)
         
          // Información del usuario y logout (opcional)
          if (showUserInfo) 
            _buildUserInfo(context)
          else
            // Profile section original (solo icono)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                FontAwesomeIcons.user,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    final isAnonymous = _authService.isAnonymous;
    final userName = _authService.currentUserName;
    final userEmail = _authService.currentUserEmail;
    
    // Obtener nombre o email del usuario
    String displayName = 'Usuario';
    if (isAnonymous) {
      displayName = 'Invitado';
    } else if (userName != null && userName.isNotEmpty) {
      displayName = userName;
    } else if (userEmail != null && userEmail.isNotEmpty) {
      displayName = userEmail;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Información del usuario (solo texto)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono del usuario
            Icon(
              isAnonymous ? FontAwesomeIcons.userSecret : FontAwesomeIcons.user,
              color: isAnonymous ? AppTheme.warningColor : AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            
            // Nombre del usuario
            Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isAnonymous ? AppTheme.warningColor : AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 8),
        
        // Botón de logout
        GestureDetector(
          onTap: () => _showLogoutDialog(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.errorColor.withOpacity(0.3),
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
            child: Icon(
              FontAwesomeIcons.rightFromBracket,
              color: AppTheme.errorColor,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppTheme.surfaceColor,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FontAwesomeIcons.rightFromBracket,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar diálogo
                await _authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
