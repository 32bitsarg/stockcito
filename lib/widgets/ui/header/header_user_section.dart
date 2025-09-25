import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../services/auth/supabase_auth_service.dart';
import '../../../screens/auth/login_screen.dart';

/// Widget para la sección de usuario del header
class HeaderUserSection extends StatelessWidget {
  final bool showUserInfo;
  final VoidCallback? onLogout;

  const HeaderUserSection({
    super.key,
    this.showUserInfo = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return _buildUserInfo(context);
  }

  Widget _buildUserInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Texto "Logout"
        Text(
          'Logout',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),

        const SizedBox(width: 8),

        // Botón de logout
        _buildLogoutButton(context),
      ],
    );
  }


  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(context),
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Icon(
              Icons.logout,
              color: AppTheme.errorColor,
              size: 16,
            ),
          ),
        ),
      ),
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
                  Icons.logout,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Cerrar Sesión',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                
                // Ejecutar callback personalizado si existe
                onLogout?.call();
                
                // O usar el servicio de autenticación por defecto
                if (onLogout == null) {
                  final authService = SupabaseAuthService();
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
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
