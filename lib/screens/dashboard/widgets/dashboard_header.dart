import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../widgets/facebook_notifications_widget.dart';
import '../../../services/supabase_auth_service.dart';
import '../../../screens/auth/login_screen.dart';
import '../../../config/app_theme.dart';

class DashboardHeader extends StatelessWidget {
  final TextEditingController searchController;
  final Function(String) onSearch;

  DashboardHeader({
    super.key,
    required this.searchController,
    required this.onSearch,
  });

  final SupabaseAuthService _authService = SupabaseAuthService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
          // Espaciador para centrar los controles
          const Spacer(),
          // Buscador funcional
          _buildSearchField(),
          const SizedBox(width: 16),
          // Notificaciones estilo Facebook
          const FacebookNotificationsWidget(),
          const SizedBox(width: 16),
          // Información del usuario y logout
          _buildUserInfo(context),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 300,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: const InputDecoration(
          hintText: 'Buscar productos, clientes, ventas...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(
            FontAwesomeIcons.magnifyingGlass,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          prefixIconConstraints: BoxConstraints(
            minWidth: 24,
            minHeight: 24,
          ),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
        ),
        onChanged: onSearch,
        onSubmitted: onSearch,
        textInputAction: TextInputAction.search,
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
